---
name: verify-phase
description: Verify current phase completion
command: /verify-phase
---

# Verify Phase Completion

Check all exit criteria for the current phase.

## Steps

1. Read `SESSION.md` for current phase and exit criteria
2. Run automated checks:
   - TypeScript: `npm run typecheck`
   - Tests: `npm run test`
   - Lint: `npm run lint` (if configured)
   - Build: `npm run build`
3. Check manual criteria from phase plan
4. Report results:

```
## Phase Verification: {{PHASE_NAME}}

### Automated Checks
| Check | Status | Details |
|-------|--------|---------|
| TypeScript | ✅ | No new errors |
| Tests | ✅ | 45/45 passed |
| Lint | ✅ | 0 warnings |
| Build | ✅ | Success |

### Manual Criteria
| Criterion | Status |
|-----------|--------|
| {{criterion_1}} | ✅ |
| {{criterion_2}} | ⚠️ Partial |

### Result
**Phase {{PHASE_NAME}}: READY TO ADVANCE** ✅
(or: **BLOCKING ISSUES FOUND** - fix before advancing)
```

5. If all pass: suggest running `/phase-next`
6. If blocking: list what needs fixing
