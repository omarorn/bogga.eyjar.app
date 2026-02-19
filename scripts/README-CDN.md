# CDN Scripts README

**Quick reference for CDN-related scripts**

---

## Available Scripts

### 1. Upload Assets to R2

**File:** `upload-assets-to-r2.js`

Upload all static assets from `apps/*/public/` folders to Cloudflare R2 bucket.

**Usage:**
```bash
# Dry run (preview what would be uploaded)
node scripts/upload-assets-to-r2.js --dry-run

# Or use npm script
npm run cdn:upload:dry

# Upload all assets
node scripts/upload-assets-to-r2.js
npm run cdn:upload

# Upload only from specific app
node scripts/upload-assets-to-r2.js --app=web
```

**Options:**
- `--dry-run` - Show what would be uploaded without uploading
- `--bucket=NAME` - Specify R2 bucket name (default: litla-gamaleigan-images)
- `--app=NAME` - Upload only from specific app (admin, drivers, web)
- `--help` - Show help message

**Features:**
- Organizes assets by type (videos/, images/, branding/, etc.)
- Sets correct Content-Type headers
- Shows upload progress with file sizes
- Handles large files (videos)

---

### 2. Update Asset URLs

**File:** `update-asset-urls.js`

Replace local asset URLs with CDN URLs in all frontend code.

**Usage:**
```bash
# Dry run (preview what would change)
node scripts/update-asset-urls.js --dry-run
npm run cdn:update-urls:dry

# Update URLs to CDN
node scripts/update-asset-urls.js
npm run cdn:update-urls

# Rollback to local paths
node scripts/update-asset-urls.js --rollback
npm run cdn:rollback
```

**Options:**
- `--dry-run` - Show what would change without modifying files
- `--rollback` - Revert CDN URLs back to local paths
- `--app=NAME` - Update only specific app
- `--help` - Show help message

**Features:**
- Updates .astro, .tsx, .jsx, .css, .html files
- Handles quoted strings, src/href attributes, CSS url()
- Supports rollback to local paths
- Shows summary of changes by app

---

### 3. Test CDN Performance

**File:** `test-cdn-performance.sh`

Compare performance between CDN and local asset delivery.

**Usage:**
```bash
bash scripts/test-cdn-performance.sh
npm run cdn:test
```

**Features:**
- Tests multiple assets (images, videos)
- 5 iterations per asset for accuracy
- Reports cache status (HIT/MISS)
- Calculates performance improvement percentage
- Color-coded output

**Output Example:**
```
Testing: images/branding/logo.png
   Size: 1.84 MB
   CDN: 0.082s (avg) - Cache: HIT
   Local: 0.231s (avg)
   Improvement: 64.5% faster via CDN
```

---

## Complete Workflow

### Initial Setup

1. **Configure R2 Bucket** (Cloudflare Dashboard)
   - Create bucket: `litla-gamaleigan-images`
   - Enable public access
   - Add DNS CNAME: `images` → `litla-gamaleigan-images.r2.cloudflarestorage.com`
   - Connect custom domain: `images.gamaleigan.is`
   - Configure CORS policy

2. **Upload Assets**
   ```bash
   # Preview first
   npm run cdn:upload:dry

   # Upload
   npm run cdn:upload
   ```

3. **Update Code**
   ```bash
   # Preview first
   npm run cdn:update-urls:dry

   # Update
   npm run cdn:update-urls
   ```

4. **Deploy Apps**
   ```bash
   npm run deploy
   ```

5. **Test Performance**
   ```bash
   npm run cdn:test
   ```

---

## Troubleshooting

### Script Not Executable

**Error:** `Permission denied`

**Fix:**
```bash
chmod +x scripts/test-cdn-performance.sh
```

### Line Ending Issues (WSL)

**Error:** `bad interpreter`

**Fix:**
```bash
sed -i 's/\r$//' scripts/test-cdn-performance.sh
```

### Upload Fails

**Error:** `Request timeout`

**Solution:**
- Check internet connection
- Large files may take time (hero-video.mp4 is 450 MB)
- Use wrangler CLI directly for large files:
  ```bash
  npx wrangler r2 object put litla-gamaleigan-images/videos/hero/desktop/hero-video.mp4 \
    --file=apps/litlagamaleigan-web/public/hero-video.mp4
  ```

### URL Replacement Shows No Changes

**Possible Causes:**
1. Assets already use CDN URLs
2. No matching asset paths found
3. Wrong app filter

**Debug:**
```bash
# Check current URLs
grep -r "images.gamaleigan.is" apps/litlagamaleigan-web/src/

# Check local URLs
grep -r '"/hero-video' apps/litlagamaleigan-web/src/
```

---

## Asset Organization

Assets are organized in R2 as:

```
litla-gamaleigan-images/
├── videos/
│   ├── hero/desktop/     (MP4, WebM formats)
│   ├── hero/mobile/      (Mobile-optimized)
│   └── fallbacks/        (Poster images)
├── images/
│   ├── containers/       (Container photos)
│   ├── team/             (Team photos)
│   └── branding/         (Logos, favicon)
├── news/                 (News images)
└── icons/                (SVG icons, misc)
```

---

## Performance Expectations

**Before (Local Serving):**
- TTFB: 200-500ms
- Download: 50-100 MB/s
- Cache: None

**After (CDN):**
- TTFB: 30-100ms
- Download: 200-500 MB/s
- Cache Hit Ratio: 90-95%
- **Improvement: 40-70% faster**

---

## Documentation

**Full Guides:**
- [CDN Setup Guide](../docs/CDN_SETUP_GUIDE.md) - Complete 11-phase setup
- [Quick Start](../docs/CDN_QUICK_START.md) - 15-minute setup
- [Implementation Summary](../docs/TASK-162-CDN-IMPLEMENTATION.md) - Full details

---

**Last Updated:** January 3, 2026
