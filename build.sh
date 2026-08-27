#!/usr/bin/env bash
# Generates Dockerfile from template.Dockerfile by inlining custom.css
# into the CUSTOM_CSS env var. Run this locally before committing.
#
# GitHub Actions also runs this same script via the workflow.

set -euo pipefail

CSS_FILE="${1:-custom.css}"
TEMPLATE="template.Dockerfile"
OUTPUT="Dockerfile"

if [ ! -f "$CSS_FILE" ]; then
  echo "❌ CSS file not found: $CSS_FILE" >&2
  exit 1
fi

# Read CSS, escape for ENV var (single-quote, escape single quotes,
# escape backslashes/newlines for Dockerfile ENV parsing)
CSS_ESCAPED=$(printf '%s' "$(cat "$CSS_FILE")" | \
  sed 's/\\/\\\\/g' | \
  sed "s/'/'\\\\''/g" | \
  awk '{ printf "%s\\n", $0 }')

# Build the Dockerfile
{
  echo "# Auto-generated from template.Dockerfile by build.sh — do not edit."
  echo "# Regenerate with: ./build.sh"
  echo ""
  cat "$TEMPLATE" | sed "s|__CUSTOM_CSS_PLACEHOLDER__|${CSS_ESCAPED}|"
} > "$OUTPUT"

echo "✅ Generated $OUTPUT (inlined $(wc -c < "$CSS_FILE") bytes of CSS)"
