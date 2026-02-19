# Create E2E Test Infrastructure

**Purpose:** Scaffold complete E2E test infrastructure for new customer-facing features

**Usage:** `/create-e2e-test [feature-name]`

**Example:** `/create-e2e-test customer-portal`

---

## What This Creates

1. **Playwright Test File** (`tests/[feature-name].spec.ts`)
   - Test configuration constants (URLs, credentials)
   - Helper functions (login, navigation)
   - Test groups by functionality
   - All tests marked as `.skip` initially

2. **Test Data Script** (`tests/setup-[feature-name]-data.sql`)
   - Customer/user creation
   - Related entity creation (containers, orders, etc.)
   - Password hash placeholder
   - Foreign key relationships

3. **Testing Guide** (`tests/[FEATURE_NAME]_TESTING.md`)
   - Quick start instructions
   - Prerequisites checklist
   - Test data setup commands
   - Configuration steps
   - Troubleshooting guide

4. **Password Hash Generator** (if not exists: `generate-test-password.mjs`)
   - PBKDF2 hash generation
   - 100,000 iterations
   - Copy-paste ready output

---

## Workflow

**1. Analyze Feature:**
- Identify customer-facing pages
- List API endpoints to test
- Determine required test data

**2. Create Test File:**
```typescript
// tests/[feature-name].spec.ts
import { test, expect, type Page } from '@playwright/test';

const BACKEND_URL = 'http://localhost:8787';
const FRONTEND_URL = 'http://localhost:4321';

const TEST_CUSTOMER = {
  email: 'test-[feature]@litla.is',
  password: 'TestPassword123!',
  customerId: 'CUST-TEST-[FEATURE]',
};

async function loginAsCustomer(page: Page) {
  // Login helper implementation
}

test.describe('[Feature] - Authentication', () => {
  test.skip('should login successfully', async ({ page }) => {
    // Test implementation
  });
});

// Additional test groups:
// - Dashboard
// - Detail Pages
// - Forms
// - API Integration
```

**3. Create Test Data Script:**
```sql
-- tests/setup-[feature-name]-data.sql

-- 1. Create test customer
INSERT OR IGNORE INTO customers (id, name, email, ...)
VALUES ('CUST-TEST-[FEATURE]', 'Test Customer', 'test-[feature]@litla.is', ...);

-- 2. Create test user
-- Check schema first: PRAGMA table_info(users)
INSERT INTO users (id, email, name, password_hash, role, customer_id, ...)
VALUES ('USER-TEST-[FEATURE]', 'test-[feature]@litla.is', 'Test User', '[PASSWORD_HASH]', 'customer', 'CUST-TEST-[FEATURE]', ...);

-- 3. Create related entities
-- (containers, orders, etc.)

-- 4. Verification queries
SELECT * FROM customers WHERE id = 'CUST-TEST-[FEATURE]';
SELECT * FROM users WHERE id = 'USER-TEST-[FEATURE]';
```

**4. Create Testing Guide:**
```markdown
# [Feature Name] E2E Testing Guide

## Status
- ✅ Test infrastructure: Complete
- ⚠️ Test data: Needs configuration
- ⏸️ Tests: Ready to run (marked as .skip)

## Quick Start

### 1. Prerequisites
- Backend running: `cd packages/workers && npm run dev`
- Frontend running: `cd apps/litlagamaleigan-web && npm run dev`

### 2. Setup Test Data
# Generate password hash
node packages/workers/generate-test-password.mjs

# Update SQL script with hash
# Replace [PASSWORD_HASH] in tests/setup-[feature-name]-data.sql

# Execute script
npx wrangler d1 execute litla-gamaleigan-db --local \
  --file tests/setup-[feature-name]-data.sql

### 3. Configure Tests
# Update TEST_CUSTOMER constants in tests/[feature-name].spec.ts

### 4. Run Tests
# Remove .skip from tests
# Run: npx playwright test tests/[feature-name].spec.ts --ui

## Test Coverage
- [ ] Authentication
- [ ] Dashboard
- [ ] Detail pages
- [ ] Forms/submissions
- [ ] API integration
- [ ] Security (ownership validation)

## Troubleshooting
[Common issues and solutions]
```

**5. Verify Schema:**
```bash
# ALWAYS check actual schema before creating test data
npx wrangler d1 execute litla-gamaleigan-db --local \
  --command "PRAGMA table_info(users)"

npx wrangler d1 execute litla-gamaleigan-db --local \
  --command "PRAGMA table_info(containers)"

# Update SQL script to match actual columns
```

---

## Standard Test Structure

### Test Groups (describe blocks):
1. **Authentication** - Login, logout, session persistence
2. **Dashboard** - List views, statistics, navigation
3. **Detail Pages** - Entity details, related data
4. **Forms** - Create, update, validation
5. **API Integration** - Direct endpoint testing
6. **Security** - Ownership validation, access control

### Test Patterns:
```typescript
// ✅ GOOD: Comprehensive coverage
test.describe('[Feature] - [Area]', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsCustomer(page);
  });

  test.skip('should [action]', async ({ page }) => {
    // Arrange
    await page.goto('/feature/page');

    // Act
    await page.click('button');

    // Assert
    await expect(page.locator('.result')).toBeVisible();
  });
});

// API tests with fetch
test.skip('API: should list resources', async () => {
  const response = await fetch(`${BACKEND_URL}/api/resources`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });

  expect(response.status).toBe(200);
  const data = await response.json();
  expect(data).toHaveProperty('data');
});
```

---

## Files Checklist

After running this command, verify:

- [ ] `tests/[feature-name].spec.ts` - Test file created
- [ ] `tests/setup-[feature-name]-data.sql` - Data script created
- [ ] `tests/[FEATURE_NAME]_TESTING.md` - Guide created
- [ ] `generate-test-password.mjs` - Hash generator exists
- [ ] Schema verified for all tables used
- [ ] Test constants updated with feature-specific values
- [ ] All tests marked as `.skip` initially

---

## Next Steps

1. **Validate test data script:**
   ```bash
   ./scripts/validate-test-data.sh tests/setup-[feature-name]-data.sql
   ```

2. **Generate password hash:**
   ```bash
   node packages/workers/generate-test-password.mjs
   ```

3. **Execute test data:**
   ```bash
   npx wrangler d1 execute litla-gamaleigan-db --local \
     --file tests/setup-[feature-name]-data.sql
   ```

4. **Configure tests:**
   - Update TEST_CUSTOMER constants
   - Remove `.skip` from tests

5. **Run tests:**
   ```bash
   npx playwright test tests/[feature-name].spec.ts --ui
   ```

---

**Time Savings:** 20-30 minutes per feature test setup
**Benefit:** Standardized, complete test infrastructure every time
