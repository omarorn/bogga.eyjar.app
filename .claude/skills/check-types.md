---
name: check-types
description: Run TypeScript type checking and categorize errors
command: /check-types
---

# TypeScript Type Check

Run TypeScript type checking without building. Categorize and track errors.

## Steps

1. Run `npm run typecheck` (or `npx tsc --noEmit`)
2. Count total errors
3. Categorize errors by type:
   - Missing type annotations
   - Implicit `any` types
   - Null/undefined safety
   - Missing imports
   - Type mismatches
   - Other
4. Show summary table:

```
## TypeScript Error Summary

| Category | Count | Example |
|----------|-------|---------|
| Implicit any | 12 | Parameter 'x' implicitly has 'any' type |
| Null safety | 8 | Object is possibly 'null' |
| Type mismatch | 5 | Type 'string' not assignable to 'number' |
| **Total** | **25** | |
```

5. Suggest top 3 quick fixes
6. Compare to baseline (if known): `{{BASELINE_ERRORS}} errors → current`
