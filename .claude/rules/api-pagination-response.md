# API Pagination Response Pattern

**Purpose:** Ensure PaginatedResponse<T> type consistency between API services and components
**Applies to:** Files matching `**/services/*.ts`, `**/api/*.ts`, `**/*Api.ts`
**Priority:** P1 (Prevents runtime errors)
**Created:** January 7, 2026

---

## Rule: Always Return Flat Pagination Structure

### Core Principle

**API service methods must return flat pagination structure matching `PaginatedResponse<T>` type.**

Components expect: `{ data, total, page, limit, totalPages }`
NOT: `{ data, pagination: { total, page, limit, totalPages } }`

### Error Pattern

When this rule is violated, components show:
```
Cannot read properties of undefined (reading 'data')
Cannot read properties of undefined (reading 'total')
```

Or worse: silent failures where pagination controls don't work.

### Standard Pattern

```typescript
// Type definition (what components expect)
interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// ❌ WRONG - Nested pagination (causes undefined errors)
async getItems(): Promise<PaginatedResponse<Item>> {
  const response = await authenticatedFetch('/api/items');
  return response;  // Backend returns { success, items, pagination: {...} }
}

// ✅ CORRECT - Flatten to match type
async getItems(): Promise<PaginatedResponse<Item>> {
  const response = await authenticatedFetch<any>('/api/items');

  // Backend returns { success, items, pagination }
  // Flatten to match PaginatedResponse<T> type
  const pag = response.pagination || { page: 1, limit: 20, total: 0, totalPages: 0 };
  return {
    data: response.items || [],
    total: pag.total,
    page: pag.page,
    limit: pag.limit,
    totalPages: pag.totalPages,
  };
}
```

### Real-World Example

**From:** `apps/litla-admin/src/services/userApi.ts`

```typescript
// ❌ BEFORE (caused "Cannot read properties of undefined")
async getUsers(filters, pagination): Promise<PaginatedResponse<User>> {
  const response = await authenticatedFetch(`/api/admin/users?${params}`);
  return response.data;  // response.data was undefined!
}

// ✅ AFTER (works correctly)
async getUsers(filters, pagination): Promise<PaginatedResponse<User>> {
  const response = await authenticatedFetch<any>(`/api/admin/users?${params}`);

  // Backend returns { success, users, pagination }
  // Flatten to match PaginatedResponse<T> type
  const pag = response.pagination || { page: 1, limit: 20, total: 0, totalPages: 0 };
  return {
    data: response.users || [],
    total: pag.total,
    page: pag.page,
    limit: pag.limit,
    totalPages: pag.totalPages,
  };
}
```

### Backend Response Patterns

Different backends return pagination differently. Always normalize:

| Backend Pattern | Normalize To |
|-----------------|--------------|
| `{ data, pagination: {...} }` | `{ data, total, page, limit, totalPages }` |
| `{ items, meta: {...} }` | `{ data: items, total: meta.total, ... }` |
| `{ users, pagination: {...} }` | `{ data: users, total, page, ... }` |
| `{ results, count, next, previous }` | `{ data: results, total: count, ... }` |

### Verification Checklist

When implementing paginated API methods:

- [ ] Check TypeScript type definition for return shape
- [ ] Log backend response to see actual structure
- [ ] Flatten nested pagination to match type
- [ ] Provide defaults for missing pagination: `{ page: 1, limit: 20, total: 0, totalPages: 0 }`
- [ ] Test component receives correct properties

### Debugging Steps

When pagination doesn't work:

1. **Check console for errors**: "Cannot read properties of undefined"
2. **Log API response**: `console.log('API response:', response)`
3. **Compare shapes**: Backend response vs TypeScript type
4. **Flatten in service**: Transform response to match type

---

## References

- **Pattern Source:** UserManagement CRUD fix (January 7, 2026)
- **Affected Files:** `userApi.ts` - getUsers, fleetApi.getAssignments, containerApi.getAssignments
- **Root Cause:** Type mismatch between API service return and PaginatedResponse<T>

---

**This rule prevents runtime errors from pagination type mismatches.**
