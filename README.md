# Polish Theme for Open WebUI

A Claude/ChatGPT-inspired dark theme for [Open WebUI](https://github.com/open-webui/open-webui).

## What's included

- Inter (UI) + Source Serif Pro (headings) + JetBrains Mono (code)
- Tokyo Night syntax highlighting
- Artifact-style cards with left-rail accent
- Refined chat input pill, message bubbles, tables, blockquotes
- Auto-switches to light palette on `.light` / `[data-theme="light"]`
- `prefers-reduced-motion` respected
- Bulletproof: 12 CSS layers, `:where()` zero-specificity selectors, fallbacks

## How it works

Open WebUI's `src/app.html` loads `<link rel="stylesheet" href="/static/custom.css">`.
The backend mounts `/static` from `STATIC_DIR` (default `/app/backend/open_webui/static`).

**The catch**: OWUI's `backend/open_webui/config.py` runs on startup and **deletes every file in `STATIC_DIR`**, then rebuilds from `/app/build/static/`. So a plain `COPY` into `STATIC_DIR` is wiped before any request is served.

The fix: a small `start-polish.sh` wrapper that:
1. Drops our CSS into `/app/polish-theme/custom.css` (a directory OWUI doesn't touch)
2. Launches OWUI's normal `start.sh` in the background
3. Polls for the uvicorn port to come up (which means OWUI's wipe is done)
4. Re-copies our CSS into `STATIC_DIR/custom.css` and waits for OWUI to exit

## Run

> ⚠️ **Important**: If you have an existing `open-webui` container (even from a different image), stop and remove it first — they all bind port 3000 and will conflict.

```bash
# 1. Stop and remove any existing open-webui container
docker ps --filter "publish=3000" -q | xargs -r docker stop
docker ps --filter "publish=3000" -q | xargs -r docker rm

# 2. Pull the latest image
docker pull ghcr.io/rakesh1308/openwebui-polish-theme:latest

# 3. (Recommended) Verify the image has our CSS — should print ~20153 bytes
docker run --rm ghcr.io/rakesh1308/openwebui-polish-theme:latest \
  sh -c "wc -c /app/backend/open_webui/static/custom.css"
#    Expected: 20153 /app/backend/open_webui/static/custom.css
#    If you see "0 /app/..." the image is stale — re-pull with --no-cache

# 4. Run (uses the same data volume as a stock open-webui install,
#    so your chats/users are preserved)
docker run -d -p 3000:8080 -v open-webui-data:/app/backend/data \
  --name open-webui --restart unless-stopped \
  ghcr.io/rakesh1308/openwebui-polish-theme:latest
```

No env vars needed — CSS is baked into the image.

## Verify it's working

Open <http://localhost:3000>, **hard refresh** (Ctrl+Shift+R), then F12 → Console:

```javascript
// 1. The file should be ~20KB, not 0 bytes
fetch('/static/custom.css').then(r => r.text())
  .then(t => t.length)
//   → ~20000

// 2. Tokens should now be applied
getComputedStyle(document.documentElement).getPropertyValue('--accent')
//   → "#6366f1"
```

If step 1 returns `0`, your running container is from an old image. Repeat step 1 of "Run" above.

## Files

| File | Purpose |
|---|---|
| `custom.css` | The theme — edit this |
| `Dockerfile` | Layers CSS onto the official image |
| `.github/workflows/build.yml` | GH Actions — builds & pushes image |
| `README.md` | This file |

## Editing the theme

1. Edit `custom.css`
2. Commit & push — Actions rebuilds & publishes the image in ~2 min

## Custom accent color

Change `--accent` in `custom.css` (and any other token in `:where(:root, .dark, .light, [data-theme])`).
