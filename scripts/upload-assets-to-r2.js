// Upload Static Assets to R2 CDN
//
// This script uploads all static assets from apps/*/public/ folders
// to the Cloudflare R2 bucket for CDN delivery.
//
// Usage:
//   node scripts/upload-assets-to-r2.js [--dry-run] [--bucket=name]
//
// Options:
//   --dry-run    Show what would be uploaded without actually uploading
//   --bucket     Specify R2 bucket name (default: litla-gamaleigan-images)
//   --app        Upload only from specific app (admin, drivers, web)
//
// Examples:
//   node scripts/upload-assets-to-r2.js --dry-run
//   node scripts/upload-assets-to-r2.js --app=web

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const CONFIG = {
  bucket: 'litla-gamaleigan-images',
  dryRun: false,
  appFilter: null,

  apps: [
    { name: 'web', path: 'apps/litlagamaleigan-web/public' },
    { name: 'admin', path: 'apps/litla-admin/public' },
    { name: 'drivers', path: 'apps/litla-drivers/public' },
  ],

  extensions: [
    '.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp',
    '.mp4', '.webm', '.mov', '.avi',
    '.woff', '.woff2', '.ttf', '.otf',
    '.ico', '.xml',
  ],

  skipFiles: ['robots.txt', 'sitemap.xml', '.DS_Store', 'Thumbs.db'],

  assetMapping: {
    'hero-video': 'videos/hero/desktop',
    'hero-video-compressed': 'videos/hero/desktop',
    'hero-video-mobile': 'videos/hero/mobile',
    'hero-fallback': 'videos/fallbacks',
    'halfur': 'images/containers',
    'krokheysi': 'images/containers',
    'krokheysigamur': 'images/containers',
    '20251229': 'images/containers',
    'gunnar': 'images/team',
    'einar': 'images/team',
    'litla2': 'images/branding',
    'logo': 'images/branding',
    'favicon': 'images/branding',
    'news': 'news',
    'vite': 'icons',
    'hero-banner': 'icons',
  },

  contentTypes: {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.webp': 'image/webp',
    '.mp4': 'video/mp4',
    '.webm': 'video/webm',
    '.mov': 'video/quicktime',
    '.avi': 'video/x-msvideo',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
    '.ttf': 'font/ttf',
    '.otf': 'font/otf',
    '.ico': 'image/x-icon',
    '.xml': 'application/xml',
  },
};

function parseArgs() {
  const args = process.argv.slice(2);
  args.forEach(arg => {
    if (arg === '--dry-run') CONFIG.dryRun = true;
    else if (arg.startsWith('--bucket=')) CONFIG.bucket = arg.split('=')[1];
    else if (arg.startsWith('--app=')) CONFIG.appFilter = arg.split('=')[1];
    else if (arg === '--help' || arg === '-h') {
      console.log('Usage: node scripts/upload-assets-to-r2.js [options]');
      console.log('Options:');
      console.log('  --dry-run    Show what would be uploaded');
      console.log('  --bucket     R2 bucket name');
      console.log('  --app        Upload only from specific app (admin, drivers, web)');
      process.exit(0);
    }
  });
}

function getR2Path(filename, sourcePath) {
  const basename = path.basename(filename, path.extname(filename));
  for (const [pattern, folder] of Object.entries(CONFIG.assetMapping)) {
    if (basename.includes(pattern)) {
      return `${folder}/${path.basename(filename)}`;
    }
  }
  return path.relative(sourcePath, filename);
}

function getContentType(filename) {
  const ext = path.extname(filename).toLowerCase();
  return CONFIG.contentTypes[ext] || 'application/octet-stream';
}

function findAssets() {
  const assets = [];
  const appsToScan = CONFIG.appFilter
    ? CONFIG.apps.filter(app => app.name === CONFIG.appFilter)
    : CONFIG.apps;

  if (appsToScan.length === 0) {
    console.error(`Error: App "${CONFIG.appFilter}" not found`);
    process.exit(1);
  }

  function scanDir(dirPath, sourcePath, appName) {
    if (!fs.existsSync(dirPath)) return;
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });

    entries.forEach(entry => {
      const fullPath = path.join(dirPath, entry.name);
      if (entry.isDirectory()) {
        scanDir(fullPath, sourcePath, appName);
      } else if (entry.isFile()) {
        const ext = path.extname(entry.name).toLowerCase();
        if (CONFIG.extensions.includes(ext) && !CONFIG.skipFiles.includes(entry.name)) {
          assets.push({
            source: fullPath,
            r2Path: getR2Path(fullPath, sourcePath),
            contentType: getContentType(fullPath),
            size: fs.statSync(fullPath).size,
            app: appName,
          });
        }
      }
    });
  }

  appsToScan.forEach(app => {
    const appPath = path.join(process.cwd(), app.path);
    scanDir(appPath, appPath, app.name);
  });

  return assets;
}

function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function uploadAsset(asset) {
  const { source, r2Path, contentType } = asset;
  try {
    const command = `npx wrangler r2 object put ${CONFIG.bucket}/${r2Path} --file="${source}" --content-type="${contentType}"`;
    if (CONFIG.dryRun) {
      console.log(`  [DRY RUN] Would upload: ${r2Path}`);
      return { success: true, bytes: asset.size };
    }
    execSync(command, { stdio: 'pipe' });
    return { success: true, bytes: asset.size };
  } catch (error) {
    console.error(`Failed to upload ${r2Path}:`, error.message);
    return { success: false, bytes: 0 };
  }
}

async function uploadAll(assets) {
  console.log(`\nUploading ${assets.length} assets to R2 bucket: ${CONFIG.bucket}\n`);

  let uploaded = 0;
  let failed = 0;
  let totalBytes = 0;

  const byFolder = {};
  assets.forEach(asset => {
    const folder = path.dirname(asset.r2Path);
    if (!byFolder[folder]) byFolder[folder] = [];
    byFolder[folder].push(asset);
  });

  for (const [folder, folderAssets] of Object.entries(byFolder)) {
    console.log(`\n${folder}/ (${folderAssets.length} files)`);
    for (const asset of folderAssets) {
      process.stdout.write(`  ${path.basename(asset.r2Path)} (${formatBytes(asset.size)})...`);
      const result = uploadAsset(asset);
      if (result.success) {
        console.log(' OK');
        uploaded++;
        totalBytes += result.bytes;
      } else {
        console.log(' FAILED');
        failed++;
      }
    }
  }

  console.log(`\n${'='.repeat(60)}`);
  console.log(`Uploaded: ${uploaded} files (${formatBytes(totalBytes)})`);
  if (failed > 0) console.log(`Failed: ${failed} files`);
  console.log(`${'='.repeat(60)}\n`);

  if (CONFIG.dryRun) {
    console.log('DRY RUN MODE - No files were actually uploaded');
    console.log('Remove --dry-run flag to perform actual upload\n');
  }
}

async function main() {
  parseArgs();

  console.log('\nLitla Gamaleigan - R2 Asset Upload Script');
  console.log(`${'='.repeat(60)}`);
  console.log(`Bucket: ${CONFIG.bucket}`);
  console.log(`Mode: ${CONFIG.dryRun ? 'DRY RUN' : 'UPLOAD'}`);
  if (CONFIG.appFilter) console.log(`App Filter: ${CONFIG.appFilter}`);
  console.log(`${'='.repeat(60)}`);

  console.log('\nScanning for assets...');
  const assets = findAssets();

  if (assets.length === 0) {
    console.log('No assets found to upload');
    process.exit(0);
  }

  console.log(`Found ${assets.length} assets (${formatBytes(assets.reduce((sum, a) => sum + a.size, 0))})`);

  const byApp = {};
  assets.forEach(asset => {
    if (!byApp[asset.app]) byApp[asset.app] = { count: 0, bytes: 0 };
    byApp[asset.app].count++;
    byApp[asset.app].bytes += asset.size;
  });

  console.log('\nBreakdown by app:');
  Object.entries(byApp).forEach(([app, stats]) => {
    console.log(`  ${app}: ${stats.count} files (${formatBytes(stats.bytes)})`);
  });

  await uploadAll(assets);

  console.log('Upload complete!\n');
  console.log('Next steps:');
  console.log('  1. Verify uploads: npx wrangler r2 object list ' + CONFIG.bucket);
  console.log('  2. Configure custom domain: images.gamaleigan.is');
  console.log('  3. Update asset URLs: node scripts/update-asset-urls.js\n');
}

main().catch(error => {
  console.error('\nFatal error:', error.message);
  process.exit(1);
});
