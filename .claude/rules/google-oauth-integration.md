# Google OAuth Integration for Cloudflare Workers

**Purpose:** Step-by-step guide for implementing Google OAuth in Cloudflare Workers + React dashboard
**Applies to:** Files matching `**/routes/auth.ts`, `**/stores/auth.ts`, `**/pages/Login.tsx`
**Priority:** P1 (Authentication)
**Created:** January 2026
**Author:** 2076 ehf

---

## Overview

This guide covers implementing Google OAuth 2.0 authentication with:
- Cloudflare Workers (Hono.js) as backend
- React (Vite) dashboard as frontend
- D1 database for user/session storage
- KV for OAuth state management

---

## Step 1: Google Cloud Console Setup

### 1.1 Create OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create a new project or select existing
3. Click **Create Credentials** → **OAuth client ID**
4. Select **Web application**
5. Add authorized redirect URIs:
   ```
   https://your-worker.workers.dev/api/auth/google/callback
   https://api.yourdomain.com/api/auth/google/callback
   ```
6. Save the **Client ID** and **Client Secret**

### 1.2 Configure OAuth Consent Screen

1. Go to **OAuth consent screen**
2. Select **External** (or Internal for Google Workspace)
3. Fill in app name, support email
4. Add scopes: `openid`, `email`, `profile`
5. Add test users if in testing mode

---

## Step 2: Database Schema

### 2.1 Users Table

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  agency_id TEXT NOT NULL,
  google_id TEXT UNIQUE,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  picture TEXT,
  role TEXT DEFAULT 'user',
  active INTEGER DEFAULT 1,
  last_login_at TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (agency_id) REFERENCES agencies(id) ON DELETE CASCADE
);
```

### 2.2 Sessions Table

```sql
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  agency_id TEXT NOT NULL,
  refresh_token TEXT UNIQUE NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## Step 3: Worker Configuration

### 3.1 wrangler.toml

```toml
[vars]
API_URL = "https://your-worker.workers.dev"
DASHBOARD_URL = "https://your-dashboard.pages.dev"

# Secrets (set via: wrangler secret put SECRET_NAME)
# JWT_SECRET
# GOOGLE_CLIENT_ID
# GOOGLE_CLIENT_SECRET
```

### 3.2 Set Secrets

```bash
# Generate a secure JWT secret
openssl rand -base64 32

# Set secrets
wrangler secret put JWT_SECRET
wrangler secret put GOOGLE_CLIENT_ID
wrangler secret put GOOGLE_CLIENT_SECRET
```

---

## Step 4: Auth Routes (Worker)

### 4.1 auth.ts

```typescript
import { Hono } from 'hono';
import { sign, verify } from 'hono/jwt';

export const authRoutes = new Hono<{ Bindings: Env }>();

// Generate secure random state
function generateState(): string {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}

// Start Google OAuth
authRoutes.get('/google', async (c) => {
  const state = generateState();
  await c.env.SESSIONS.put(`oauth_state:${state}`, 'pending', { expirationTtl: 600 });

  const params = new URLSearchParams({
    client_id: c.env.GOOGLE_CLIENT_ID,
    redirect_uri: `${c.env.API_URL}/api/auth/google/callback`,
    response_type: 'code',
    scope: 'openid email profile',
    state,
    access_type: 'offline',
  });

  return c.redirect(`https://accounts.google.com/o/oauth2/v2/auth?${params}`);
});

// Google OAuth callback
authRoutes.get('/google/callback', async (c) => {
  const code = c.req.query('code');
  const state = c.req.query('state');
  const error = c.req.query('error');

  if (error || !code || !state) {
    return c.redirect(`${c.env.DASHBOARD_URL}/login?error=${error || 'missing_params'}`);
  }

  // Verify state (CSRF protection)
  const storedState = await c.env.SESSIONS.get(`oauth_state:${state}`);
  if (!storedState) {
    return c.redirect(`${c.env.DASHBOARD_URL}/login?error=invalid_state`);
  }
  await c.env.SESSIONS.delete(`oauth_state:${state}`);

  try {
    // Exchange code for tokens
    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id: c.env.GOOGLE_CLIENT_ID,
        client_secret: c.env.GOOGLE_CLIENT_SECRET,
        redirect_uri: `${c.env.API_URL}/api/auth/google/callback`,
        grant_type: 'authorization_code',
      }),
    });

    const tokens = await tokenRes.json() as { access_token: string };

    // Get user info from Google
    const userRes = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
      headers: { Authorization: `Bearer ${tokens.access_token}` },
    });
    const googleUser = await userRes.json() as {
      id: string;
      email: string;
      name: string;
      picture: string;
    };

    // Find user by google_id first, then by email (first-time login)
    let user = await c.env.DB.prepare(
      'SELECT * FROM users WHERE google_id = ?'
    ).bind(googleUser.id).first() as any;

    if (!user) {
      // Try to find by email (first-time login migration)
      user = await c.env.DB.prepare(
        'SELECT * FROM users WHERE email = ?'
      ).bind(googleUser.email).first() as any;

      if (user) {
        // Link Google account for future logins
        await c.env.DB.prepare('UPDATE users SET google_id = ?, updated_at = ? WHERE id = ?')
          .bind(googleUser.id, new Date().toISOString(), user.id).run();
      }
    }

    if (!user) {
      return c.redirect(`${c.env.DASHBOARD_URL}/login?error=no_account`);
    }

    // Update last login and picture
    await c.env.DB.prepare(
      'UPDATE users SET last_login_at = ?, picture = ?, updated_at = ? WHERE id = ?'
    ).bind(new Date().toISOString(), googleUser.picture, new Date().toISOString(), user.id).run();

    // Generate JWT (24 hour expiry)
    const now = Math.floor(Date.now() / 1000);
    const token = await sign({
      sub: user.id,
      email: user.email,
      name: user.name,
      picture: googleUser.picture,
      agency_id: user.agency_id,
      role: user.role,
      iat: now,
      exp: now + 86400,
    }, c.env.JWT_SECRET);

    // Generate refresh token (30 day expiry)
    const refreshToken = generateState();
    await c.env.DB.prepare(
      'INSERT INTO sessions (id, user_id, agency_id, refresh_token, expires_at, created_at) VALUES (?,?,?,?,?,?)'
    ).bind(
      crypto.randomUUID(),
      user.id,
      user.agency_id,
      refreshToken,
      new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      new Date().toISOString()
    ).run();

    // Build user object for dashboard
    const userInfo = {
      id: user.id,
      email: user.email,
      name: user.name,
      picture: googleUser.picture,
      role: user.role,
      agency_id: user.agency_id,
    };
    const userParam = encodeURIComponent(JSON.stringify(userInfo));

    return c.redirect(
      `${c.env.DASHBOARD_URL}/auth/callback?token=${token}&refresh=${refreshToken}&user=${userParam}`
    );
  } catch (err) {
    console.error('OAuth error:', err);
    return c.redirect(`${c.env.DASHBOARD_URL}/login?error=oauth_failed`);
  }
});

// Refresh token endpoint
authRoutes.post('/refresh', async (c) => {
  const { refresh_token } = await c.req.json<{ refresh_token: string }>();
  if (!refresh_token) return c.json({ error: 'Missing refresh token' }, 400);

  const session = await c.env.DB.prepare(
    `SELECT s.*, u.email, u.name, u.picture, u.role
     FROM sessions s
     JOIN users u ON s.user_id = u.id
     WHERE s.refresh_token = ? AND s.expires_at > ?`
  ).bind(refresh_token, new Date().toISOString()).first() as any;

  if (!session) return c.json({ error: 'Invalid refresh token' }, 401);

  const now = Math.floor(Date.now() / 1000);
  const token = await sign({
    sub: session.user_id,
    email: session.email,
    name: session.name,
    picture: session.picture,
    agency_id: session.agency_id,
    role: session.role,
    iat: now,
    exp: now + 86400,
  }, c.env.JWT_SECRET);

  return c.json({ token });
});

// Logout endpoint
authRoutes.post('/logout', async (c) => {
  const { refresh_token } = await c.req.json<{ refresh_token: string }>();
  if (refresh_token) {
    await c.env.DB.prepare('DELETE FROM sessions WHERE refresh_token = ?')
      .bind(refresh_token).run();
  }
  return c.json({ success: true });
});

// Get current user
authRoutes.get('/me', async (c) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  try {
    const payload = await verify(authHeader.slice(7), c.env.JWT_SECRET, 'HS256');
    const user = await c.env.DB.prepare(
      'SELECT * FROM users WHERE id = ?'
    ).bind(payload.sub).first();
    return user ? c.json(user) : c.json({ error: 'Not found' }, 404);
  } catch {
    return c.json({ error: 'Invalid token' }, 401);
  }
});
```

---

## Step 5: Dashboard (React)

### 5.1 Auth Store (Zustand)

```typescript
// stores/auth.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
  id: string;
  email: string;
  name: string;
  picture?: string;
  role: string;
  agency_id: string;
}

interface AuthState {
  token: string | null;
  refreshToken: string | null;
  user: User | null;
  setAuth: (token: string, refreshToken: string, user: User) => void;
  clearAuth: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      refreshToken: null,
      user: null,
      setAuth: (token, refreshToken, user) => set({ token, refreshToken, user }),
      clearAuth: () => set({ token: null, refreshToken: null, user: null }),
    }),
    { name: 'auth-storage' }
  )
);
```

### 5.2 Login Page

```tsx
// pages/Login.tsx
import { useSearchParams } from 'react-router-dom';

const API_URL = import.meta.env.VITE_API_URL;

export default function Login() {
  const [searchParams] = useSearchParams();
  const error = searchParams.get('error');

  const handleGoogleLogin = () => {
    window.location.href = `${API_URL}/api/auth/google`;
  };

  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="max-w-md w-full p-8">
        <h1 className="text-2xl font-bold mb-6">Login</h1>

        {error && (
          <div className="bg-red-100 text-red-700 p-3 rounded mb-4">
            {error === 'no_account' ? 'No account found for this email' : error}
          </div>
        )}

        <button
          onClick={handleGoogleLogin}
          className="w-full flex items-center justify-center gap-2 bg-white border border-gray-300 rounded-lg px-4 py-3 hover:bg-gray-50"
        >
          <img src="/google-icon.svg" alt="Google" className="w-5 h-5" />
          Continue with Google
        </button>
      </div>
    </div>
  );
}
```

### 5.3 Auth Callback Page

```tsx
// pages/AuthCallback.tsx
import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useAuthStore } from '@/stores/auth';

export default function AuthCallback() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { setAuth } = useAuthStore();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const token = searchParams.get('token');
    const refresh = searchParams.get('refresh');
    const userParam = searchParams.get('user');
    const errorParam = searchParams.get('error');

    if (errorParam) {
      setError(errorParam);
      return;
    }

    if (token && refresh && userParam) {
      try {
        const user = JSON.parse(decodeURIComponent(userParam));
        setAuth(token, refresh, user);
        navigate('/', { replace: true });
      } catch {
        setError('Failed to parse user data');
      }
    } else {
      setError('Missing login information');
    }
  }, [searchParams, setAuth, navigate]);

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-xl font-semibold mb-2">Login Failed</h2>
          <p className="text-gray-600 mb-4">{error}</p>
          <a href="/login" className="text-blue-600 hover:underline">
            Try again
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600" />
    </div>
  );
}
```

### 5.4 Routes Configuration

```tsx
// App.tsx
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/auth';
import Login from '@/pages/Login';
import AuthCallback from '@/pages/AuthCallback';
import Dashboard from '@/pages/Dashboard';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { token } = useAuthStore();
  return token ? <>{children}</> : <Navigate to="/login" replace />;
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/auth/callback" element={<AuthCallback />} />
        <Route path="/" element={
          <ProtectedRoute>
            <Dashboard />
          </ProtectedRoute>
        } />
      </Routes>
    </BrowserRouter>
  );
}
```

---

## Step 6: Add Users

### 6.1 Via D1 Console

```bash
# Add admin user (they must log in with Google to link account)
wrangler d1 execute YOUR_DB --remote --command "
INSERT INTO users (id, agency_id, google_id, email, name, role, active, created_at, updated_at)
VALUES ('user-001', 'agency-001', 'pending', 'user@example.com', 'User Name', 'admin', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
"
```

### 6.2 First Login Flow

1. User visits `/login` and clicks "Continue with Google"
2. User authenticates with Google
3. System looks up by `google_id` (won't find)
4. System looks up by `email` (finds user)
5. System updates `google_id` with actual Google ID
6. User is logged in
7. Future logins use `google_id` directly

---

## Troubleshooting

### "no_account" Error

User's email not in database. Add them:
```bash
wrangler d1 execute DB --remote --command "
INSERT INTO users (id, agency_id, google_id, email, name, role, active)
VALUES ('uuid', 'agency-id', 'pending', 'email@example.com', 'Name', 'user', 1);
"
```

### "invalid_state" Error

OAuth state expired or CSRF mismatch. User should try again.

### "oauth_failed" Error

Check worker logs:
```bash
wrangler tail
```

Common causes:
- Wrong `GOOGLE_CLIENT_SECRET`
- Redirect URI mismatch in Google Console
- Network error fetching tokens

### Missing User Info After Login

Ensure the callback includes `user` parameter:
```typescript
const userParam = encodeURIComponent(JSON.stringify(userInfo));
return c.redirect(`...?token=${token}&refresh=${refreshToken}&user=${userParam}`);
```

---

## Security Checklist

- [ ] JWT_SECRET is 32+ characters, randomly generated
- [ ] GOOGLE_CLIENT_SECRET stored as Wrangler secret
- [ ] OAuth state verified before token exchange
- [ ] Redirect URIs match exactly in Google Console
- [ ] Tokens have appropriate expiry (24h access, 30d refresh)
- [ ] HTTPS enforced in production
- [ ] Users table has `active` flag for deactivation

---

## References

- **Google OAuth Documentation:** https://developers.google.com/identity/protocols/oauth2
- **Hono JWT:** https://hono.dev/helpers/jwt
- **Cloudflare Workers:** https://developers.cloudflare.com/workers/

---

**This guide ensures secure, production-ready Google OAuth integration.**
