---
paths: "packages/workers/**/*.ts", "apps/**/*auth*.tsx", "**/*user*.ts"
---

# Auth0 Hybrid Migration Strategy

This project uses a hybrid authentication approach to migrate from password-based to OTP-based auth without forcing immediate user action.

## Authentication Method Types

```typescript
type AuthMethod = 'otp_only' | 'password_fallback' | 'passkey';
```

| Method | Description | Use Case |
|--------|-------------|----------|
| `otp_only` | Auth0 passwordless (SMS/Email OTP) | New users, migrated users |
| `password_fallback` | Password hash stored in database | Existing users during migration |
| `passkey` | WebAuthn/FIDO2 passkeys | Future-preferred, phishing-resistant |

**Note (2025):** Consider passkeys (WebAuthn) as the ultimate migration target. Passkeys are:
- Phishing-resistant (unlike SMS OTP which is vulnerable to SIM-swap and Storm-2372 style attacks)
- User-friendly (biometric or device PIN)
- Supported by Auth0 and all major browsers

## Database Schema Pattern

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL,

  -- Hybrid auth fields
  auth_method TEXT DEFAULT 'password_fallback',  -- Migration support
  password_hash TEXT,                            -- Nullable for OTP-only users

  -- Verification tracking
  email_verified INTEGER DEFAULT 0,
  phone_verified INTEGER DEFAULT 0,

  -- Timestamps
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  last_login_at INTEGER
);
```

## Authentication Flow Logic

```typescript
// Backend authentication handler
async function authenticateUser(email: string, password?: string, otp?: string) {
  const user = await db.getUser(email);

  if (user.auth_method === 'otp_only') {
    // Auth0 passwordless flow
    return await verifyAuth0Token(otp);
  } else {
    // Password fallback for migration period
    if (!password) {
      return { error: 'Password required for this account' };
    }
    return await verifyPasswordHash(password, user.password_hash);
  }
}
```

## Migration Workflow

1. **Phase 1**: All existing users have `auth_method='password_fallback'`
2. **Phase 2**: Users migrate by:
   - Admin sets `auth_method='otp_only'` and clears `password_hash`
   - OR user completes OTP verification, system auto-migrates
3. **Phase 3**: New users created with `auth_method='otp_only'` by default
4. **Phase 4** (future): Deprecate `password_fallback`, all users on OTP

## Admin User Creation Pattern

```typescript
// New admin users: OTP-only with temporary password fallback
await createUser({
  email: 'admin@example.com',
  auth_method: 'otp_only',       // Primary: Auth0 OTP
  password_hash: tempHash,        // Fallback: temporary password
  email_verified: 0,              // Must verify via OTP first
});
```

## Context

This hybrid approach allows gradual migration from password-based authentication to Auth0 passwordless OTP without disrupting existing users. Users can continue using passwords during transition, then migrate to OTP when ready.

## Related Files

- `packages/workers/src/utils/auth.ts` - Authentication logic
- `packages/workers/src/scripts/seed-admins.ts` - Admin creation with hybrid auth
- `apps/litla-admin/src/types/user.ts` - User type definitions with `auth_method`
