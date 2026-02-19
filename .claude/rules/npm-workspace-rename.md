---
paths: "package.json", "apps/*/package.json", "packages/*/package.json"
---

# NPM Workspace Package Rename Workflow

Renaming a workspace package requires updating package.json, lock file, and optionally related HTML/config files.

## Workflow

### Step 1: Identify All References

**Search for old package name:**
```bash
grep -r "old-package-name" .
```

**Common locations:**
- `apps/old-package-name/package.json` - Package name field
- `apps/old-package-name/index.html` - Title and meta tags
- `package-lock.json` - Auto-generated references
- README.md, documentation files

### Step 2: Update Package Definition

**Edit workspace package.json:**
```json
{
  "name": "new-package-name",  // Changed
  "private": true,
  "version": "0.0.0"
}
```

### Step 3: Update Related Files (Optional)

**HTML entry point (if applicable):**
```html
<!-- apps/new-package-name/index.html -->
<title>New Package Name - Project</title>
<meta name="description" content="New Package Name description" />
```

### Step 4: Sync Lock File (CRITICAL)

```bash
npm install  # Regenerate package-lock.json
```

**Verify the update:**
```bash
grep "new-package-name" package-lock.json
# Should show new name, not old name
```

### Step 5: Test Locally

```bash
npm ci  # Test clean install (same as CI/CD)
cd apps/new-package-name
npm run dev  # Verify package works
```

### Step 6: Commit Changes

```bash
git add package.json package-lock.json apps/*/package.json apps/*/index.html
git commit -m "refactor: Rename package from old-name to new-name

- Updated package.json name field
- Updated index.html title/meta
- Synced package-lock.json

🤖 Generated with Claude Code"
```

## Common Mistakes

❌ **Forgetting lock file sync:**
- Edit package.json
- Commit without running npm install
- CI/CD fails with "Missing: new-package-name from lock file"

❌ **Renaming directory but not package.json:**
- Rename `apps/old-name/` → `apps/new-name/`
- Forget to update `apps/new-name/package.json` → `"name": "old-name"`
- Causes workspace resolution errors

❌ **Partial updates:**
- Update package.json
- Forget to update HTML title/meta tags
- Users see old name in browser tabs

## Project Context: Litla Gámaleigan

**Workspace structure:**
```
apps/
  litlagamaleigan-web/     # Landing page
  litla-admin/             # Admin dashboard
  litla-drivers/           # Driver app
  litla-support/           # Support app
```

**Recent rename:**
- "litla-admin" → "litli-sorpstjorinn"
- Updated package.json, index.html, and 5 Astro navigation menus
- Required lock file sync to fix Cloudflare Pages build

## Why Lock File Sync Matters

Cloudflare Pages uses `npm ci` which requires exact package-lock.json sync. Without it:
```
npm error Missing: new-package-name@0.0.0 from lock file
Build failed
```

See also: `.claude/rules/cloudflare-pages-build.md`

## Context

Discovered while renaming admin package from "Stjórnborð" (Dashboard) to "Litli Sorpstjórinn" (Little Waste Manager). Initial commit missed lock file sync, causing deployment failure.
