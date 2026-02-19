#!/usr/bin/env node
/**
 * Seed Markdown Files to KV
 *
 * This script uploads all whitelisted markdown files to the MARKDOWN_FILES KV namespace.
 * It reads files from the filesystem and stores them with metadata.
 *
 * Usage:
 *   node scripts/seed-markdown-kv.js [--dry-run]
 *
 * Requirements:
 *   - wrangler must be installed (npm install -g wrangler)
 *   - MARKDOWN_FILES KV namespace must exist in wrangler.toml
 *   - User must be authenticated (wrangler login)
 *
 * Options:
 *   --dry-run: Show what would be uploaded without actually uploading
 *   --force: Overwrite existing files in KV
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Project root directory
const PROJECT_ROOT = path.resolve(__dirname, '..');

// Whitelist of allowed markdown files (from backend markdown.ts)
const ALLOWED_FILES = [
  // Root files
  'TODO.md',
  'tasks.md',
  'completedtasks.md',
  'CLAUDE.md',
  'SESSION.md',
  'README.md',

  // Docs folder
  'docs/CUSTOMER_PILOT_STRATEGY.md',
  'docs/CHANGELOG_AUTOMATION.md',
  'docs/CALENDAR_AND_REAL_DATA_STRATEGY.md',
  'docs/MARKDOWN_EDITOR_FEATURE.md',
  'docs/HERO_VIDEO_CMS_INTEGRATION.md',
  'docs/README.md',
  'docs/IMPLEMENTATION_PHASES.md',
  'docs/ENV_VARIABLES.md',
  'docs/INSTALLATION_COMMANDS.md',
  'docs/LITLA-ARCHITECTURE.md',
  'docs/SQL_INJECTION_AUDIT_REPORT.md',
  'docs/DATABASE_OPTIMIZATION_REPORT.md',
  'docs/ADMIN_PANEL_UX_COMPLETION.md',
  'docs/TROUBLESHOOTING.md',
  'docs/DOCUMENTATION_OVERVIEW.md',

  // User manuals
  'docs/manuals/README.md',
  'docs/manuals/ADMIN_MANUAL.md',
  'docs/manuals/CUSTOMER_PORTAL_MANUAL.md',
  'docs/manuals/DRIVER_MANUAL.md',
];

// Parse command line arguments
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const isForce = args.includes('--force');

// KV namespace configuration
const KV_NAMESPACE_ID = '3cc43daa5d454ce582104aea222579eb'; // From wrangler.toml
const KV_BINDING = 'MARKDOWN_FILES';

console.log('='.repeat(60));
console.log('Markdown KV Seeder');
console.log('='.repeat(60));
console.log(`Project root: ${PROJECT_ROOT}`);
console.log(`KV Namespace ID: ${KV_NAMESPACE_ID}`);
console.log(`KV Binding: ${KV_BINDING}`);
console.log(`Dry run: ${isDryRun ? 'Yes' : 'No'}`);
console.log(`Force overwrite: ${isForce ? 'Yes' : 'No'}`);
console.log('='.repeat(60));
console.log('');

// Statistics
let stats = {
  total: 0,
  uploaded: 0,
  skipped: 0,
  errors: 0,
  missingFiles: [],
};

/**
 * Upload a file to KV namespace using wrangler CLI
 * @param {string} filePath - Relative path to the file
 * @param {string} content - File content
 * @param {object} metadata - File metadata
 */
function uploadToKV(filePath, content, metadata) {
  try {
    // Create a temporary file with the content
    const tempFile = path.join(__dirname, '.temp-markdown-upload.txt');
    fs.writeFileSync(tempFile, content, 'utf8');

    // Upload using wrangler kv key put (new syntax for wrangler v3+)
    const metadataJson = JSON.stringify(metadata);
    const command = `wrangler kv key put --namespace-id=${KV_NAMESPACE_ID} "${filePath}" --path="${tempFile}" --metadata='${metadataJson}'`;

    if (isDryRun) {
      console.log(`  [DRY RUN] Would execute: ${command}`);
    } else {
      execSync(command, { stdio: 'pipe' });
    }

    // Clean up temp file
    fs.unlinkSync(tempFile);

    return true;
  } catch (error) {
    console.error(`  Error uploading: ${error.message}`);
    return false;
  }
}

/**
 * Get category from file path
 * @param {string} filePath - Relative path to the file
 * @returns {string} Category name
 */
function getCategoryFromPath(filePath) {
  if (filePath.startsWith('docs/')) {
    const filename = path.basename(filePath);
    if (filename.includes('STRATEGY')) return 'Strategy';
    if (filename.includes('AUDIT') || filename.includes('REPORT')) return 'Reports';
    if (filename.includes('ARCHITECTURE') || filename.includes('IMPLEMENTATION')) return 'Architecture';
    return 'Documentation';
  }
  if (filePath.includes('tasks') || filePath.includes('TODO')) return 'Project Tracking';
  if (filePath.includes('CLAUDE') || filePath.includes('SESSION')) return 'Development';
  return 'General';
}

/**
 * Seed all markdown files to KV
 */
async function seedMarkdownFiles() {
  console.log(`Processing ${ALLOWED_FILES.length} whitelisted files...\n`);

  for (const filePath of ALLOWED_FILES) {
    stats.total++;
    const absolutePath = path.join(PROJECT_ROOT, filePath);

    console.log(`[${stats.total}/${ALLOWED_FILES.length}] ${filePath}`);

    // Check if file exists
    if (!fs.existsSync(absolutePath)) {
      console.log(`  ⚠️  File not found (skipping)`);
      stats.skipped++;
      stats.missingFiles.push(filePath);
      console.log('');
      continue;
    }

    // Read file content
    let content;
    try {
      content = fs.readFileSync(absolutePath, 'utf8');
    } catch (error) {
      console.log(`  ❌ Error reading file: ${error.message}`);
      stats.errors++;
      console.log('');
      continue;
    }

    // Get file stats
    const fileStats = fs.statSync(absolutePath);
    const fileSizeKB = (fileStats.size / 1024).toFixed(2);

    console.log(`  Size: ${fileSizeKB} KB`);
    console.log(`  Modified: ${fileStats.mtime.toISOString()}`);

    // Prepare metadata
    const metadata = {
      lastModified: new Date().toISOString(),
      modifiedBy: 'seed-script',
      version: 1,
      commitMessage: 'Initial upload from filesystem',
      category: getCategoryFromPath(filePath),
      size: fileStats.size,
    };

    // Upload to KV
    const success = uploadToKV(filePath, content, metadata);

    if (success) {
      console.log(`  ✅ Uploaded successfully`);
      stats.uploaded++;
    } else {
      console.log(`  ❌ Upload failed`);
      stats.errors++;
    }

    console.log('');
  }

  // Print summary
  console.log('='.repeat(60));
  console.log('Upload Summary');
  console.log('='.repeat(60));
  console.log(`Total files: ${stats.total}`);
  console.log(`Uploaded: ${stats.uploaded}`);
  console.log(`Skipped: ${stats.skipped}`);
  console.log(`Errors: ${stats.errors}`);

  if (stats.missingFiles.length > 0) {
    console.log('');
    console.log('Missing files:');
    stats.missingFiles.forEach(file => {
      console.log(`  - ${file}`);
    });
  }

  console.log('='.repeat(60));

  if (isDryRun) {
    console.log('');
    console.log('This was a dry run. No files were actually uploaded.');
    console.log('Run without --dry-run to perform actual upload.');
  }
}

// Run the seeder
seedMarkdownFiles().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
