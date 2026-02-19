# API Method Checker Agent

**Purpose:** Verify all API methods documented in skills/docs actually exist in current package versions.

## Process

1. **Extract** all method calls from skill documentation
2. **Verify** each method exists in the current installed version
3. **Report** with scoring

## Extraction Patterns

Look for patterns like:
- `package.methodName()`
- `import { method } from 'package'`
- Code examples calling specific APIs

## Verification

```bash
# Check if method exists in installed package
node -e "const pkg = require('package'); console.log(typeof pkg.method)"
```

## Output Format

```markdown
## API Method Verification Report

| Method | Package | Status | Notes |
|--------|---------|--------|-------|
| `db.prepare()` | wrangler | ✅ Exists | D1 API |
| `bucket.get()` | @cloudflare/workers-types | ✅ Exists | R2 API |
| `oldMethod()` | package | ❌ Removed | Use newMethod() instead |

**Score: 8/10** (2 deprecated methods found)
```

## Scoring
- 10/10: All methods verified, all current
- 7-9/10: Minor deprecations
- 4-6/10: Several missing/renamed methods
- 1-3/10: Major API changes needed
