// Update Asset URLs to CDN
//
// This script replaces local asset URLs with CDN URLs in all frontend code.
//
// Usage:
//   node scripts/update-asset-urls.js [--dry-run] [--rollback]
//
// Options:
//   --dry-run    Show what would change without actually changing files
//   --rollback   Revert CDN URLs back to local paths
//   --app        Update only specific app (admin, drivers, web)

const fs = require('fs');
const path = require('path');

const CONFIG = {
  cdnUrl: 'https://images.gamaleigan.is',
  localPrefix: '/public',
  dryRun: false,
  rollback: false,
  appFilter: null,

  apps: [
    { name: 'web', path: 'apps/litlagamaleigan-web' },
    { name: 'admin', path: 'apps/litla-admin' },
    { name: 'drivers', path: 'apps/litla-drivers' },
  ],

  extensions: ['.astro', '.tsx', '.jsx', '.ts', '.js', '.css', '.html'],
  skipFolders: ['node_modules', 'dist', 'build', '.astro', '.vite', 'public'],

  assetPatterns: {
    videos: [
      '/hero-video.mp4',
      '/hero-video.webm',
      '/hero-video-compressed.mp4',
      '/hero-video-mobile.mp4',
      '/hero-video-mobile.webm',
      '/hero-fallback-1.jpg',
      '/hero-fallback-2.jpg',
      '/hero-fallback-3.jpg',
    ],
    images: [
      '/images/halfur-opin.jpg',
      '/images/krokheysi-lokaður.jpg',
      '/images/krokheysigamur1.jpg',
      '/images/20251229_140923.jpg',
      '/images/gunnar.jpg',
      '/images/einar.jpg',
      '/images/gunnar og einar.jpg',
      '/litla2.png',
      '/logo.png',
      '/favicon.svg',
      '/news1.png',
      '/hero-banner.png',
    ],
    icons: ['/vite.svg'],
  },
};

function parseArgs() {
  const args = process.argv.slice(2);
  args.forEach(arg => {
    if (arg === '--dry-run') CONFIG.dryRun = true;
    else if (arg === '--rollback') CONFIG.rollback = true;
    else if (arg.startsWith('--app=')) CONFIG.appFilter = arg.split('=')[1];
    else if (arg === '--help' || arg === '-h') {
      console.log('Usage: node scripts/update-asset-urls.js [options]');
      console.log('Options:');
      console.log('  --dry-run    Show what would change');
      console.log('  --rollback   Revert CDN URLs back to local paths');
      console.log('  --app        Update only specific app');
      process.exit(0);
    }
  });
}

function buildReplacementMap() {
  const map = new Map();
  const allAssets = [
    ...CONFIG.assetPatterns.videos,
    ...CONFIG.assetPatterns.images,
    ...CONFIG.assetPatterns.icons,
  ];

  allAssets.forEach(localPath => {
    const cdnPath = localPath.startsWith('/') ? localPath.slice(1) : localPath;

    if (CONFIG.rollback) {
      const cdnUrl = `${CONFIG.cdnUrl}/${cdnPath}`;
      map.set(cdnUrl, localPath);
      map.set(encodeURI(cdnUrl), localPath);
    } else {
      const cdnUrl = `${CONFIG.cdnUrl}/${cdnPath}`;
      map.set(localPath, cdnUrl);
      map.set(`"${localPath}"`, `"${cdnUrl}"`);
      map.set(`'${localPath}'`, `'${cdnUrl}'`);
      map.set(`src="${localPath}"`, `src="${cdnUrl}"`);
      map.set(`href="${localPath}"`, `href="${cdnUrl}"`);
      map.set(`src='${localPath}'`, `src='${cdnUrl}'`);
      map.set(`href='${localPath}'`, `href='${cdnUrl}'`);
      map.set(`url('${localPath}')`, `url('${cdnUrl}')`);
      map.set(`url("${localPath}")`, `url("${cdnUrl}")`);
      map.set(`url(${localPath})`, `url(${cdnUrl})`);
    }
  });

  return map;
}

function shouldProcessFile(filePath) {
  const ext = path.extname(filePath);
  if (!CONFIG.extensions.includes(ext)) return false;
  const parts = filePath.split(path.sep);
  return !CONFIG.skipFolders.some(skip => parts.includes(skip));
}

function findFiles() {
  const files = [];
  const appsToScan = CONFIG.appFilter
    ? CONFIG.apps.filter(app => app.name === CONFIG.appFilter)
    : CONFIG.apps;

  if (appsToScan.length === 0) {
    console.error(`Error: App "${CONFIG.appFilter}" not found`);
    process.exit(1);
  }

  function scanDir(dirPath, appName) {
    if (!fs.existsSync(dirPath)) return;
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });

    entries.forEach(entry => {
      const fullPath = path.join(dirPath, entry.name);
      if (entry.isDirectory()) {
        if (!CONFIG.skipFolders.includes(entry.name)) {
          scanDir(fullPath, appName);
        }
      } else if (entry.isFile() && shouldProcessFile(fullPath)) {
        files.push({ path: fullPath, app: appName });
      }
    });
  }

  appsToScan.forEach(app => {
    const appPath = path.join(process.cwd(), app.path);
    scanDir(appPath, app.name);
  });

  return files;
}

function escapeRegex(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function updateFile(file, replacementMap) {
  let content = fs.readFileSync(file.path, 'utf8');
  const originalContent = content;
  let replacements = 0;

  for (const [search, replace] of replacementMap.entries()) {
    if (content.includes(search)) {
      const regex = new RegExp(escapeRegex(search), 'g');
      const count = (content.match(regex) || []).length;
      content = content.replace(regex, replace);
      replacements += count;
    }
  }

  return {
    changed: content !== originalContent,
    replacements,
    newContent: content,
  };
}

function processFiles(files, replacementMap) {
  console.log(`\nProcessing ${files.length} files...\n`);

  let filesChanged = 0;
  let totalReplacements = 0;
  const changesByApp = {};

  files.forEach(file => {
    const result = updateFile(file, replacementMap);

    if (result.changed) {
      filesChanged++;
      totalReplacements += result.replacements;

      if (!changesByApp[file.app]) changesByApp[file.app] = [];
      changesByApp[file.app].push({
        path: file.path,
        replacements: result.replacements,
      });

      const relativePath = path.relative(process.cwd(), file.path);
      console.log(`  ${relativePath} (${result.replacements} changes)`);

      if (!CONFIG.dryRun) {
        fs.writeFileSync(file.path, result.newContent, 'utf8');
      }
    }
  });

  console.log(`\n${'='.repeat(60)}`);
  console.log(`Files changed: ${filesChanged}`);
  console.log(`Total replacements: ${totalReplacements}`);
  console.log(`${'='.repeat(60)}\n`);

  if (CONFIG.dryRun) {
    console.log('DRY RUN MODE - No files were actually modified');
    console.log('Remove --dry-run flag to apply changes\n');
  }

  if (Object.keys(changesByApp).length > 0) {
    console.log('Changes by app:');
    Object.entries(changesByApp).forEach(([app, changes]) => {
      const totalChanges = changes.reduce((sum, c) => sum + c.replacements, 0);
      console.log(`  ${app}: ${changes.length} files (${totalChanges} replacements)`);
    });
    console.log('');
  }

  return { filesChanged, totalReplacements };
}

async function main() {
  parseArgs();

  console.log('\nLitla Gamaleigan - Asset URL Update Script');
  console.log(`${'='.repeat(60)}`);
  console.log(`Mode: ${CONFIG.rollback ? 'ROLLBACK (CDN -> Local)' : 'UPDATE (Local -> CDN)'}`);
  console.log(`CDN URL: ${CONFIG.cdnUrl}`);
  console.log(`Dry Run: ${CONFIG.dryRun ? 'Yes' : 'No'}`);
  if (CONFIG.appFilter) console.log(`App Filter: ${CONFIG.appFilter}`);
  console.log(`${'='.repeat(60)}`);

  const replacementMap = buildReplacementMap();
  console.log(`\n${replacementMap.size} replacement patterns loaded`);

  console.log('\nScanning for files...');
  const files = findFiles();

  if (files.length === 0) {
    console.log('No files found to process');
    process.exit(0);
  }

  console.log(`Found ${files.length} files to process`);

  const result = processFiles(files, replacementMap);

  console.log('Update complete!\n');

  if (!CONFIG.dryRun && !CONFIG.rollback && result.filesChanged > 0) {
    console.log('Next steps:');
    console.log('  1. Test locally: npm run dev');
    console.log('  2. Verify assets load from CDN');
    console.log('  3. Commit changes: git add . && git commit -m "feat: migrate assets to CDN"');
    console.log('  4. Deploy apps: npm run deploy\n');
  } else if (!CONFIG.dryRun && CONFIG.rollback && result.filesChanged > 0) {
    console.log('Rollback complete. Assets now use local /public paths.\n');
  }
}

main().catch(error => {
  console.error('\nFatal error:', error.message);
  process.exit(1);
});
