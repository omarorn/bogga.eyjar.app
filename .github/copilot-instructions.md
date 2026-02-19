# GitHub Copilot Instructions - Litla Gámaleigan

This file provides coding patterns, security guidelines, and best practices for this project.

---

## Security Patterns

### Timing-Safe Comparison for Secrets

**Always use timing-safe comparison for passwords, API keys, tokens, and JWTs:**

```typescript
// ❌ VULNERABLE: Subject to timing attacks
if (password === storedPassword) { ... }

// ✅ SECURE: Constant-time comparison
import { timingSafeEqual } from './utils/auth';
if (timingSafeEqual(password, storedPassword)) { ... }
```

**Required for:**
- Password verification
- API key validation
- JWT signature verification
- Token comparison

### SQL Injection Prevention

**Always use parameterized queries with `.bind()`:**

```typescript
// ✅ SECURE: Parameterized query
const result = await env.DB.prepare(
  'SELECT * FROM users WHERE id = ?'
).bind(userId).first();

// ❌ VULNERABLE: String concatenation
const result = await env.DB.prepare(
  `SELECT * FROM users WHERE id = ${userId}`
).first();
```

### API Retry Logic

**Retry 5xx errors, skip 4xx errors:**

```typescript
export async function apiCallWithRetry<T>(
  apiCall: () => Promise<T>,
  maxRetries: number = 3
): Promise<{ success: boolean; data?: T; error?: string }> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const data = await apiCall();
      return { success: true, data };
    } catch (error: any) {
      const status = error.status || error.response?.status;

      // Don't retry client errors (4xx)
      if (status >= 400 && status < 500) {
        return { success: false, error: `Client error ${status}` };
      }

      // Last attempt - don't wait
      if (attempt === maxRetries - 1) {
        return { success: false, error: 'Max retries exceeded' };
      }

      // Exponential backoff: 1s, 2s, 4s
      const delay = Math.pow(2, attempt) * 1000;
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}
```

**Retry these:**
- ✅ Network errors (timeout, connection refused)
- ✅ 5xx server errors (500, 502, 503, 504)
- ✅ Rate limiting (429)

**Don't retry these:**
- ❌ 4xx client errors (400, 401, 403, 404)
- ❌ Authentication failures
- ❌ Validation errors

---

## Cloudflare Workers Patterns

### D1 Database Migration Pattern

**Always apply migrations to BOTH local and remote:**

```bash
# 1. Test locally first
wrangler d1 migrations apply my-db --local

# 2. Verify migration
wrangler d1 execute my-db --local --command "SELECT * FROM new_table"

# 3. Apply to production
wrangler d1 migrations apply my-db --remote
```

### Cron Job Pattern

**wrangler.toml configuration:**

```toml
[triggers]
crons = ["0 * * * *"]  # Every hour
```

**Worker handler:**

```typescript
export default {
  async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
    try {
      console.log(`[Cron] Starting: ${event.cron}`);
      await handleScheduledTask(env);
      console.log(`[Cron] Complete`);
    } catch (error) {
      console.error('[Cron] Error:', error);
      throw error;  // Mark execution as failed
    }
  }
};
```

**Best practices:**
- Make operations idempotent (safe to run multiple times)
- Log execution time and results
- Handle partial failures gracefully

---

## Code Organization

### File Size Limits

| Lines | Status | Action Required |
|-------|--------|----------------|
| < 500 | ✅ Acceptable | None |
| 500-1000 | ⚠️ Warning | Consider refactoring |
| 1000-2000 | 🔴 Critical | Refactor immediately |
| > 2000 | ❌ Unacceptable | Emergency refactor |

**Decision tree:**
- File < 500 lines → ✅ OK to add code
- File 500-1000 lines AND adding < 50 lines → ⚠️ OK but warn
- File > 1000 lines OR adding > 50 lines → 🔴 Extract to new module

### Service Signature Pattern

```typescript
export async function processBusinessLogic(
  env: Env,              // Environment first
  identifier: string,    // Entity ID
  data: DataType,        // Context
  callback?: Function    // Optional side effects
): Promise<Result>
```

---

## Astro Patterns

### Import Resolution

**Use `/src/` prefix for processed assets:**

```astro
<!-- ✅ CORRECT: Processed by Astro build -->
<link rel="stylesheet" href="/src/styles/global.css">
<script src="/src/scripts/analytics.ts"></script>

<!-- ❌ WRONG: Looks in public/ directory -->
<link rel="stylesheet" href="/styles/global.css">
```

### JavaScript Variable Scoping

**All `<script>` tags share the same namespace:**

```astro
<script>
  // ✅ GOOD: Single declaration, reused
  const heroVideo = document.querySelector('.hero-video');

  if (heroVideo) {
    heroVideo.play();

    // Reuse same variable for parallax
    window.addEventListener('scroll', () => {
      heroVideo.style.transform = `...`;
    });
  }

  // ❌ BAD: Duplicate declaration causes build error
  // const heroVideo = document.querySelector('.hero-video');
</script>
```

### Navigation Link Patterns

```astro
<!-- Same-page anchor (on landing page) -->
<a href="#contact">Contact</a>

<!-- Cross-page anchor (on other pages) -->
<a href="/#contact">Contact</a>

<!-- Other page anchor -->
<a href="/about#team">Team</a>
```

---

## Testing Patterns

### Test Coverage Thresholds

**Target: 40-60% coverage (sweet spot for ROI)**

- Minimum viable: 40% coverage
- Critical modules: Higher coverage
  - Authentication: 95%+ (security-critical)
  - Cryptography: 98%+ (correctness-critical)
  - Configuration: 100% (stability-critical)

**Pass rate expectations:**
- Acceptable: 96%+ passing tests
- Environment issues OK: 10 failures acceptable if env limitations (not code bugs)

### Test Template Strategy

**Create structured templates, not exhaustive coverage initially:**

```typescript
// auth.spec.ts - Template with critical paths
describe('Authentication', () => {
  it('should display login form', () => { ... });
  it('should login with valid credentials', () => { ... });
  it('should show error with invalid credentials', () => { ... });
  it('should validate empty fields', () => { ... });
  it('should store JWT token', () => { ... });
  it('should logout and clear session', () => { ... });

  // TODO: Add more tests as needed
  // TODO: Add concurrent login tests
  // TODO: Add role-based access tests
});
```

**Expand when:**
- Before production launch (cover P0 paths)
- After bug discovery (add regression test)
- During feature addition (test new functionality)

---

## WSL Development

### Bash Script Line Endings

**Always fix CRLF → LF after creating `.sh` files:**

```bash
# Required after creating/editing bash scripts
sed -i 's/\r$//' script.sh
chmod +x script.sh
./script.sh
```

### Git Authentication

**Commit via CLI, push via VSCode:**

```bash
# 1. Commit via CLI
git add . && git commit -m "message"

# 2. Push via VSCode GUI
# Source Control → Sync Changes
```

---

## Pre-Implementation Verification

### Always Verify Before Assuming Complete

```bash
# ❌ WRONG: Search and assume complete
grep -r "functionName" src/
# Found: src/feature.ts ← DANGEROUS ASSUMPTION

# ✅ CORRECT: Verify implementation depth
grep -r "functionName" src/
wc -l src/feature.ts           # Check line count
grep -c "function\|class" src/feature.ts  # Logic vs interfaces
grep -n "TODO\|FIXME" src/feature.ts      # Check for stubs
```

### Implementation Depth Thresholds

| Lines | Interfaces | Logic | Assessment |
|-------|-----------|-------|------------|
| < 50 | Yes | No | ⚠️ NOT STARTED (5%) |
| 50-100 | Yes | Minimal | 🟠 STARTED (20%) |
| 100-200 | Yes | Partial | 🟡 PARTIAL (50%) |
| 200-500 | Yes | Substantial | 🟢 WORKING (80%) |
| 500+ | Yes | Complete | ✅ COMPLETE (100%) |

---

## Mobile-Responsive Implementation

### Mobile Sidebar Pattern

```tsx
function Layout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="flex h-screen">
      {/* Backdrop (mobile only) */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 md:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar - responsive positioning */}
      <div className={`
        fixed md:static inset-y-0 left-0 z-50
        transform transition-transform duration-300
        md:transform-none
        ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}
      `}>
        <Sidebar onClose={() => setSidebarOpen(false)} />
      </div>

      <div className="flex-1">
        {/* Hamburger (mobile only) */}
        <button
          onClick={() => setSidebarOpen(!sidebarOpen)}
          className="md:hidden p-2"
        >
          {sidebarOpen ? <X /> : <Menu />}
        </button>
        <main><Outlet /></main>
      </div>
    </div>
  );
}
```

### Touch Target Sizes

```css
@media (max-width: 768px) {
  button, a, input { min-height: 44px; }  /* Touch targets */
  input { font-size: 16px; }              /* Prevent iOS zoom */
  table { overflow-x: auto; }             /* Horizontal scroll */
}
```

---

## Video Optimization

### MP4-Only (Recommended)

```html
<video autoplay muted loop playsinline poster="/fallback.jpg">
  <!-- Mobile version (≤768px) -->
  <source
    src="/mobile.mp4"
    type="video/mp4"
    media="(max-width: 768px)"
  >
  <!-- Desktop version (>768px) -->
  <source src="/desktop.mp4" type="video/mp4">
</video>
```

**Benefits:**
- ✅ 99%+ browser support (including iOS/Safari)
- ✅ Single format to maintain
- ✅ Faster implementation

**URL encoding for filenames with spaces:**

```html
<!-- ✅ CORRECT: URL-encoded -->
<source src="/litla%20video-mobile.mp4">

<!-- ❌ WRONG: Spaces break URL -->
<source src="/litla video-mobile.mp4">
```

---

## Logger Utility Pattern

**Structured logging for centralized aggregation:**

```typescript
export function log(level: LogLevel, message: string, context?: LogContext): void {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    message,
    context: processContext(context)
  }));
}

// Usage
const timer = startTimer({ operation: 'database_query' });
await db.query('SELECT...');
timer.end('Query completed'); // Logs duration automatically

// Logger with persistent context
const reqLogger = logger.withContext({ requestId: '123', userId: '456' });
reqLogger.info('Processing request');
reqLogger.error('Request failed', { error: e });
```

**Don't:** Replace all console.log() immediately
**Do:** Create utility, use in new code, migrate gradually

---

## Common Mistakes to Avoid

### 1. Duplicate Variable Declarations

```typescript
// ❌ ERROR: Symbol already declared
const video = document.querySelector('.video');
// ... later in same scope
const video = document.querySelector('.video'); // Build fails!

// ✅ CORRECT: Reuse variable or use unique name
const video = document.querySelector('.video');
// ... reuse video variable
// OR
const parallaxVideo = document.querySelector('.video');
```

### 2. Early Exit in Comparisons

```typescript
// ❌ VULNERABLE: Early exit leaks timing
if (secret === inputSecret) { ... }

// ✅ SECURE: Constant-time comparison
if (timingSafeEqual(secret, inputSecret)) { ... }
```

### 3. Forgetting --remote Flag

```bash
# ❌ BAD: Only affects local database
wrangler d1 migrations apply my-db

# ✅ GOOD: Explicitly target remote
wrangler d1 migrations apply my-db --remote
```

### 4. Non-Idempotent Cron Jobs

```typescript
// ❌ BAD: Race conditions, not idempotent
async function updateCounter(env: Env): Promise<void> {
  const count = await env.KV.get('counter');
  await env.KV.put('counter', String(Number(count) + 1));
}

// ✅ GOOD: Idempotent operation
async function cleanupExpiredSessions(env: Env): Promise<number> {
  const now = Date.now();
  const expiredKeys = await findExpiredKeys(env, now);

  for (const key of expiredKeys) {
    await env.SESSIONS.delete(key);
  }

  return expiredKeys.length;
}
```

---

## Quick Reference

### Cloudflare Cron Schedule Syntax

```
 ┌─ minute (0-59)
 │ ┌─ hour (0-23)
 │ │ ┌─ day of month (1-31)
 │ │ │ ┌─ month (1-12)
 │ │ │ │ ┌─ day of week (0-6)
 * * * * *
```

**Common patterns:**
- Every hour: `0 * * * *`
- Every 15 min: `*/15 * * * *`
- Daily 2 AM: `0 2 * * *`
- Weekly Monday: `0 0 * * 1`

### Tailwind Breakpoints

- `md:hidden` = Hide on desktop (≥768px), show mobile
- `md:static` = Fixed on mobile, static on desktop
- `md:transform-none` = Disable transforms on desktop

### HTTP Status Codes

**Retry these:**
- 500, 502, 503, 504 (server errors)
- 429 (rate limit)
- Network errors

**Don't retry these:**
- 400 (bad request)
- 401 (unauthorized)
- 403 (forbidden)
- 404 (not found)

---

**Last Updated:** January 5, 2026
**Source:** `.claude/CLAUDE.md`
