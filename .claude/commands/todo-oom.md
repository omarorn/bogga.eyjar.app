---
description: Delegate tasks from todo.md using Serena + multi-agent orchestration
---

## Phase 1: Ultrathink — Plan & Audit

Use Serena's symbolic tools (`find_symbol`, `get_symbols_overview`, `search_for_pattern`) and multiple agents to deeply analyze the codebase BEFORE writing any code.

For each task in `todo.md`:
1. **Check if the feature already exists** — use `find_symbol` and `search_for_pattern` to scan for existing implementations
2. **Check if scripts/utilities already exist** — search `scripts/`, `src/utils/`, and `src/services/` before creating new files
3. **Check if there's a plugin, skill, or MCP tool** that already handles the task — review `.claude/skills/`, `.claude/commands/`, and `.claude/mcp-config.json`
4. **Map dependencies** — use `find_referencing_symbols` to understand what the change would affect

Only proceed to implementation after confirming the feature is genuinely missing.

## Phase 1.5: LSP Validation Gate — Establish Baseline

Before delegating any work, capture the current health of the codebase:

1. **TypeScript baseline**: `npm run typecheck 2>&1 | tail -5` — note error count
2. **Test baseline**: `npm run test` — note pass/fail count
3. **Lint baseline**: `npm run lint 2>&1 | tail -5` — note violation count
4. **Build check**: `npm run build` — confirm it compiles
5. **Type contracts**: use `find_symbol` with `include_info=true` on interfaces you'll modify — understand type signatures before changing them
6. **Break analysis**: use `find_referencing_symbols` on any symbol you plan to modify — map all callers

**Gate rule:** If typecheck has errors above baseline or build fails, fix those FIRST before implementing new features. Do not add new code on top of a broken baseline.

## Phase 2: Delegate with Serena + Multiple Agents

Use the **Task tool** to spawn specialized agents in parallel where possible:
- **Explore agent** — for codebase research and finding existing patterns
- **Plan agent** — for designing implementation approaches
- **feature-dev agents** — `code-explorer`, `code-architect`, `code-reviewer` for feature implementation
- **code-simplifier** — for cleanup after implementation

Use **Serena's symbolic editing** (`replace_symbol_body`, `insert_after_symbol`) for precise code modifications instead of file-level edits.

Leverage **MCP servers** where applicable:
- `cloudflare-bindings` for D1/R2/KV operations
- `cloudflare-docs` for API reference
- `context7` for library documentation
- `icelandic-morphology` for Icelandic text processing
- Other MCP servers as needed per task

Use **skills** when they match the task:
- `/check-types` after TypeScript changes
- `/db-backup` before database modifications
- `/deploy-all` for deployment tasks
- `/icelandic-grammar` for Icelandic text review
- `/verify-phase` for phase completion checks

## Phase 3: Execute with Ralph Loop

After planning is complete, execute the implementation using:

```
/ralph-loop "Implement tasks from todo.md following the approved plan" --max-iterations 25 --completion-promise "All tasks from todo.md have been implemented, tested, and documented in completed-tasks.md"
```

## Phase 3.5: Post-Implementation Validation Gates

After each task is implemented, run these checks BEFORE committing:

1. **TypeScript**: `npm run typecheck` — must not introduce new errors above baseline
2. **Lint**: `npm run lint` — new code must follow project style
3. **Tests**: `npm run test` — existing tests must still pass
4. **Build**: `npm run build` — must compile successfully
5. **Import verification**: use `find_symbol` to confirm new exports are reachable
6. **Barrel exports**: if new files added, verify `index.ts` re-exports are updated
7. **package-lock.json**: if dependencies changed, run `npm install` then verify with `npm ci --dry-run`
8. **CSS build**: if styles changed, run `npm run build:css`
9. **Migration order**: if DB changes, apply migrations to remote BEFORE deploying code

**Gate rule:** Do NOT commit or mark a task complete if any gate fails. Fix first, then commit.

## Phase 4: Track Progress & Document

Throughout execution:
- **Update `completed-tasks.md`** after each task is done — include:
  - Task description and status
  - Files created/modified
  - Claude session ID for reflection history
  - Timestamp and approach used
- **Git commit regularly** — commit after each logical unit of work with descriptive messages
- **Use `/reflect`** periodically to capture learnings
- **Note all Claude sessions** in completed-tasks.md for the reflection history trail

## Phase 5: Reflect using  /claude-reflect:reflect

## Rules
- NEVER create a file without first searching if it already exists
- NEVER implement a feature without checking for existing implementations
- ALWAYS use Serena's symbolic tools for code navigation and editing
- ALWAYS git commit after completing each task
- ALWAYS update completed-tasks.md with session details


- Use honest task status assessment (see `.claude/rules/task-status.md`)

