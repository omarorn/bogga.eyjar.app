---
paths: "tests/**", "src/**/*.test.*"
---

# Test Import Verification After Refactoring

**Purpose:** Detect broken test imports after code refactoring.

## The Problem

After refactoring (moving files, renaming exports, restructuring modules), tests often reference old paths. This causes:
- `"X is not a function"` errors despite production working
- `"Cannot find module"` errors
- Tests silently testing undefined values

## Detection Pattern

```
Error: myFunction is not a function
```

This typically means the import path is wrong, not that the function doesn't exist.

## Prevention Checklist

After any refactoring:
- [ ] Search tests for old import paths
- [ ] Verify all `import { X } from '...'` paths are valid
- [ ] Run `npm run test` to catch broken imports early
- [ ] Check barrel exports (index.ts) are updated

## Fix Pattern

```typescript
// OLD (broken after refactoring)
import { handleStories } from '../src/routes/stories';

// NEW (updated path)
import { handleStories } from '../src/routes/stories/index';
```
