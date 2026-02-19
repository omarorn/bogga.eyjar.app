---
paths: "**/dist/**", "**/wrangler.toml", "**/*.astro"
---

# Cloudflare Pages File Size Limits

Cloudflare Pages has strict file size limits that require special handling for large assets.

## Pattern

| If Claude suggests... | Use instead... |
|----------------------|----------------|
| Deploying video files in dist | Serve from R2 and exclude from dist |
| Including large assets (>25MB) in build | Upload to R2, reference via URL |
| Bundling media in Pages deployment | Use R2 for media, Pages for code |

## File Size Limits

**Cloudflare Pages:**
- Maximum file size: **25 MiB** per file
- Applies to all files in dist folder
- Error: `Pages only supports files up to 25 MiB in size`

**Cloudflare R2:**
- Maximum object size: **5 TiB** (5,000 GiB)
- No practical limit for media files
- Recommended for videos, large images, archives

## Implementation

### Video Files (Most Common Case)

**Problem:**
```bash
# Build copies videos to dist/
npm run build
# ✗ hero-video-mobile.webm is 57.6 MiB - exceeds 25 MiB limit
wrangler pages deploy dist
```

**Solution:**
```bash
# 1. Build normally
npm run build

# 2. Remove large video files from dist
rm -f dist/hero-video*.mp4 dist/hero-video*.webm

# 3. Reference R2 URLs in HTML
<video src="https://worker.workers.dev/videos/hero-video.mp4"></video>

# 4. Deploy without large files
wrangler pages deploy dist --project-name=my-project
```

### Astro Configuration

**Exclude large files from build output:**

```javascript
// astro.config.mjs
export default defineConfig({
  vite: {
    build: {
      rollupOptions: {
        external: [
          // Exclude video files from bundle
          /.*\.(mp4|webm|avi|mov)$/
        ]
      }
    }
  }
});
```

**Use R2 URLs in templates:**

```astro
---
// Use R2 URLs instead of local files
const videoUrl = 'https://your-worker.workers.dev/videos/hero-video.mp4';
---

<video src={videoUrl} autoplay muted loop></video>
```

## R2 Setup for Media Files

### Upload to R2

```bash
# Create R2 bucket (if needed)
wrangler r2 bucket create media-assets

# Upload video files
wrangler r2 object put media-assets/videos/hero-video-desktop.mp4 \
  --file=./public/hero-video-desktop.mp4 \
  --content-type=video/mp4

wrangler r2 object put media-assets/videos/hero-video-mobile.mp4 \
  --file=./public/hero-video-mobile.mp4 \
  --content-type=video/mp4
```

### Serve from Worker

```typescript
// packages/workers/src/index.ts
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Serve videos from R2
    if (url.pathname.startsWith('/videos/')) {
      const key = url.pathname.slice(8); // Remove '/videos/'
      const object = await env.R2_BUCKET.get(key);

      if (!object) {
        return new Response('Not Found', { status: 404 });
      }

      return new Response(object.body, {
        headers: {
          'Content-Type': object.httpMetadata?.contentType || 'video/mp4',
          'Cache-Control': 'public, max-age=31536000', // 1 year
        },
      });
    }

    // ... rest of worker
  }
};
```

## Common File Size Issues

### Issue 1: Video files too large

**Symptom:**
```
✘ ERROR Error: Pages only supports files up to 25 MiB in size
  hero-video-mobile.webm is 57.6 MiB in size
```

**Solution:**
1. Upload videos to R2
2. Remove from dist: `rm -f dist/*.mp4 dist/*.webm`
3. Update HTML to use R2 URLs
4. Redeploy

### Issue 2: Large images exceed limit

**Symptom:**
```
✘ ERROR Error: Pages only supports files up to 25 MiB in size
  hero-background.jpg is 28.3 MiB in size
```

**Solution:**
1. Compress image: `npm install sharp && node compress-image.js`
2. Or upload to R2 if compression not acceptable
3. Use WebP format (better compression)

### Issue 3: Large data files

**Symptom:**
```
✘ ERROR Error: Pages only supports files up to 25 MiB in size
  data/products.json is 32.1 MiB in size
```

**Solution:**
1. Split into smaller chunks
2. Use D1 database instead of static JSON
3. Or upload to R2 and fetch at runtime

## Deployment Checklist

Before deploying to Pages:

```bash
# Check for large files
find dist -type f -size +20M -exec ls -lh {} \;

# If any found:
# 1. Identify file type (video, image, data)
# 2. Upload to R2 if needed
# 3. Remove from dist
# 4. Update references to use R2 URLs
# 5. Deploy

wrangler pages deploy dist --project-name=my-project
```

## Automation

**Script to remove large files before deploy:**

```bash
#!/bin/bash
# scripts/deploy-pages.sh

# Build
npm run build

# Remove large video files
echo "Removing large video files..."
rm -f dist/hero-video*.mp4 dist/hero-video*.webm
rm -f dist/*.avi dist/*.mov

# Check for remaining large files
echo "Checking for files >20MB..."
large_files=$(find dist -type f -size +20M)

if [ -n "$large_files" ]; then
  echo "WARNING: Large files detected:"
  echo "$large_files"
  echo "Upload to R2 or remove before deploying."
  exit 1
fi

# Deploy
wrangler pages deploy dist --project-name=my-project --commit-dirty=true
```

## References

- **Cloudflare Pages Limits:** https://developers.cloudflare.com/pages/platform/limits/
- **R2 Documentation:** https://developers.cloudflare.com/r2/
- **Example Implementation:** `apps/litlagamaleigan-web/src/pages/index.astro` (lines 243-262)
- **Worker R2 Integration:** `packages/workers/src/index.ts`

## Context

Discovered during CMS deployment (January 1, 2026) when hero video files (57.6 MiB) exceeded Pages 25 MiB limit. Solution: videos already hosted on R2, just needed to remove from dist folder before deploying.
