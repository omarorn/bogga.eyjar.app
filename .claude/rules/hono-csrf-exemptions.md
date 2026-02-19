---
paths: "**/middleware/csrf*.ts", "**/index.ts"
---

# Hono CSRF Exemption Patterns

When configuring CSRF protection middleware in Hono, use path prefixes to exempt entire endpoint groups.

## Pattern

Use the shortest path prefix that covers all endpoints you want to exempt.

## Corrections

| If Claude suggests... | Use instead... |
|----------------------|----------------|
| `exemptPaths: ['/api/cms/sections', '/api/cms/images']` | `exemptPaths: ['/api/cms']` |
| Individual endpoint paths | Shortest common prefix |

## Example - This Project

```typescript
// ❌ Verbose - Hard to maintain
app.use('/*', csrfProtection({
  exemptPaths: [
    '/api/auth/login',
    '/api/auth/csrf-token',
    '/api/cms/sections',
    '/api/cms/sections/:key',
    '/api/cms/images',
    '/api/cms/images/:key',
    '/api/cms/history/:key',
    '/api/innforsla',
    '/health',
  ]
}));

// ✅ Clean - Uses prefixes
app.use('/*', csrfProtection({
  exemptPaths: [
    '/api/auth/login',      // Needs token before auth
    '/api/auth/csrf-token', // Provides the token
    '/api/innforsla',       // IoT devices (no CSRF capability)
    '/api/cms',             // CMS endpoints (until frontend implements CSRF)
    '/health',              // Health check
  ]
}));
```

## Why Use Prefixes

1. **Maintainability**: Adding `/api/cms/rollback` is automatically covered by `/api/cms`
2. **Readability**: Clear intent - "all CMS endpoints" vs listing each one
3. **Less error-prone**: Can't forget to add new endpoints to the list

## When to Exempt

- **Login endpoints**: Need token before authentication
- **CSRF token endpoints**: Provide the token itself
- **IoT/machine endpoints**: Devices can't handle CSRF tokens
- **Health checks**: Monitoring systems
- **Temporary**: Endpoints where frontend hasn't implemented CSRF yet

## When NOT to Exempt

- Endpoints that modify data (unless temporary)
- User-facing forms (should implement CSRF)
- Any endpoint accessible from browser without token

## Implementation Notes

This project uses Hono middleware from `packages/workers/src/middleware/csrfProtection.ts`.

CSRF tokens are:
- Generated per session
- Stored in KV
- Validated using timing-safe comparison
- Required for POST, PUT, DELETE, PATCH (mutating operations)

Exempt paths should be reviewed regularly and reduced as frontend implements proper CSRF token handling.
