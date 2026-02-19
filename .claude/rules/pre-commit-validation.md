# Pre-Commit Validation Gates

**Purpose:** Mandatory checks before any git commit to prevent broken code from entering the repo
**Applies to:** All commits
**Priority:** P1 (Critical)

---

## Gate Checklist

Run these checks BEFORE every `git commit`. All must pass.

### 1. TypeScript Compilation
```bash
npm run typecheck
```
- ❌ **ABORT** if: new errors introduced above baseline
- ✅ **PASS** if: error count same or lower than baseline

### 2. Lint
```bash
npm run lint
```
- ⚠️ **WARN** if: new violations in changed files
- ✅ **PASS** if: no new violations

### 3. Tests
```bash
npm run test
```
- ❌ **ABORT** if: previously passing tests now fail
- ✅ **PASS** if: all tests pass (new tests optional but encouraged)

### 4. Build
```bash
npm run build
```
- ❌ **ABORT** if: build fails
- ✅ **PASS** if: compiles successfully

### 5. Package Lock Sync (if deps changed)
```bash
npm ci --dry-run
```
- ❌ **ABORT** if: lock file out of sync
- Fix: run `npm install` first

### 6. CSS Build (if styles changed)
```bash
npm run build:css
```
- ❌ **ABORT** if: CSS build fails
- ✅ **PASS** if: output.css generated

### 7. No Secrets in Code
```bash
# Check for common secret patterns
grep -r "sk-\|AKIA\|password.*=.*['\"]" src/ --include="*.ts" --include="*.tsx"
```
- ❌ **ABORT** if: hardcoded secrets found

### 8. Migration Order (if DB changes)
- Migrations must be applied to remote BEFORE deploying code
- Never commit code that depends on unapplied migrations

---

## Quick Command

```bash
npm run typecheck && npm run lint && npm run test && npm run build
```

## When to Skip Gates

- **Never skip typecheck** — broken types = broken production
- **Lint warnings OK** for WIP commits on feature branches
- **Test failures OK** only if the failing test is for the feature you're implementing (mark with TODO)

---

**This rule prevents broken code from entering the repository.**
