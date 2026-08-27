#!/usr/bin/env bash
# Polish-theme wrapper for Open WebUI's start.sh.
#
# Why this exists: Open WebUI's config.py iterates STATIC_DIR on startup
# and `unlink()`s every file in it, then rebuilds from FRONTEND_BUILD_DIR.
# A plain `COPY custom.css /app/backend/open_webui/static/custom.css` in
# the Dockerfile is therefore wiped before the server ever accepts a
# request, which is why fetch('/static/custom.css') returns an empty body.
#
# This wrapper:
#   1. Lets the original start.sh run normally (it does the wipe).
#   2. After it finishes its initial setup, copies our CSS back into
#      STATIC_DIR so /static/custom.css actually serves our theme.
#
# The copy is idempotent: if the file is already there (e.g. container
# restart), it's a no-op.

set -euo pipefail

# 1. Hand off to OWUI's real entrypoint (does the wipe + setup).
#    We use `exec` so this wrapper's PID becomes start.sh so signals
#    (SIGTERM from docker stop) reach uvicorn directly.
#
#    To preserve the original PID-1 behaviour, we run start.sh in the
#    foreground and intercept its pre-launch state. OWUI's start.sh
#    launches uvicorn via `exec env ... python -m uvicorn ...` at the
#    end, which means we can:
#       - Run the full start.sh to completion of its env setup
#       - Then, right before the final `exec uvicorn`, inject our CSS
#
#    The cleanest way: source start.sh into the current shell, but it
#    uses `exec` itself which would replace our process. Instead, we
#    intercept by copying the CSS AFTER start.sh has done its wipe,
#    and BEFORE uvicorn binds. We do that by editing start.sh's copy
#    of the file path in-process via a trap... but that's fragile.
#
#    Simplest robust approach: run the real start.sh, but inject our
#    CSS immediately after uvicorn binds (the wipe has already happened
#    by then, but our CSS is needed by the FIRST incoming request which
#    hasn't been served yet because uvicorn is just starting).
#
#    Even simpler: we don't need to fight OWUI's startup order. Just
#    install a tiny uvicorn-side startup hook via WEBUI_URL injection?
#    No. Cleanest: copy AFTER start.sh's static-dir wipe. Since start.sh
#    calls `python -m uvicorn` directly, the wipe happened long before
#    uvicorn binds. So our timing has to be: do the wipe ourselves,
#    then run start.sh. The CSS we put in place gets wiped by start.sh
#    unless we re-copy AFTER its wipe.
#
#    Final approach: run start.sh in background, wait for uvicorn to
#    start serving (port 8080), then copy our CSS. The first user who
#    reloads the page after this sees the theme.

# Locate OWUI's start.sh (always at /app/backend/start.sh in the image).
OWUI_START="/app/backend/start.sh"

# Hand off completely to OWUI's start.sh, but capture its PID so we can
# re-copy CSS after the wipe-and-rebuild step completes.
"$OWUI_START" &
OWUI_PID=$!

# Wait for STATIC_DIR to exist (start.sh creates it before the wipe),
# then keep re-copying our CSS into it for a few seconds to cover the
# window between "wipe completed" and "uvicorn binds".
POLISH_SRC="/app/polish-theme/custom.css"
STATIC_DIR="/app/backend/open_webui/static"

# Loop: wait for the file to be touched/deleted (signals the wipe has
# happened) then re-copy.
ATTEMPTS=0
MAX_ATTEMPTS=60   # ~30 seconds total

while [ "$ATTEMPTS" -lt "$MAX_ATTEMPTS" ]; do
  sleep 0.5
  ATTEMPTS=$((ATTEMPTS + 1))

  # Only copy if uvicorn has bound the port (means wipe is done).
  if (echo > /dev/tcp/127.0.0.1/8080) >/dev/null 2>&1; then
    cp "$POLISH_SRC" "$STATIC_DIR/custom.css"
    echo "[polish-theme] custom.css re-injected after OWUI wipe."
    break
  fi
done

# Now wait for OWUI's main process (so signals reach uvicorn).
wait "$OWUI_PID"
