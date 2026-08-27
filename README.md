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

Open WebUI's official image builds the frontend in a Node stage and ships only `/app/build/*` at runtime — `COPY` into `/app/src/...` is silently lost.

Instead, the backend reads the `CUSTOM_CSS` env var and inlines it into every HTML response. We bake the CSS into that env var at image-build time.

## Run

```bash
docker pull ghcr.io/rakesh1308/openwebui-polish-theme:latest
docker run -d -p 3000:8080 -v open-webui-data:/app/backend/data \
  --name open-webui --restart unless-stopped \
  ghcr.io/rakesh1308/openwebui-polish-theme:latest
```

No env vars needed — CSS is baked in.

## Verify it's working

Open <http://localhost:3000>, then F12 → Console, paste:

```javascript
getComputedStyle(document.documentElement).getPropertyValue('--accent')
```

Should return: `#6366f1`

## Files

| File | Purpose |
|---|---|
| `custom.css` | The theme — edit this |
| `template.Dockerfile` | Template with CSS placeholder |
| `build.sh` | Generates `Dockerfile` from template + CSS |
| `Dockerfile` | **Auto-generated**, do not edit |
| `.github/workflows/build.yml` | GH Actions — runs `build.sh` then builds image |

## Editing the theme

1. Edit `custom.css`
2. Run `bash build.sh` locally to regenerate `Dockerfile`
3. Commit both — Actions rebuilds & pushes the image

## Custom accent color

Change `--accent` in `custom.css` (and any other token in `:where(:root, .dark, .light, [data-theme])`).
