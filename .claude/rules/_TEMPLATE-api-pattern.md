# API Endpoint Pattern Template

**Purpose:** Standardize API endpoint implementation across 2076 ehf projects
**Applies to:** Files matching `**/api/**/*.ts`, `**/routes/**/*.ts`
**Priority:** P1 (Critical)
**Created:** January 2025
**Author:** 2076 ehf

---

## Rule: All API Endpoints Must Follow Standard Response Pattern

### Required Response Structure

```typescript
// ✅ GOOD: Standard API response
interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: unknown;
  };
  meta?: {
    timestamp: string;
    requestId?: string;
    pagination?: {
      page: number;
      limit: number;
      total: number;
      hasMore: boolean;
    };
  };
}
```

---

## Endpoint Implementation Pattern

### GET Endpoint (Single Resource)

```typescript
// ✅ GOOD: GET /api/items/:id
export async function handleGetItem(
  request: Request,
  env: Env,
  params: { id: string }
): Promise<Response> {
  const requestId = crypto.randomUUID();
  
  try {
    const item = await env.DB.prepare(
      'SELECT * FROM items WHERE id = ?'
    ).bind(params.id).first();
    
    if (!item) {
      return Response.json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: `Item ${params.id} not found`
        },
        meta: { timestamp: new Date().toISOString(), requestId }
      }, { status: 404 });
    }
    
    return Response.json({
      success: true,
      data: item,
      meta: { timestamp: new Date().toISOString(), requestId }
    });
    
  } catch (error) {
    console.error(`[${requestId}] Error:`, error);
    return Response.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred'
      },
      meta: { timestamp: new Date().toISOString(), requestId }
    }, { status: 500 });
  }
}
```

### GET Endpoint (List with Pagination)

```typescript
// ✅ GOOD: GET /api/items?page=1&limit=20
export async function handleListItems(
  request: Request,
  env: Env
): Promise<Response> {
  const url = new URL(request.url);
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '20')));
  const offset = (page - 1) * limit;
  
  try {
    // Get total count
    const countResult = await env.DB.prepare(
      'SELECT COUNT(*) as total FROM items'
    ).first<{ total: number }>();
    const total = countResult?.total || 0;
    
    // Get paginated items
    const items = await env.DB.prepare(
      'SELECT * FROM items ORDER BY created_at DESC LIMIT ? OFFSET ?'
    ).bind(limit, offset).all();
    
    return Response.json({
      success: true,
      data: items.results,
      meta: {
        timestamp: new Date().toISOString(),
        pagination: {
          page,
          limit,
          total,
          hasMore: offset + limit < total
        }
      }
    });
    
  } catch (error) {
    return Response.json({
      success: false,
      error: { code: 'INTERNAL_ERROR', message: 'Failed to fetch items' }
    }, { status: 500 });
  }
}
```

### POST Endpoint (Create)

```typescript
// ✅ GOOD: POST /api/items
export async function handleCreateItem(
  request: Request,
  env: Env
): Promise<Response> {
  const requestId = crypto.randomUUID();
  
  try {
    // Parse and validate input
    const body = await request.json() as { name: string; value: number };
    
    if (!body.name || typeof body.name !== 'string') {
      return Response.json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Name is required and must be a string',
          details: { field: 'name' }
        }
      }, { status: 400 });
    }
    
    // Insert and return created item
    const id = crypto.randomUUID();
    await env.DB.prepare(
      'INSERT INTO items (id, name, value, created_at) VALUES (?, ?, ?, ?)'
    ).bind(id, body.name, body.value || 0, new Date().toISOString()).run();
    
    const created = await env.DB.prepare(
      'SELECT * FROM items WHERE id = ?'
    ).bind(id).first();
    
    return Response.json({
      success: true,
      data: created,
      meta: { timestamp: new Date().toISOString(), requestId }
    }, { status: 201 });
    
  } catch (error) {
    if (error instanceof SyntaxError) {
      return Response.json({
        success: false,
        error: { code: 'INVALID_JSON', message: 'Request body must be valid JSON' }
      }, { status: 400 });
    }
    throw error;
  }
}
```

### PUT/PATCH Endpoint (Update)

```typescript
// ✅ GOOD: PUT /api/items/:id
export async function handleUpdateItem(
  request: Request,
  env: Env,
  params: { id: string }
): Promise<Response> {
  try {
    // Check if exists
    const existing = await env.DB.prepare(
      'SELECT * FROM items WHERE id = ?'
    ).bind(params.id).first();
    
    if (!existing) {
      return Response.json({
        success: false,
        error: { code: 'NOT_FOUND', message: `Item ${params.id} not found` }
      }, { status: 404 });
    }
    
    const body = await request.json() as Partial<{ name: string; value: number }>;
    
    // Update with provided fields
    await env.DB.prepare(
      'UPDATE items SET name = COALESCE(?, name), value = COALESCE(?, value), updated_at = ? WHERE id = ?'
    ).bind(body.name, body.value, new Date().toISOString(), params.id).run();
    
    const updated = await env.DB.prepare(
      'SELECT * FROM items WHERE id = ?'
    ).bind(params.id).first();
    
    return Response.json({
      success: true,
      data: updated,
      meta: { timestamp: new Date().toISOString() }
    });
    
  } catch (error) {
    return Response.json({
      success: false,
      error: { code: 'INTERNAL_ERROR', message: 'Failed to update item' }
    }, { status: 500 });
  }
}
```

### DELETE Endpoint

```typescript
// ✅ GOOD: DELETE /api/items/:id
export async function handleDeleteItem(
  request: Request,
  env: Env,
  params: { id: string }
): Promise<Response> {
  try {
    const existing = await env.DB.prepare(
      'SELECT * FROM items WHERE id = ?'
    ).bind(params.id).first();
    
    if (!existing) {
      return Response.json({
        success: false,
        error: { code: 'NOT_FOUND', message: `Item ${params.id} not found` }
      }, { status: 404 });
    }
    
    await env.DB.prepare('DELETE FROM items WHERE id = ?').bind(params.id).run();
    
    return Response.json({
      success: true,
      data: { deleted: true, id: params.id },
      meta: { timestamp: new Date().toISOString() }
    }, { status: 200 }); // or 204 with no body
    
  } catch (error) {
    return Response.json({
      success: false,
      error: { code: 'INTERNAL_ERROR', message: 'Failed to delete item' }
    }, { status: 500 });
  }
}
```

---

## Error Code Standards

| Code | HTTP Status | Usage |
|------|-------------|-------|
| `VALIDATION_ERROR` | 400 | Invalid input data |
| `INVALID_JSON` | 400 | Malformed JSON body |
| `UNAUTHORIZED` | 401 | Missing or invalid auth |
| `FORBIDDEN` | 403 | Valid auth but no permission |
| `NOT_FOUND` | 404 | Resource doesn't exist |
| `CONFLICT` | 409 | Duplicate or state conflict |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Unexpected server error |

---

## Verification Checklist

- [ ] Response follows `ApiResponse<T>` structure
- [ ] Error responses include `code` and `message`
- [ ] Pagination uses `page`, `limit`, `total`, `hasMore`
- [ ] Request ID generated for tracing
- [ ] Input validation before database operations
- [ ] Proper HTTP status codes used

---

## References

- **Hono Framework:** https://hono.dev/
- **Cloudflare D1:** https://developers.cloudflare.com/d1/

---

**This template ensures consistent, predictable API responses across all 2076 ehf projects.**
