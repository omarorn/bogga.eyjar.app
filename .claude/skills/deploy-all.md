---
name: deploy-all
description: Deploy all workers with mandatory pre-flight validation gates
command: /deploy-all
---

# Deploy All Workers

Deploy all workers only after ALL validation gates pass.

## Pre-flight Gates (ALL MUST PASS — no exceptions)

### Gate 1: TypeScript Compilation
```bash
npm run typecheck
```
❌ **ABORT** if: any errors (zero tolerance for deploy)

### Gate 2: Tests
```bash
npm run test
```
❌ **ABORT** if: any test failures

### Gate 3: Lint
```bash
npm run lint
```
⚠️ **WARN** if: violations exist, but allow deploy if no errors

### Gate 4: Build
```bash
npm run build
```
❌ **ABORT** if: build fails

### Gate 5: CSS Build (if applicable)
```bash
npm run build:css
```
❌ **ABORT** if: CSS build fails

### Gate 6: Package Lock Sync
```bash
npm ci --dry-run
```
❌ **ABORT** if: lock file out of sync with package.json

### Gate 7: Database Migrations
Check if there are unapplied migrations:
```bash
ls migrations/*.sql
```
If new migrations exist, apply to remote BEFORE deploying code:
```bash
npx wrangler d1 execute {{D1_DATABASE_NAME}} --remote --file=migrations/LATEST.sql
```
❌ **ABORT** if: code depends on unapplied migrations

### Gate 8: Database Backup
```bash
npx wrangler d1 export {{D1_DATABASE_NAME}} --remote --output=backup-$(date +%Y%m%d).sql
```

## Deploy (only after all gates pass)

```bash
# Main worker
npx wrangler deploy

# Additional workers (if applicable)
npx wrangler deploy --config wrangler-{{WORKER_NAME}}.json
```

## Post-Deploy Verification

1. Health check:
```bash
curl "https://api.{{DOMAIN}}/health"
```

2. Check logs for errors:
```bash
npx wrangler tail --format=json | head -50
```

3. Report:
```
## Deployment Report
| Gate | Status |
|------|--------|
| TypeScript | ✅ 0 errors |
| Tests | ✅ N/N passed |
| Lint | ✅/⚠️ |
| Build | ✅ |
| CSS | ✅ |
| Lock Sync | ✅ |
| Migrations | ✅ Applied |
| Backup | ✅ Created |

| Worker | Status | URL |
|--------|--------|-----|
| main | ✅ | https://{{DOMAIN}} |
```
