---
description: Document completed agent/session deliverables with Serena verification
---

## Phase 1: Gather Deliverables

Use Serena to verify what was actually created/modified (don't trust summaries alone):

1. **`search_for_pattern`** — find files modified in recent commits:
   ```bash
   git diff --name-only HEAD~5
   ```
2. **`get_symbols_overview`** on each modified file — count symbols, understand scope
3. **`find_symbol`** with `include_body=true` on key additions — verify implementation quality
4. Check git log for commit messages and session context

## Phase 2: Count & Categorize

**Files Created ([N] files):**
| # | File | Description | Lines |
|---|------|-------------|-------|
| 1 | `path/to/file.ts` | Brief description | ~N |

**Files Updated ([N] files):**
| # | File | Changes | Impact |
|---|------|---------|--------|
| 1 | `path/to/file.ts` | What changed | High/Med/Low |

**Key Features Implemented:**
- Feature 1: Brief description + file path
- Feature 2: Brief description + file path

**Issues Fixed:**
- Error category: What was fixed (N files affected)

**Dependencies Added:**
```bash
npm install package1 package2
```

## Phase 3: Quality Validation Gates

Run ALL gates before documenting deliverables as complete:

### Automated Gates (must all pass)
1. **TypeScript**: `npm run typecheck` — no new errors above baseline
2. **Lint**: `npm run lint` — new code follows project style
3. **Tests**: `npm run test` — existing + new tests pass
4. **Build**: `npm run build` — compiles successfully

### Serena Verification
5. **Import check**: `find_symbol` on new exports — confirm they're reachable
6. **Break analysis**: `find_referencing_symbols` on modified symbols — no callers broken
7. **Barrel exports**: if new files added, verify `index.ts` is updated
8. **Type contracts**: `find_symbol` with `include_info=true` on public APIs — signatures correct

### Agent Review
9. **feature-dev:code-reviewer** — review new/modified code for bugs and quality
10. **Pattern compliance** — naming conventions, API response format, security patterns

### Dependency Gates (if applicable)
11. **package-lock.json**: `npm ci --dry-run` if deps changed
12. **CSS build**: `npm run build:css` if styles changed
13. **Migration order**: DB migrations applied before code deploy

**Quality Grade:**
- ✅ PRODUCTION READY — all gates pass, tests pass, no breaking changes
- 🟢 WORKING — gates pass, minor non-blocking issues documented
- 🟡 NEEDS WORK — one or more gates fail, document what and why

## Phase 4: Write Summary to completed-tasks.md

Append to `completed-tasks.md`:

```markdown
## [Date] — [Phase/Task Name] ✅ COMPLETE
- **Session:** [Claude session ID]
- **Duration:** [Estimated] → [Actual] (agent time)
- **Tokens:** [approximate token count]

### Deliverables
- ✅ [Deliverable 1] — `path/to/file.ts`
- ✅ [Deliverable 2] — `path/to/file.ts`

### Files Created ([N])
[list with descriptions]

### Files Updated ([N])
[list with changes]

### Quality
- TypeScript: ✅ No errors
- Tests: ✅/⚠️ [status]
- Code Review: ✅/⚠️ [status]

### Learnings
- [Key takeaway 1]
- [Key takeaway 2]
```

## Phase 5: Update Tracking

- Update `todo.md` — mark completed tasks
- Update `tasks.md` — update phase status
- Update `SESSION.md` — current phase and next action
- Git commit with descriptive message
- Run `/reflect` to capture learnings

## Rules
- ALWAYS verify deliverables with Serena — don't trust summaries alone
- ALWAYS include file paths and line counts
- ALWAYS note the Claude session ID
- ALWAYS update completed-tasks.md before marking done
- ALWAYS git commit the documentation
