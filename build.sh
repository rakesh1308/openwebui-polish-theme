#!/usr/bin/env bash
# Generates Dockerfile from template.Dockerfile by inlining custom.css
# into the CUSTOM_CSS env var. Run this locally before committing.
#
# GitHub Actions also runs this same script via the workflow.
#
# Strategy: We use python to do the escaping because bash + sed + awk
# is fragile across line endings (CRLF on Windows) and edge cases in
# the CSS (backslashes, double quotes, etc.).

set -euo pipefail

CSS_FILE="${1:-custom.css}"
TEMPLATE="template.Dockerfile"
OUTPUT="Dockerfile"

if [ ! -f "$CSS_FILE" ]; then
  echo "❌ CSS file not found: $CSS_FILE" >&2
  exit 1
fi

# Build Dockerfile using Python so escaping is deterministic.
python3 - "$CSS_FILE" "$TEMPLATE" "$OUTPUT" <<'PYEOF'
import sys, pathlib

css_path   = pathlib.Path(sys.argv[1])
tmpl_path  = pathlib.Path(sys.argv[2])
out_path   = pathlib.Path(sys.argv[3])

css = css_path.read_text(encoding="utf-8")

# Escape for Dockerfile ENV (POSIX shell rules):
#   \  -> \\
#   "  -> \"
#   newline -> \n (literal backslash-n, NOT a real newline)
# We deliberately do NOT need to escape: $, `, ', since ENV is parsed
# by the Docker builder, not a shell. The resulting value will be the
# raw CSS bytes when the container runs.
escaped = (
    css.replace("\\", "\\\\")   # backslash must be first
       .replace('"', '\\"')     # double-quote
       .replace("\r\n", "\\n")  # Windows CRLF -> escape both
       .replace("\n", "\\n")    # Unix LF -> escape
)

tmpl = tmpl_path.read_text(encoding="utf-8")
result = (
    "# Auto-generated from template.Dockerfile by build.sh — do not edit.\n"
    "# Regenerate with: ./build.sh\n"
    "\n"
    + tmpl.replace("__CUSTOM_CSS_PLACEHOLDER__", escaped)
)

out_path.write_text(result, encoding="utf-8", newline="\n")
print(f"✅ Generated {out_path} (inlined {len(css)} bytes of CSS)")
PYEOF
