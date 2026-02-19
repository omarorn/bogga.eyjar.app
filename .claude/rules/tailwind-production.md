---
paths: "src/**/*.ts", "src/**/*.tsx", "src/**/*.astro", "index.html"
---

# Tailwind CSS: Never Use CDN in Production

**Purpose:** Always use compiled Tailwind CSS, never CDN.

## Rule
```html
<!-- WRONG: CDN (slow, no tree-shaking, no custom config) -->
<script src="https://cdn.tailwindcss.com"></script>

<!-- CORRECT: Compiled CSS -->
<link rel="stylesheet" href="/output.css">
```

## Build Process

```bash
# Build compiled CSS
npm run build:css

# Watch mode during development
npx @tailwindcss/cli -i ./src/input.css -o ./public/output.css --watch
```

## Deployment

1. Build CSS: `npm run build:css`
2. CSS is auto-uploaded via Workers Assets (`public/output.css`)
3. Fallback to R2 if Assets fails (see `cloudflare-workers-assets.md`)

## Why Not CDN?
- No tree-shaking (full 3MB+ vs ~10KB compiled)
- No custom config support
- Extra network request
- Flash of unstyled content
- Not available offline
