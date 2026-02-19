---
paths: "package.json", "package-lock.json"
---

# Cloudflare Pages Build Requirements

Cloudflare Pages uses `npm ci` (clean install) which requires exact sync between package.json and package-lock.json.

## Critical Pattern

**After ANY package.json changes:**
```bash
npm install  # Regenerate package-lock.json
git add package-lock.json
git commit -m "deps: Sync lock file after package changes"
```

## Why This Matters

**Local development:**
- `npm install` auto-fixes package-lock.json mismatches
- Developers often don't notice sync issues

**Cloudflare Pages:**
- Uses `npm ci` (clean install)
- FAILS if package.json and lock file don't match exactly
- Cannot auto-fix like `npm install` does

## Error Signature

```
npm error `npm ci` can only install packages when your package.json
and package-lock.json are in sync. Please update your lock file
with `npm install` before continuing.

npm error Missing: [package-name]@[version] from lock file
```

## Common Triggers

1. **Renaming workspace packages:**
   ```json
   // package.json
   "name": "new-package-name"  // Changed from "old-package-name"
   ```
   → Lock file still references "old-package-name"

2. **Adding dependencies manually:**
   ```json
   "dependencies": {
     "new-package": "^1.0.0"  // Added without npm install
   }
   ```

3. **Editing version constraints:**
   ```json
   "dependencies": {
     "existing-package": "^2.0.0"  // Changed from "^1.0.0"
   }
   ```

## Prevention

**Always run after package.json edits:**
```bash
npm install  # Update lock file
npm ci       # Verify it works (same as Cloudflare)
```

**Pre-commit check (optional):**
```bash
# In scripts/pre-commit-check.sh
if ! npm ci --dry-run; then
  echo "❌ package-lock.json out of sync with package.json"
  echo "Run: npm install"
  exit 1
fi
```

## Monorepo Context

This project uses npm workspaces:
- Root package.json manages workspace packages
- Changes to workspace package names require root lock file update
- Example: Renaming "litla-admin" → "litli-sorpstjorinn" required lock file sync

## Context

Discovered when Cloudflare Pages build failed after renaming admin workspace package. Local development worked fine (npm install auto-fixed), but CI/CD failed because `npm ci` is strict.
