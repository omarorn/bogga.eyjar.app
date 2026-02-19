# Golden Rules: 2076 Cloudflare Project Development

**Purpose**: Core development principles for 2076 ehf Cloudflare Workers projects
**Last Updated**: 2026-02-08
**Applies to**: All 2076 Cloudflare Workers development

---

## Project Structure

```
project/
├── src/                  # Application source code
│   ├── index.ts          # Main worker entry (Hono app)
│   ├── routes/           # API route handlers
│   ├── pages/            # HTML page generators
│   ├── services/         # Business logic
│   ├── components/       # Reusable UI components
│   └── utils/            # Helper functions
├── migrations/           # D1 database migrations
├── public/               # Static assets (compiled CSS, icons)
├── scripts/              # Utility scripts
├── tests/                # Test suites
├── .claude/              # Claude Code configuration
└── CLAUDE.md             # Project guidance
```

---

## Development Commands

### Quick Start
```bash
npm install
npm run cf-typegen         # Generate TS types from wrangler bindings
npm run build:css          # Build Tailwind CSS
npm run dev                # Local dev (http://localhost:8787)
```

### Testing
```bash
npm run test               # Vitest
npm run test:e2e           # Playwright
npm run typecheck          # TypeScript
npm run lint               # ESLint
```

### Deployment
```bash
npx wrangler deploy        # Deploy to Cloudflare
```

---

## API Patterns

### Standard Hono Route Handler
```typescript
import { Hono } from 'hono';

const app = new Hono<{ Bindings: Env }>();

app.get('/api/items', async (c) => {
  const items = await c.env.DB.prepare('SELECT * FROM items WHERE status = ?')
    .bind('active')
    .all();
  return c.json({ success: true, data: items.results });
});

app.post('/api/items', async (c) => {
  const body = await c.req.json();
  // Validate input...
  const result = await c.env.DB.prepare('INSERT INTO items (title) VALUES (?)')
    .bind(body.title)
    .run();
  return c.json({ success: true, data: { id: result.meta.last_row_id } }, 201);
});
```

### Paginated Response
```typescript
// Always use flat structure matching PaginatedResponse<T>
return c.json({
  data: items,
  total: count,
  page: page,
  limit: limit,
  totalPages: Math.ceil(count / limit)
});
```

### Error Response
```typescript
return c.json({ success: false, error: 'Description of error' }, 400);
```

---

## Platform Limitations (Cloudflare Workers)

| Limit | Value | Workaround |
|-------|-------|------------|
| Memory | 128 MB | Stream large files, paginate queries |
| CPU time | 30 seconds | Use Workflows/Durable Objects for long tasks |
| Request size | 100 MB | Upload directly to R2 |
| D1 row size | 100 KB | Split large content across rows |
| Script size | 10 MB | Code-split, lazy imports |
| Subrequest limit | 1,000/request | Batch operations |

**No Node.js built-ins**: Use Web APIs only (fetch, crypto, TextEncoder, etc.)

---

## TypeScript Standards

### Env Interface
```typescript
interface Env {
  DB: D1Database;
  BUCKET: R2Bucket;
  KV: KVNamespace;
  ASSETS: Fetcher;
  JWT_SECRET: string;
  ADMIN_PASSWORD: string;
  ENVIRONMENT: string;
}
```

### Generate Types
```bash
npm run cf-typegen  # Generates worker-configuration.d.ts from wrangler.toml
```

---

## Security Rules

1. **Timing-safe comparison** for ALL secrets/passwords/tokens
2. **Parameterized queries** for ALL database operations (NEVER string concat)
3. **Customer data isolation** - validate ownership on every request
4. **Rate limiting** on API endpoints (100 req/min per IP)
5. **CORS headers** only for allowed origins
6. **CSRF protection** via Hono middleware

---

## Database Rules

1. **FK insertion order**: Base tables → Main entities → Relationships → Analysis
2. **Confirm before writes**: Show proposed changes, wait for approval
3. **Migrations before code**: Deploy D1 migrations BEFORE deploying worker code
4. **JSON columns are TEXT**: Always `JSON.parse(field || '[]')`
5. **Backup before destructive ops**: `/db-backup` before DELETE/DROP

---

## UI/Frontend Rules

1. **Mobile-first**: 44px minimum touch targets
2. **Tailwind compiled**: Never CDN (see `tailwind-production.md`)
3. **HTML escaping**: Always escape user content (see `html-content-escaping.md`)
4. **Icelandic chars**: Escape in onclick attributes (see `icelandic-onclick-escaping.md`)
5. **Form IDs**: Explicit ID override when JS expects specific IDs

---

## Testing Strategy

1. **Unit tests**: Business logic, utils, services
2. **Integration tests**: API endpoints with mock D1/R2
3. **E2E tests**: Critical user flows with Playwright
4. **Type checking**: `npm run typecheck` as part of CI

---

## Task Completion Checklist

After completing any task:
- [ ] `npm run typecheck` — no new errors
- [ ] `npm run test` — all tests pass
- [ ] `npm run lint` — no warnings
- [ ] Build CSS if styles changed: `npm run build:css`
- [ ] Barrel exports updated (if adding routes/pages)
- [ ] Migrations deployed to remote before code deploy

---

## AI Behavior Rules

1. **Read before writing**: Always read existing code before modifying
2. **Confirm destructive actions**: Show plan before DB writes
3. **Preserve content**: Never shorten user content (stories, messages, etc.)
4. **Follow existing patterns**: Match the codebase style
5. **Test changes**: Run relevant tests after modifications
6. **Document changes**: Update relevant docs/comments

---

## Quick Reference

| Need | Solution |
|------|----------|
| New API endpoint | `src/routes/` → export from index → add route in index.ts |
| New page | `src/pages/` → export chain → add route |
| Database change | New migration file → apply local → apply remote → deploy |
| Static asset | Put in `public/` → served via Assets binding |
| Large file | Upload to R2, serve via signed URL |
| Background job | Cloudflare Workflows or Cron Triggers |
| Real-time | Durable Objects + WebSocket Hibernation API |
| AI feature | Workers AI or Gemini API via service |
