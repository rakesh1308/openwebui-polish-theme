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
The backend mounts `/static` from the `STATIC_DIR` (default `/app/backend/open_webui/static`).

So the Dockerfile just `COPY`s our CSS into that directory:

```dockerfile
FROM ghcr.io/open-webui/open-webui:main
COPY custom.css /app/backend/open_webui/static/custom.css
```

## Run

```bash
docker pull ghcr.io/rakesh1308/openwebui-polish-theme:latest
docker run -d -p 3000:8080 -v open-webui-data:/app/backend/data \
  --name open-webui --restart unless-stopped \
  ghcr.io/rakesh1308/openwebui-polish-theme:latest
```

No env vars needed — CSS is baked in.

## Verify it's working

Open <http://localhost:3000>, hard refresh (Ctrl+Shift+R), then F12 → Console:

```javascript
fetch('/static/custom.css').then(r => r.status)
// → 200

getComputedStyle(document.documentElement).getPropertyValue('--accent')
// → "#6366f1"
```

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
