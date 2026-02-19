---
description: Deep reflection on project state — what works, what's missing, what could be better
---

## Phase 1: Gather Evidence with Serena

Do NOT rely on memory or assumptions. Use symbolic tools to get the actual state:

1. **`get_symbols_overview`** on key files — map what's actually implemented (not just planned)
2. **`search_for_pattern`** for TODO/FIXME/HACK comments — find hidden debt
3. **`find_symbol`** with `include_body=true` on critical paths — verify implementation quality
4. Read `completed-tasks.md` — understand what's been done and when
5. Read `todo.md` / `tasks.md` — understand what's planned vs pending
6. Read `SESSION.md` — understand current phase and blockers

## Phase 1.5: Measure — LSP & Validation Metrics

Collect hard numbers BEFORE making any judgments:

1. **TypeScript errors**: `npm run typecheck 2>&1 | tail -5` — exact error count
2. **TODO/FIXME/HACK count**: `search_for_pattern` with pattern `TODO|FIXME|HACK` — hidden debt indicator
3. **Test pass rate**: `npm run test` — actual functionality proof
4. **Lint violations**: `npm run lint 2>&1 | tail -5` — code quality metric
5. **Build status**: `npm run build` — does it even compile?
6. **Unused symbols**: use `find_referencing_symbols` on exported symbols — find dead code
7. **Import health**: check for `Cannot find module` errors in typecheck output

Use these metrics to calibrate honest status levels — e.g., "Feature marked ✅ COMPLETE but has 3 TypeScript errors" is actually 🟡 PARTIAL.

## Phase 2: Cross-Reference Promises vs Reality

Use **multiple agents** to audit in parallel:
- **Explore agent** — scan for dead code, unused exports, orphaned files
- **feature-dev:code-reviewer** — review code quality with confidence-based filtering
- **feature-dev:code-explorer** — trace execution paths of critical features

For each promised feature (from PRD, CLAUDE.md, README, or original spec):
1. **Does it exist?** — search with Serena
2. **Does it work?** — trace the execution path
3. **Is it complete?** — check for stubs, TODOs, partial implementations
4. Apply honest status assessment (see `.claude/rules/task-status.md`):
   - ✅ COMPLETE (100%) — fully implemented, tested, verified
   - 🟢 WORKING (80-99%) — core works, minor polish needed
   - 🟡 PARTIAL (40-79%) — framework exists, significant features missing
   - 🟠 STARTED (10-39%) — basic structure, mostly stubs
   - ⚠️ NOT STARTED (0-9%) — interfaces only, no implementation

## Phase 3: Critic's Report

Produce a structured assessment:

### What Works Well
- List features that are genuinely complete and solid
- Highlight good patterns, clean code, well-tested areas

### What's Missing
- Features promised but not implemented
- Tests that should exist but don't
- Documentation gaps
- MCP/plugin integrations not yet connected

### What Could Be Better
- Code quality issues (without being pedantic)
- Architecture concerns
- Performance bottlenecks
- Security gaps
- UX/accessibility issues

### Honest Status Summary
```markdown
| Feature | Promised | Actual Status | Gap |
|---------|----------|---------------|-----|
| [Feature] | ✅ | 🟡 PARTIAL (60%) | [What's missing] |
```

### Recommended Priority
1. 🔴 Fix now — blocking or broken
2. 🟡 Fix soon — degraded experience
3. 🟢 Fix later — polish and optimization

## Phase 4: Update Tracking

- Add findings to `todo.md` with priorities
- Update `completed-tasks.md` with reflection session details
- Run `/reflect` to capture learnings
- Git commit the reflection report

## Rules
- NEVER inflate status — use honest assessment levels
- ALWAYS verify with Serena before claiming something works or doesn't
- ALWAYS include file paths and evidence for each finding
- ALWAYS note the Claude session ID in completed-tasks.md
