---
paths: "src/index.ts", "wrangler.toml", "wrangler*.json", "wrangler*.toml"
---

# Cloudflare Workers Assets Binding

How static assets are served in Cloudflare Workers projects.

## Assets Configuration

In `wrangler.toml` or `wrangler.json`:
```json
"assets": {
  "directory": "./public",
  "binding": "ASSETS"
}
```

This automatically uploads files from `public/` and serves them at root paths.

## Serving Pattern

| File Path | Served At |
|-----------|-----------|
| `public/output.css` | `/output.css` |
| `public/manifest.json` | `/manifest.json` |
| `public/icons/*.png` | `/icons/*.png` |

## Fallback Chain

For critical assets, implement this pattern:

```typescript
if (path === '/output.css') {
  // 1. Try Assets binding first (automatic from public/)
  if (env.ASSETS) {
    try {
      const assetResponse = await env.ASSETS.fetch(new Request(request.url));
      if (assetResponse.ok) {
        return new Response(assetResponse.body, {
          headers: {
            'Content-Type': 'text/css',
            'Cache-Control': 'public, max-age=31536000, immutable',
          },
        });
      }
    } catch (e) {
      console.error('Assets fetch failed:', e);
    }
  }

  // 2. Fallback to R2 bucket
  const cssFile = await env.BUCKET.get('output.css');
  if (cssFile) {
    return new Response(cssFile.body, {
      headers: { 'Content-Type': 'text/css', 'Cache-Control': 'public, max-age=31536000' },
    });
  }

  // 3. Return 404 (NOT redirect to avoid loops)
  return new Response('/* File not found */', { status: 404, headers: { 'Content-Type': 'text/css' } });
}
```

## Critical: Avoid Infinite Redirects

| Don't | Do |
|-------|-----|
| `return Response.redirect('/output.css', 302)` | `return new Response('...', { status: 404 })` |
| Redirect to same path as route | Return error with helpful message |

Redirecting to the same path creates an infinite loop.
