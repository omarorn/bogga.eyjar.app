# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) and GitHub Actions agents when working with this repository.

**Project:** Bogga - Verkefnalisti app með PIN auðkenningu og deilingu
**Owner:** Ómar Örn Magnússon (omar@2076.is)
**Repository:** github.com/omarorn/bogga.eyjar.app
**Production:** https://bogga.eyjar.app | API: https://api.bogga.eyjar.app
**Philosophy:** Einfaldur, hraðvirkur verkefnalisti fyrir dagleg verkefni

---

## Quick Reference

### Essential Access
```
Main App:       https://bogga.eyjar.app
API:            https://api.bogga.eyjar.app
Admin:          https://admin.bogga.eyjar.app
Staging:        https://staging.bogga.eyjar.app
```

### Cloudflare Resources
```
Account ID:     72ed26d13abd695cc3ae785adb386c27
Account Name:   2076 ehf
D1 Database:    bogga-db (77fd2dc9-526a-40c8-867b-87f069c7f709)
R2 Buckets:     — (ekki notað)
KV Namespaces:  — (ekki notað)
Vectorize:      — (ekki notað) (768-dim, cosine)
Workers:        bogga-app
```

### Cloudflare Secrets
All API keys and passwords stored as secrets (not in code):
```bash
# Set secrets
echo "KEY" | npx wrangler secret put SECRET_NAME
```

**Required Secrets:**
- `ADMIN_PASSWORD` - Admin access
- `JWT_SECRET` - JWT signing key
- `CF_IMAGES_KEY` - Cloudflare Images API key (if using)
- `CLOUDFLARE_API_TOKEN` - Cloudflare API access
- `GEMINI_API_KEY` - Google Gemini API (if using AI features)
- `VAPID_PUBLIC_KEY` - Web Push notifications (if using)
- `VAPID_PRIVATE_KEY` - Web Push notifications (if using)

### Cloudflare Native Solutions Decision Tree
```
Need file storage?     → R2 (not custom file handling)
Need database?         → D1 (not external DB)
Need search?           → Vectorize (not custom embeddings)
Need AI?               → Workers AI (not external APIs when possible)
Need caching?          → KV (not custom cache)
Need image transforms? → Cloudflare Images (not ImageMagick)
Need video processing? → Stream (not ffmpeg)
Need scheduled tasks?  → Cron Triggers (not external schedulers)
Need queues?           → Queues (not custom pub/sub)
Need real-time?        → Durable Objects + WebSocket (not external WS)
```

---

## Project Overview

Bogga er einföld PWA verkefnalistavefsíða fyrir iOS/Android. Notendur skrá sig inn með 4-stafa PIN, búa til lista, bæta við verkefnum með frestum og taggum, og deila listum með gestum án innskráningar.

**Current Status:** Alpha — Grunnvirkni tilbúin

**Tech Stack:**
- **Frontend:** Vanilla JS SPA (engin framework) (e.g., Astro + React + TypeScript + Tailwind CSS + Shadcn/UI)
- **Backend:** Cloudflare Workers + Hono + D1 + R2 + KV
- **Real-time:** WebSocket with Hibernation API (if applicable)
- **AI Integration:** — (ekki notað) (e.g., Claude API, Gemini, Workers AI)
- **Deployment:** Cloudflare Pages + Workers
- **Testing:** Vitest (unit/integration) + Playwright (E2E)
- **CI/CD:** GitHub Actions + Husky pre-commit hooks

---

## Repository Structure

```
bogga.eyjar.app/
├── .claude/
│   ├── rules/                 # Claude Code rules (patterns, security, etc.)
│   ├── commands/              # Custom slash commands
│   ├── skills/                # Custom skills (reusable capabilities)
│   ├── Agents/                # Specialized AI agents
│   ├── settings.json          # Enabled plugins
│   └── mcp-config.json        # MCP server configurations
├── .github/
│   ├── workflows/
│   │   ├── claude.yml         # @claude mention trigger
│   │   ├── claude-code-review.yml  # Automated PR reviews
│   │   └── auto-fix-issues.yml     # Issue → PR automation
│   └── scripts/
│       └── fix-issue.js       # Claude API integration
├── src/                       # Application source code
├── migrations/                # D1 database migrations
├── scripts/                   # Deployment and utility scripts
├── public/                    # Static assets
├── modules/                   # Reusable feature modules (drop-in)
│   ├── r2-file-manager/       # R2 Object Browser with full UI
│   ├── cms/                   # CMS for sections, images, markdown
│   ├── camera-scanner/        # Camera capture + AI classification
│   ├── quiz-game/             # Multi-mode quiz with leaderboards
│   └── driver-location/       # GPS tracking, routes, job management
├── tests/                     # Test suites
├── wrangler.toml              # Cloudflare Workers config
├── CLAUDE.md                  # This file
├── TODO.md                    # Project roadmap
├── completed-tasks.md         # Task completion history & reflection trail
└── README.md                  # Project documentation
```

---

## Architecture

### Multi-Worker System (if applicable)
- **Main Worker:** Pages, APIs, session auth, rate limiting
- **RAG Worker:** Semantic search, AI features (if applicable)
- **Workflows Worker:** AI pipelines with scheduled triggers (if applicable)
- **Scheduled Worker:** Cron tasks (if applicable)

### Key Patterns

**1. Modular Routes** (`src/routes/`)
```typescript
export async function handleX(request: Request, env: Env, userInfo: UserInfo): Promise<Response>
```

**2. Access Control**
```typescript
const ACCESS_HIERARCHY = {
  'public': 0,
  'user': 1,
  'editor': 2,
  'admin': 3,
  'super_admin': 4
};
```

**3. API Response Format**
```typescript
// Success
{ success: true, data: T, message?: string }

// Error
{ success: false, error: string, code?: number }

// Paginated
{ data: T[], total: number, page: number, limit: number, totalPages: number }
```

**4. Security Patterns**
- Timing-safe comparison for secrets/passwords
- Parameterized queries (NEVER string concatenation)
- Customer data isolation (validate ownership)
- Rate limiting on API endpoints

---

## Database

### Schema Pattern (D1/SQLite)
```sql
-- Example core table
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT,
  status TEXT DEFAULT 'active',
  privacy_level INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);
```

### Critical Notes
- `tagged_people` or similar JSON fields are TEXT: **Always parse:** `JSON.parse(field || '[]')`
- Follow FK insertion order (see `database-order.md` rule)
- Always confirm before executing write operations (see `confirmation-workflow.md`)
- Apply migrations to remote BEFORE deploying worker code

### Migration Commands
```bash
# Apply migration locally
npx wrangler d1 execute bogga-db --local --file=migrations/XXX.sql

# Apply migration remotely (BEFORE deploying code!)
npx wrangler d1 execute bogga-db --remote --file=migrations/XXX.sql

# Query database
npx wrangler d1 execute bogga-db --remote --command="SELECT ..."

# Backup
npx wrangler d1 export bogga-db --remote --output=backup-$(date +%Y%m%d).sql
```

---

## Development Commands

### Quick Start
```bash
npm install
npm run cf-typegen         # Generate TS types from wrangler.toml
npm run build:css          # Build Tailwind CSS (if using)
npm run dev                # Start local dev (http://localhost:8787)
```

### Development
```bash
npm run dev                # Local dev server
npm run build:css          # Build Tailwind CSS
npm run cf-typegen         # Generate TS types
npm run typecheck          # Check types
npm run lint               # Lint code
npm run lint:fix           # Auto-fix lint issues
```

### Testing
```bash
npm run test               # Run all tests (Vitest)
npm run test:unit          # Unit tests only
npm run test:integration   # Integration tests only
npm run test:e2e           # E2E tests (Playwright)
npm run test:coverage      # Coverage report
```

### Deployment
```bash
# Main worker
npx wrangler deploy

# Additional workers (if applicable)
npx wrangler deploy --config wrangler-[worker-name].json

# Cloudflare Pages (if using)
npm run deploy:pages
```

### Emergency Commands
```bash
# Health check
curl "https://api.bogga.eyjar.app/health"

# Backup database
npx wrangler d1 export bogga-db --remote --output=backup-$(date +%Y%m%d).sql

# Deploy all
npm run deploy
```

---

## MCP Servers & Plugins

### Enabled Plugins (`.claude/settings.json`)

| Plugin | Purpose | Status |
|--------|---------|--------|
| `serena` | Symbol-level code navigation, LSP | ✅ Active |
| `context7` | Library documentation & examples | ✅ Active |
| `typescript-lsp` | TypeScript language server | ✅ Active |
| `pr-review-toolkit` | Comprehensive PR review agents | ✅ Active |
| `sentry` | Error tracking integration | ✅ Active |
| `playwright` | Browser automation & testing | ✅ Active |
| `frontend-design` | UI/UX design assistance | ✅ Active |
| `huggingface-skills` | HuggingFace integration | ✅ Active |
| `greptile` | Codebase-wide search & understanding | ✅ Active |
| `superpowers` | Enhanced Claude capabilities | ✅ Active |
| `docs-cleaner` | Documentation cleanup | ✅ Active |
| `skill-creator` | Custom skill creation | ✅ Active |
| `history-finder` | Session history file search | ✅ Active |

### MCP Servers (`.claude/mcp-config.json`)

**Cloudflare MCP Suite (7 servers):**
| Server | Purpose |
|--------|---------|
| cloudflare-bindings | D1, R2, KV, Workers AI, Vectorize |
| cloudflare-docs | Search Cloudflare documentation |
| cloudflare-builds | Deploy and build management |
| cloudflare-observability | Logs, analytics, monitoring |
| cloudflare-ai-gateway | AI Gateway management |
| cloudflare-graphql | GraphQL API access |
| cloudflare-radar | Internet insights, trends |

**Other MCP Servers:**
| Server | Purpose | Requires |
|--------|---------|----------|
| github | GitHub API (issues, PRs, repos) | GITHUB_TOKEN |
| airtable | Airtable database operations | AIRTABLE_API_KEY |
| supabase | Supabase database & auth | SUPABASE_URL, SUPABASE_ANON_KEY |
| railway | Railway deployments | RAILWAY_TOKEN |
| docker | Docker container management | - |
| icelandic-morphology | BÍN morphology (Icelandic projects) | - |

---

## Claude Code Rules (`.claude/rules/`)

### Core Rules
| Rule | Purpose |
|------|---------|
| `golden-rules.md` | Core development principles |
| `confirmation-workflow.md` | Confirm before DB changes |
| `database-order.md` | FK constraint insertion order |
| `timing-safe-comparison.md` | Constant-time security comparisons |
| `naming-conventions.md` | Backend snake_case ↔ Frontend camelCase |

### Cloudflare Rules
| Rule | Purpose |
|------|---------|
| `cloudflare-workers-assets.md` | Static asset serving patterns |
| `cloudflare-pages-build.md` | Lock file sync for Pages |
| `cloudflare-pages-limits.md` | 25MB file limits, R2 for large files |
| `cloudflare-cron.md` | Cron trigger configuration |
| `durable-objects-separation.md` | Business logic extraction from DOs |

### UI/Frontend Rules
| Rule | Purpose |
|------|---------|
| `mobile-touch-targets.md` | 44px minimum touch targets |
| `tailwind-production.md` | Never use CDN, always compiled CSS |
| `html-content-escaping.md` | Escape content in JS strings |
| `form-component-ids.md` | Form ID override patterns |
| `modal-close-handlers.md` | Optional chaining for onClose |
| `button-component-patterns.md` | Button component limitations |

### Icelandic Language Rules (for Icelandic projects)
| Rule | Purpose |
|------|---------|
| `icelandic-ui.md` | All UI text in Icelandic |
| `icelandic-onclick-escaping.md` | Escape Icelandic in onclick |

### Quality & Validation Rules
| Rule | Purpose |
|------|---------|
| `pre-commit-validation.md` | Mandatory gates before every git commit |
| `lsp-integration.md` | LSP tools for code analysis workflows |

### Development Rules
| Rule | Purpose |
|------|---------|
| `session-protocol.md` | Cross-session state management |
| `task-status.md` | Honest task status assessment |
| `todo-tracking.md` | Phase work tracking |
| `bash-scripts.md` | Script execution patterns |
| `test-import-verification.md` | Verify imports after refactoring |

### Templates
| Rule | Purpose |
|------|---------|
| `_TEMPLATE-rule.md` | Template for creating new rules |
| `_TEMPLATE-database.md` | Database operation patterns |
| `_TEMPLATE-api-pattern.md` | API endpoint patterns |
| `_TEMPLATE-component.md` | UI component patterns |

---

## Skills (`.claude/skills/`)

| Skill | Command | Purpose |
|-------|---------|---------|
| `check-types` | `/check-types` | Run TypeScript type checking |
| `db-backup` | `/db-backup` | Backup D1 database |
| `deploy-all` | `/deploy-all` | Deploy all workers |
| `test-critical` | `/test-critical` | Run critical path tests |
| `phase-next` | `/phase-next` | Move to next development phase |
| `verify-phase` | `/verify-phase` | Verify phase completion |
| `icelandic-grammar` | `/icelandic-grammar` | Review Icelandic text |

---

## Agents (`.claude/Agents/`)

| Agent | Purpose |
|-------|---------|
| `api-method-checker` | Verify API methods in documentation |
| `code-example-validator` | Validate code examples |
| `content-accuracy-auditor` | Compare docs vs official sources |
| `version-checker` | Check package version references |
| `icelandic-reviewer` | Review Icelandic grammar |

---

## Commands (`.claude/commands/`)

| Command | Purpose |
|---------|---------|
| `/todo-oom` | Serena + multi-agent task delegation from todo.md |
| `/fix-oom` | Serena + Playwright feature testing, document issues in todo.md |
| `/oom-reflect` | Deep reflection — what works, what's missing, honest status audit |
| `/document-agent` | Document agent/session deliverables with Serena verification |
| `/create-e2e-test` | Scaffold E2E test infrastructure |

### `/todo-oom` Workflow (Task Delegation)

The primary automation command. Runs a 4-phase workflow:

1. **Ultrathink** — Audit codebase with Serena symbolic tools before writing code. Check if features/scripts already exist.
2. **Delegate** — Spawn multiple agents (Explore, Plan, feature-dev, code-simplifier) in parallel. Use Serena symbolic editing, MCP servers, and skills.
3. **Execute** — Run implementation via `/ralph-loop` with completion promise and max iterations.
4. **Track** — Update `completed-tasks.md` after each task, git commit regularly, run `/reflect`, note all Claude session IDs.

**Usage:**
```
/todo-oom
```

### `completed-tasks.md` Format

Each project should maintain a `completed-tasks.md` for reflection history:

```markdown
## [Date] — [Task Name]
- **Status:** ✅ Complete
- **Files:** `src/routes/example.ts`, `migrations/001.sql`
- **Session:** [Claude session ID]
- **Approach:** [Brief description]
- **Learnings:** [Key takeaways]
```

---

## Security Patterns

### Timing-Safe Comparison (CRITICAL)
```typescript
// VULNERABLE: Subject to timing attacks
if (password === storedPassword) { ... }

// SECURE: Constant-time comparison
import { timingSafeEqual } from './utils/auth';
if (timingSafeEqual(password, storedPassword)) { ... }
```

### SQL Injection Prevention
```typescript
// SECURE: Parameterized query
const result = await env.DB.prepare(
  'SELECT * FROM users WHERE id = ?'
).bind(userId).first();

// VULNERABLE: String concatenation
const result = await env.DB.prepare(
  `SELECT * FROM users WHERE id = ${userId}`
).first();
```

### Customer Data Isolation
```typescript
const record = await c.env.DB.prepare(
  'SELECT * FROM tasks WHERE id = ? AND owner_id = ?'
).bind(recordId, user.id).first();

if (!record) {
  return c.json({ error: 'Not found' }, 404); // Not 403 to avoid info leak
}
```

---

## Common Pitfalls

### 1. JSON Column Parsing
```typescript
// WRONG
const people = story.tagged_people;  // Returns string

// CORRECT
const people = JSON.parse(story.tagged_people || '[]');
```

### 2. Package Lock Sync (CI/CD Critical)
```bash
# After ANY package.json changes
npm install                    # Regenerate package-lock.json
npm ci                         # Verify it works (same as Cloudflare)
git add package-lock.json
```

### 3. Wrangler Config Selection
```bash
# Main worker
npx wrangler deploy

# Additional workers - specify config
npx wrangler deploy --config wrangler-[worker-name].json
```

### 4. Migration Order
```bash
# ALWAYS deploy migrations BEFORE code
npx wrangler d1 execute bogga-db --remote --file=migrations/XXX.sql
npx wrangler deploy
```

### 5. Workers Constraints
- No filesystem access (use R2/D1)
- 128MB memory limit (stream large files)
- 30s CPU time limit (use Workflows for long tasks)
- Web APIs only (no Node.js built-ins)

---

## Icelandic Language (for Icelandic projects)

### Rules
- ALL UI text in Icelandic
- Store names in nominative case (nefnifall)
- Support characters: á, ð, é, í, ó, ú, ý, þ, æ, ö
- Escape Icelandic chars in onclick handlers

### Morphology MCP Server
Available tools for Icelandic text processing:
| Tool | Purpose | Example |
|------|---------|---------|
| `lookup_word` | All interpretations of a word | `lookup_word("færi")` |
| `get_variant` | Specific grammatical variants | `get_variant("hestur", "kk", ["ÞGF", "FT"])` → "hestum" |
| `get_lemma` | Base form and word class | `get_lemma("hestana")` → `{lemma: "hestur"}` |

### BÍN Grammatical Tags
```
Cases:   NF (nominative), ÞF (accusative), ÞGF (dative), EF (genitive)
Number:  ET (singular), FT (plural)
Gender:  kk (masculine), kvk (feminine), hk (neuter)
```

---

## Task Management

### Status Markers
| Marker | Meaning |
|--------|---------|
| ✅ | Complete (100%) |
| 🔄 | In Progress |
| ⏸️ | Pending |
| 🚫 | Blocked |
| 🟣 | Manual task (requires user action) |
| ⚠️ | Issues but can proceed |

### Honest Assessment
| Status | Meaning |
|--------|---------|
| COMPLETE ✅ | 100% done, tested, verified |
| WORKING 🟢 | Core functionality works |
| PARTIAL 🟡 | Some features working |
| STARTED 🟠 | Code exists but incomplete |
| NOT STARTED ⚠️ | No implementation yet |

### Session Continuity
**When starting a new session:**
1. Read `SESSION.md` for current phase (if exists)
2. Check `TODO.md` for overall status
3. Review known issues
4. Continue from last checkpoint

---

## Environment Variables

### Development (`.env` or `.dev.vars`)
```bash
# See .env.example for all available variables
JWT_SECRET=your-secret-here
ENVIRONMENT=development
LOG_LEVEL=debug
```

### Production (via Wrangler secrets)
```bash
npx wrangler secret put JWT_SECRET
npx wrangler secret put ADMIN_PASSWORD
npx wrangler secret put CLOUDFLARE_API_TOKEN
```

### GitHub Secrets (for Actions)
| Secret | Purpose |
|--------|---------|
| `ANTHROPIC_API_KEY` | Claude API for issue automation |
| `CLAUDE_CODE_OAUTH_TOKEN` | Claude Code Action authentication |
| `CF_API_TOKEN` | Cloudflare deployment |

---

## Deployment Checklist

### Before Deploying
- [ ] Run `npm ci` to verify package lock sync
- [ ] Run `npm run typecheck` for type errors
- [ ] Run `npm run lint` for code style
- [ ] Run `npm run test` for tests
- [ ] Apply D1 migrations to remote (`--remote` flag)
- [ ] Test locally with `npm run dev`

### After Deploying
- [ ] Verify health endpoint: `curl https://api.bogga.eyjar.app/health`
- [ ] Check Cloudflare dashboard for errors
- [ ] Test critical user flows
- [ ] Monitor logs for errors

---

## Common Errors to Avoid

<!-- Auto-generated by claude-reflect. Add session-specific learnings here -->

- Always deploy D1 migrations to remote BEFORE deploying worker code
- `File` class is not available in Workers runtime - use typed assertions
- Run Worker dev server from correct directory
- Package-lock.json must be in sync for Cloudflare Pages deployment

---

## Guardrails

<!-- Auto-generated by claude-reflect. Review and edit as needed. -->
- Don't overwrite existing component files that use handler-prop patterns
- Confirm before executing database write operations
- Never use Tailwind CDN in production
- Follow FK constraint insertion order

---

## 2076 ehf Ecosystem

**Domains:**
- 2076.is - Company website
- myx.is - MyX portal ecosystem
- eyjar.app - Demo/staging apps

**Related Projects:**
- omar.eyjar.app — Persónuleg heimasíða
- myhealth.myx.is — Heilsurakningarapp
- dentist.myx.is — Tannlæknasíða

---

**This file is the single source of truth for Claude Code agents working in this repository.**
**Last Updated:** 2026-02-19
