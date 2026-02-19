## 🚨 Critical Blocker for Customer Portal Launch

### Problem
The customer portal frontend is **100% complete** (6 Astro pages built and ready), but customers **cannot access their data** due to a backend authorization mismatch.

**Current Behavior:**
- Frontend: Calls `/api/gamar` with customer JWT token
- Backend: Has `staffOnly` middleware (admin/operator only)
- Result: **403 Forbidden** - customers are blocked

### Impact
- ❌ Customer portal is **completely non-functional**
- ❌ Customers cannot view their containers
- ❌ Customers cannot view fill levels or sensor data
- ❌ Customers cannot submit collection requests
- ❌ **Blocks customer validation phase** (Phase 2A)

### Root Cause
Backend API endpoints assume only staff access. No customer-specific endpoints or middleware exist.

**Evidence:**
- `packages/workers/src/routes/containers.ts:29` - `staffOnly` middleware
- `apps/litlagamaleigan-web/src/pages/portal/yfirlit.astro:479` - Calls `/api/gamar`
- No `customerOnly` middleware in codebase
- JWT tokens don't include `customer_id` for auto-filtering

---

## Solution

### 1. Create Customer Middleware
**File:** `packages/workers/src/middleware/auth.ts`

```typescript
export const customerOnly = async (c: Context, next: Function) => {
  const user = c.get('user');
  if (!user || user.role !== 'customer') {
    return c.json({ error: 'Customer access required' }, 403);
  }
  await next();
};

export const staffOrCustomer = async (c: Context, next: Function) => {
  const user = c.get('user');
  if (!user || !['admin', 'operator', 'customer'].includes(user.role)) {
    return c.json({ error: 'Unauthorized' }, 403);
  }
  await next();
};
```

### 2. Create Customer Portal Routes
**File:** `packages/workers/src/routes/customerPortal.ts` (new file, ~300 lines)

Endpoints needed:
- `GET /api/customer/gamar` - List my containers (auto-filtered by customer_id)
- `GET /api/customer/gamar/:id` - Container details (with ownership check)
- `GET /api/customer/pantanir` - My orders
- `GET /api/customer/reikningar` - My invoices
- `POST /api/customer/beidnir` - Create collection request

**Critical Security:** All endpoints must validate ownership:
```typescript
const container = await c.env.DB.prepare(
  'SELECT * FROM containers WHERE id = ? AND customer_id = ?'
).bind(containerId, user.customer_id).first();

if (!container) {
  return c.json({ error: 'Not found or access denied' }, 404);
}
```

### 3. Update JWT Payload
**File:** `packages/workers/src/utils/auth.ts`

Add `customer_id` to token claims:
```typescript
const token = await sign({
  user_id: user.id,
  customer_id: user.customer_id, // REQUIRED for auto-filtering
  role: user.role,
  name: user.name,
  email: user.email,
}, secret);
```

### 4. Update Frontend API URLs
**Files to modify:**
- `apps/litlagamaleigan-web/src/pages/portal/yfirlit.astro` (line 479)
- `apps/litlagamaleigan-web/src/pages/portal/gamur/[id].astro` (line 414)
- `apps/litlagamaleigan-web/src/pages/portal/pantanir.astro`
- `apps/litlagamaleigan-web/src/pages/portal/reikningar.astro`
- `apps/litlagamaleigan-web/src/pages/portal/beidnir.astro`

Change:
```javascript
const apiUrl = '/api/gamar';
```
To:
```javascript
const apiUrl = '/api/customer/gamar';
```

---

## Implementation Checklist

### Backend
- [ ] Create `customerOnly` middleware in `auth.ts`
- [ ] Create `staffOrCustomer` middleware in `auth.ts`
- [ ] Create `customerPortal.ts` route file
- [ ] Implement `GET /api/customer/gamar` (list containers)
- [ ] Implement `GET /api/customer/gamar/:id` (container details + ownership check)
- [ ] Implement `GET /api/customer/pantanir` (orders)
- [ ] Implement `GET /api/customer/reikningar` (invoices)
- [ ] Implement `POST /api/customer/beidnir` (collection requests)
- [ ] Update JWT payload to include `customer_id`
- [ ] Register customer routes in `index.ts`
- [ ] Add rate limiting (`apiRateLimit`)

### Frontend
- [ ] Update `portal/yfirlit.astro` API URL (line 479)
- [ ] Update `portal/gamur/[id].astro` API URL (line 414)
- [ ] Update `portal/pantanir.astro` API URL
- [ ] Update `portal/reikningar.astro` API URL
- [ ] Update `portal/beidnir.astro` API URL

### Security Testing
- [ ] Test ownership isolation (Customer A cannot access Customer B's data)
- [ ] Test endpoint authorization (only customers can access `/api/customer/*`)
- [ ] Test JWT includes `customer_id`
- [ ] Test rate limiting
- [ ] Test error messages don't leak sensitive info

### Integration Testing
- [ ] Login as customer → receive JWT with `customer_id`
- [ ] View containers → only see my containers
- [ ] View container details → ownership verified
- [ ] Submit collection request → validated against my containers
- [ ] Try to access other customer's container → 404 (not 403 to avoid info leak)

---

## Files to Change

| File | Lines | Type |
|------|-------|------|
| `packages/workers/src/middleware/auth.ts` | +50 | Add middleware |
| `packages/workers/src/routes/customerPortal.ts` | +300 | New file |
| `packages/workers/src/index.ts` | +5 | Register routes |
| `packages/workers/src/utils/auth.ts` | ~5 | Update JWT payload |
| `apps/litlagamaleigan-web/src/pages/portal/yfirlit.astro` | ~3 | URL change |
| `apps/litlagamaleigan-web/src/pages/portal/gamur/[id].astro` | ~3 | URL change |
| `apps/litlagamaleigan-web/src/pages/portal/pantanir.astro` | ~3 | URL change |
| `apps/litlagamaleigan-web/src/pages/portal/reikningar.astro` | ~3 | URL change |
| `apps/litlagamaleigan-web/src/pages/portal/beidnir.astro` | ~3 | URL change |

**Total:** ~375 lines of code across 9 files

---

## Testing Commands

```bash
# 1. Login as customer
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"customer@example.is","password":"test123"}'

# Expected: JWT token with customer_id claim

# 2. List containers (should work)
curl http://localhost:8787/api/customer/gamar \
  -H "Authorization: Bearer [TOKEN]"

# Expected: Only customer's containers

# 3. Get container details (should work)
curl http://localhost:8787/api/customer/gamar/[MY_CONTAINER_ID] \
  -H "Authorization: Bearer [TOKEN]"

# Expected: Container details + alerts + readings

# 4. Try to access other customer's container (should fail)
curl http://localhost:8787/api/customer/gamar/[OTHER_CUSTOMER_CONTAINER] \
  -H "Authorization: Bearer [TOKEN]"

# Expected: 404 Not Found (ownership check failed)

# 5. Submit collection request
curl -X POST http://localhost:8787/api/customer/beidnir \
  -H "Authorization: Bearer [TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{"container_id":"[MY_CONTAINER]","requested_date":"2026-01-10","priority":"normal","notes":"Please collect ASAP"}'

# Expected: 200 OK with request ID
```

---

## References

- **Frontend Implementation:** `apps/litlagamaleigan-web/src/pages/portal/`
- **Current Backend (staffOnly):** `packages/workers/src/routes/containers.ts:29`
- **User Manual:** `docs/manuals/CUSTOMER_PORTAL_MANUAL.md`
- **Architecture Analysis:** See comprehensive analysis in planning session
- **Task Specification:** `tasks.md` → TASK-145

---

## Priority Justification

**Why P0 (Critical):**
1. **Blocks customer validation** - Cannot test portal with real customers
2. **Complete frontend wasted** - 6 fully built pages are non-functional
3. **User manual already written** - 656 lines ready but portal doesn't work
4. **Simple fix** - 6 hours estimated, high ROI
5. **Security risk if rushed** - Ownership validation must be done correctly

**Estimated Effort:** 6 hours
**Risk if Not Fixed:** Customer portal launch impossible
**Blocks:** TASK-140 (Find 5 pilot customers), Phase 2A completion
