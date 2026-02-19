---
name: phase-next
description: Move to next development phase
command: /phase-next
---

# Move to Next Phase

Update SESSION.md and move to the next development phase.

## Steps

1. Read current `SESSION.md` to determine current phase
2. Mark current phase as COMPLETE
3. Move to next phase
4. Update `SESSION.md` with:
   - Current phase name and status
   - Next action to take
   - Phase completion date
5. Display next phase summary

## SESSION.md Format

```markdown
# Session State

## Current Phase
**Phase:** {{PHASE_NAME}}
**Status:** IN PROGRESS
**Started:** {{DATE}}

## Completed Phases
- [x] Phase 1: {{name}} ({{date}})
- [x] Phase 2: {{name}} ({{date}})
- [ ] Phase 3: {{name}} ← CURRENT

## Next Action
{{NEXT_ACTION_DESCRIPTION}}

## Known Issues
- {{issue_1}}
- {{issue_2}}
```
