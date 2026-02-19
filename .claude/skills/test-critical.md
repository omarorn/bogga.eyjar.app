---
name: test-critical
description: Run critical path tests with pre-test validation and quality metrics
command: /test-critical
---

# Test Critical Paths

Run critical path tests with validation gates and quality reporting.

## Pre-Test Validation

Before running tests, ensure the codebase compiles:

```bash
# 1. Type check (tests import code — broken types = broken tests)
npm run typecheck

# 2. Build verification
npm run build

# 3. Lint check
npm run lint
```

If any fail, fix compilation issues FIRST before testing.

## Critical Flows to Test

1. **Authentication**
   - Login with valid credentials
   - Login with invalid credentials (should fail gracefully)
   - Session persistence across requests
   - Logout and session cleanup

2. **CRUD Operations**
   - Create record with valid data
   - Create record with invalid data (validation)
   - Read single record and list (with pagination)
   - Update record
   - Delete record (if applicable)

3. **API Endpoints**
   - Health check endpoint returns 200
   - Key API routes return correct status codes
   - Error responses match `{ success: false, error: string }` format
   - Pagination format matches `PaginatedResponse<T>`

4. **Page Rendering**
   - Main pages load without console errors
   - Navigation between pages works
   - Mobile viewport (375px) renders correctly

## Execution

```bash
# Run all tests
npm run test

# Run specific critical tests
npm run test -- tests/unit/auth.test.ts
npm run test -- tests/integration/api.test.ts

# E2E critical path (Playwright)
npm run test:e2e -- -g "Critical"
```

## Post-Test Checks

1. **Test isolation**: verify no `.only()` or `.skip()` in test files
   ```bash
   grep -r "\.only\|\.skip" tests/ --include="*.test.*"
   ```
2. **Console errors**: check for errors during test execution
3. **Coverage** (if configured): `npm run test:coverage`
4. **Artifact cleanup**: delete Playwright screenshots/videos if generated

## Report Format

```
## Critical Path Test Results

### Pre-Test Validation
| Check | Status |
|-------|--------|
| TypeScript | ✅ 0 errors |
| Build | ✅ Success |
| Lint | ✅ 0 violations |

### Test Results
| Flow | Status | Duration | Console Errors |
|------|--------|----------|----------------|
| Auth - Login | ✅ | 200ms | 0 |
| Auth - Invalid | ✅ | 150ms | 0 |
| CRUD - Create | ✅ | 180ms | 0 |
| CRUD - Read | ✅ | 120ms | 0 |
| API - Health | ✅ | 50ms | 0 |
| Pages - Main | ✅ | 300ms | 0 |

### Quality Metrics
- **Pass rate:** 6/6 (100%)
- **Console errors:** 0
- **Test isolation:** ✅ (no .only or .skip)
- **Coverage:** N% (if available)

**Result: ALL CRITICAL PATHS PASS** ✅
```
