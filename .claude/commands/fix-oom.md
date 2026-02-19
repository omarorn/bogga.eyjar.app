---
description: Test all features with Serena + Playwright + multi-agent, document issues in todo.md
---

## Phase 1: Audit — Map What Exists

Use Serena's symbolic tools to understand the codebase BEFORE testing:
1. **`get_symbols_overview`** on route files — map all endpoints and pages
2. **`find_symbol`** for handlers, components, pages — build a test surface map
3. **`search_for_pattern`** for existing test files — avoid duplicating tests that already pass
4. Review `todo.md` and `completed-tasks.md` to understand what's been done vs what's pending

## Phase 1.5: Pre-Test Validation Gate

Before running any Playwright tests, ensure the codebase compiles:

1. **TypeScript**: `npm run typecheck` — tests import code, broken types = broken tests
2. **Build**: `npm run build` — confirm the app compiles
3. **Lint**: `npm run lint` — catch syntax issues before runtime
4. **Test baseline**: `npm run test` — note which tests currently pass/fail
5. **Console baseline**: note pre-existing console errors (don't re-report known issues)

**Gate rule:** If typecheck or build fails, fix compilation errors FIRST. Testing broken code wastes time.

## Phase 2: Test with Playwright + Browser MCP

Use **Playwright MCP tools** (`browser_navigate`, `browser_snapshot`, `browser_console_messages`) to systematically test:

For each page/feature:
- Navigate and verify it loads without errors
- Take accessibility snapshot (`browser_snapshot`) — check for missing elements
- Check console for errors (`browser_console_messages` with pattern filter)
- Test interactive elements (forms, buttons, navigation)
- Verify mobile responsiveness (resize to 375px width)
- Test error states and loading states

Use **multiple agents in parallel** where possible:
- **Explore agent** — scan codebase for untested paths and edge cases
- **feature-dev:code-reviewer** — review code quality of existing implementations
- **Playwright browser tools** — live testing of each route

## Phase 3: Document Issues

For each issue found:
1. Add to `todo.md` with priority tag:
   - 🔴 **Critical** — broken functionality, security issues, data loss
   - 🟡 **Important** — degraded UX, missing validation, console errors
   - 🟢 **Nice-to-have** — polish, performance, accessibility improvements
2. Include file path and line number when possible (use Serena `find_symbol` to locate)
3. Update `completed-tasks.md` with test session results

## Phase 3.5: Post-Fix Validation Gate

After each batch of fixes, verify nothing regressed:

1. **TypeScript**: `npm run typecheck` — no new errors
2. **Tests**: `npm run test` — no regressions from baseline
3. **Build**: `npm run build` — still compiles
4. **Lint**: `npm run lint` — new code follows project style
5. **Test isolation**: verify no `.only()` or `.skip()` left in test files
6. **Console check**: re-run Playwright to confirm console errors are resolved
7. **package-lock.json**: if dependencies changed, `npm install && npm ci --dry-run`

**Gate rule:** Do NOT commit fixes that break other tests or introduce new TypeScript errors.

## Phase 4: Execute Fixes with Ralph Loop

After documenting all issues, run fixes:

```
/ralph-loop "Fix all issues documented in todo.md from the /fix-oom audit" --max-iterations 30 --completion-promise "All critical and important issues from todo.md have been fixed, tested, and documented in completed-tasks.md"
```

## Testing Checklist

- [ ] All routes load without console errors
- [ ] Authentication flow works end-to-end
- [ ] Main CRUD operations (create, read, update, delete)
- [ ] Navigation between all pages
- [ ] Mobile layout (375px viewport)
- [ ] Error states handled gracefully
- [ ] Loading states present where needed
- [ ] Forms validate input correctly
- [ ] API responses match expected format
- [ ] No TypeScript errors (`/check-types`)

## Rules
- ALWAYS use Serena to find the exact file/symbol before reporting an issue
- ALWAYS check if an issue is already in todo.md before adding it
- ALWAYS git commit after each batch of fixes
- ALWAYS update completed-tasks.md with session details
