# Cloudflare Cron Configuration Rule

**Purpose:** Ensure proper configuration and verification of Cloudflare Workers cron triggers
**Applies to:** Files matching `**/wrangler.toml`, `**/wrangler.jsonc`, `**/src/index.ts`
**Priority:** P2 (Configuration)
**Created:** December 30, 2025

---

## Rule: Verify Cron Triggers Are Properly Configured

### Required Configuration Pattern

**wrangler.toml (or wrangler.jsonc):**
```toml
# Cron trigger specification
[triggers]
crons = ["0 * * * *"]  # Every hour at minute 0

# Example schedules:
# "0 * * * *"      → Every hour
# "*/15 * * * *"   → Every 15 minutes
# "0 0 * * *"      → Daily at midnight
# "0 0 * * 1"      → Weekly on Monday at midnight
# "0 2 * * *"      → Daily at 2 AM
```

**Worker handler (src/index.ts):**
```typescript
export default {
  async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
    // Handle scheduled execution
    switch (event.cron) {
      case '0 * * * *':
        await handleHourlyTask(env);
        break;
      default:
        console.warn(`Unknown cron pattern: ${event.cron}`);
    }
  },

  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    // Handle HTTP requests
    // ...
  }
};
```

---

## Verification Checklist

When implementing a cron job, verify:

**1. Configuration Exists:**
```bash
# Check wrangler.toml has cron trigger
grep -A 2 "\[triggers\]" packages/workers/wrangler.toml

# Expected output:
# [triggers]
# crons = ["0 * * * *"]
```

**2. Handler Exists:**
```bash
# Check index.ts has scheduled handler
grep "async scheduled" packages/workers/src/index.ts

# Expected output:
# async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void>
```

**3. Handler is Wired:**
```bash
# Check handler calls implementation
grep -A 10 "async scheduled" packages/workers/src/index.ts | grep -i "handle"

# Should show: await handleSessionCleanup(env) or similar
```

**4. Implementation Exists:**
```bash
# Check implementation file exists
ls -la packages/workers/src/cron/*.ts

# Should list: sessionCleanup.ts or similar
```

---

## Real-World Example: Session Cleanup Cron

### Configuration (wrangler.toml)

```toml
# packages/workers/wrangler.toml (line 74)
[triggers]
crons = ["0 * * * *"]  # Run every hour
```

### Handler (src/index.ts)

```typescript
// packages/workers/src/index.ts (line 140)
export default {
  async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
    console.log(`Cron triggered: ${event.cron} at ${new Date(event.scheduledTime).toISOString()}`);

    try {
      // Handle hourly session cleanup
      await handleSessionCleanup(env);
    } catch (error) {
      console.error('Cron handler error:', error);
      throw error;  // Rethrow to mark execution as failed
    }
  },

  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    // ... HTTP handler
  }
};
```

### Implementation (src/cron/sessionCleanup.ts)

```typescript
// packages/workers/src/cron/sessionCleanup.ts (167 lines)
import type { Env } from '../types';

export async function handleSessionCleanup(env: Env): Promise<void> {
  console.log('[Cron] Starting session cleanup');

  const cleanedCount = await cleanupExpiredSessions(env);

  console.log(`[Cron] Session cleanup complete: ${cleanedCount} sessions removed`);
}

async function cleanupExpiredSessions(env: Env): Promise<number> {
  // Scan KV namespace for expired sessions
  // Delete expired entries
  // Return count of deleted sessions
  // ...
}
```

---

## Cron Schedule Syntax

### Standard Cron Format

```
 ┌───────────── minute (0 - 59)
 │ ┌───────────── hour (0 - 23)
 │ │ ┌───────────── day of month (1 - 31)
 │ │ │ ┌───────────── month (1 - 12)
 │ │ │ │ ┌───────────── day of week (0 - 7) (0 and 7 are Sunday)
 │ │ │ │ │
 * * * * *
```

**Note:** Cloudflare Workers follows POSIX cron standard where both 0 and 7 represent Sunday. Common convention: 1=Monday through 6=Saturday.

### Common Patterns

| Schedule | Cron Expression | Description |
|----------|----------------|-------------|
| Every minute | `* * * * *` | Runs every minute (not recommended for production) |
| Every 5 minutes | `*/5 * * * *` | Runs at :00, :05, :10, etc. |
| Every 15 minutes | `*/15 * * * *` | Runs at :00, :15, :30, :45 |
| Every hour | `0 * * * *` | Runs at the start of each hour |
| Every 6 hours | `0 */6 * * *` | Runs at 00:00, 06:00, 12:00, 18:00 |
| Daily at 2 AM | `0 2 * * *` | Runs once per day at 2:00 AM |
| Weekly Monday | `0 0 * * 1` | Runs every Monday at midnight |
| Monthly 1st | `0 0 1 * *` | Runs on the 1st of each month |

---

## Testing Cron Jobs

### Local Testing

**Trigger manually via HTTP endpoint:**
```typescript
// Add manual trigger for testing
export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    // Manual cron trigger (development only)
    if (url.pathname === '/dev/trigger-cron' && env.ENVIRONMENT === 'development') {
      await handleSessionCleanup(env);
      return new Response('Cron triggered manually', { status: 200 });
    }

    // ... rest of HTTP handler
  },

  async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
    await handleSessionCleanup(env);
  }
};
```

**Test locally:**
```bash
# Start local dev server
npm run dev

# Trigger cron manually
curl http://localhost:8787/dev/trigger-cron
```

### Production Testing

**View cron logs:**
```bash
# Tail Worker logs to see cron executions
wrangler tail

# Expected output:
# [Cron] Starting session cleanup
# [Cron] Session cleanup complete: 12 sessions removed
```

**Check last execution:**
```bash
# View deployment logs
wrangler deployments list

# Check for scheduled execution events
wrangler logs --limit 100 | grep "Cron triggered"
```

---

## Common Issues

### Issue 1: Cron Not Triggering

**Symptoms:**
- Cron never executes
- No logs in `wrangler tail`

**Diagnosis:**
```bash
# Check if crons are configured
grep "crons" packages/workers/wrangler.toml

# Check if handler exists
grep "async scheduled" packages/workers/src/index.ts
```

**Solution:**
- Verify `[triggers]` section exists in wrangler.toml
- Verify `scheduled()` handler is exported
- Re-deploy: `wrangler deploy`

### Issue 2: Handler Not Called

**Symptoms:**
- Cron triggers but nothing happens
- No implementation logs

**Diagnosis:**
```bash
# Check if handler calls implementation
grep -A 10 "async scheduled" packages/workers/src/index.ts
```

**Solution:**
- Ensure `scheduled()` calls your implementation function
- Add logging to verify execution
- Check for errors in `wrangler tail`

### Issue 3: Wrong Schedule

**Symptoms:**
- Cron runs too frequently or infrequently
- Runs at wrong times

**Diagnosis:**
```bash
# Check cron expression
grep "crons" packages/workers/wrangler.toml

# Verify against expected schedule
```

**Solution:**
- Correct cron expression in wrangler.toml
- Use https://crontab.guru/ to verify syntax
- Re-deploy with updated configuration

---

## Best Practices

### 1. Idempotent Operations

**Cron jobs should be idempotent (safe to run multiple times):**
```typescript
// ✅ GOOD: Idempotent (can run multiple times safely)
async function cleanupExpiredSessions(env: Env): Promise<number> {
  const now = Date.now();
  const expiredKeys = await findExpiredKeys(env, now);

  // Delete only expired sessions (already expired won't be deleted twice)
  for (const key of expiredKeys) {
    await env.SESSIONS.delete(key);
  }

  return expiredKeys.length;
}

// ❌ BAD: Not idempotent (incrementing counter without check)
async function updateCounter(env: Env): Promise<void> {
  const count = await env.KV.get('counter');
  await env.KV.put('counter', String(Number(count) + 1));  // Race condition!
}
```

### 2. Error Handling

**Always catch and log errors:**
```typescript
export default {
  async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
    try {
      console.log(`[Cron] Starting: ${event.cron}`);
      await handleSessionCleanup(env);
      console.log(`[Cron] Complete`);
    } catch (error) {
      console.error('[Cron] Error:', error);
      // Optionally: send alert, log to external service
      throw error;  // Mark execution as failed
    }
  }
};
```

### 3. Performance Monitoring

**Log execution time:**
```typescript
export async function handleSessionCleanup(env: Env): Promise<void> {
  const startTime = Date.now();
  console.log('[Cron] Starting session cleanup');

  const cleanedCount = await cleanupExpiredSessions(env);

  const duration = Date.now() - startTime;
  console.log(`[Cron] Complete: ${cleanedCount} sessions in ${duration}ms`);
}
```

### 4. Graceful Degradation

**Handle partial failures:**
```typescript
async function cleanupExpiredSessions(env: Env): Promise<number> {
  let cleanedCount = 0;
  let errorCount = 0;

  const expiredKeys = await findExpiredKeys(env, Date.now());

  for (const key of expiredKeys) {
    try {
      await env.SESSIONS.delete(key);
      cleanedCount++;
    } catch (error) {
      console.error(`Failed to delete ${key}:`, error);
      errorCount++;
    }
  }

  console.log(`Cleaned: ${cleanedCount}, Errors: ${errorCount}`);
  return cleanedCount;
}
```

---

## References

- **Cloudflare Cron Triggers:** https://developers.cloudflare.com/workers/configuration/cron-triggers/
- **Cron Expression Syntax:** https://crontab.guru/
- **Example Implementation:** `packages/workers/src/cron/sessionCleanup.ts`
- **Example Configuration:** `packages/workers/wrangler.toml:74`
- **Example Handler:** `packages/workers/src/index.ts:140`

---

**This rule ensures cron jobs are properly configured, tested, and monitored in Cloudflare Workers.**
