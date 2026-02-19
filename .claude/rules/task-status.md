---
paths: "tasks.md", "TODO.md", "completedtasks.md"
---

# Task Status Levels - Honest Assessment

Use accurate status levels that reflect implementation reality, not aspirational goals.

**Context**: This project discovered a 25% gap between claimed completion (97%) and quality-adjusted reality (72%). The root cause was marking tasks "complete" when only frameworks or stubs existed.

## Status Level Definitions

| Status | Symbol | Completion | Criteria |
|--------|--------|------------|----------|
| **COMPLETE** | ✅ | 100% | Fully implemented, tested, deployed, documented |
| **WORKING** | 🟢 | 80-99% | Core functionality works, minor polish needed |
| **PARTIAL** | 🟡 | 40-79% | Framework exists, significant features missing |
| **STARTED** | 🟠 | 10-39% | Basic structure, mostly stubs, many TODOs |
| **NOT STARTED** | ⚠️ | 0-9% | Interfaces only or no implementation |

## Verification Required

Before marking ✅ COMPLETE, verify ALL of:
- [ ] Implementation has no TODO comments
- [ ] File is >50% implementation (not just interfaces)
- [ ] Feature works in production
- [ ] Documentation reflects actual state
- [ ] Tests exist (if applicable)

## Corrections

| If Claude suggests... | Use instead... | Why |
|----------------------|----------------|-----|
| ✅ COMPLETE (when file exists with TODOs) | 🟠 STARTED (20%) | TODOs indicate incomplete work |
| ✅ COMPLETE (when only interfaces exist) | ⚠️ NOT STARTED (5%) | Interfaces ≠ implementation |
| ✅ COMPLETE (framework only, missing logic) | 🟡 PARTIAL (50%) | Framework alone is half the work |
| ✅ COMPLETE (works but no tests) | 🟢 WORKING (90%) | Tests are part of "complete" |

## Examples from This Project

**Bad (Inflated)**:
```markdown
- ✅ Task 5.2 - Facebook Archive Parser (COMPLETE)
```
**Reality**: 36 lines of interfaces only = 20% STARTED

**Good (Honest)**:
```markdown
- 🟠 Task 5.2 - Facebook Archive Parser (STARTED - 20%)
  - **Working**: Interface definitions, stub functions, file structure
  - **Missing**: JSON parsing, post extraction, error handling, tests
  - **Estimated remaining**: 4 hours
```

## Task Update Template

When updating task status, include:
```markdown
- [STATUS] Task X.Y - [Name] ([Percentage]%)
  - **Working**: [What actually works]
  - **Missing**: [What's incomplete]
  - **Estimated remaining**: [Hours]
  - **Last updated**: [Date]
  - **Verification**: [How to test/verify]
```

## Impact of Honest Status

**Before (Inflated)**:
- Claimed: 97% complete (31/32 tasks)
- Planning based on false data
- Surprises during "final" tasks

**After (Honest)**:
- Actual: 72% quality-adjusted
- Realistic roadmap (87 hours remaining)
- No surprises, better estimates

## When to Use Each Level

### ✅ COMPLETE (100%)
- All acceptance criteria met
- No TODOs in implementation
- Tests pass (if applicable)
- Deployed and verified
- Documentation accurate

### 🟢 WORKING (80-99%)
- Core feature functional
- Minor edge cases remain
- May need polish or tests
- Works in production

### 🟡 PARTIAL (40-79%)
- Framework/structure exists
- Some logic implemented
- Significant features missing
- Requires substantial work

### 🟠 STARTED (10-39%)
- Basic structure created
- Mostly stubs or TODOs
- Interfaces defined
- Minimal logic

### ⚠️ NOT STARTED (0-9%)
- Interfaces only
- Placeholder functions
- No real implementation
- Just planning/specs
