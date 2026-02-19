# Confirmation Before Execution

**Purpose:** Always show proposed changes and wait for approval before database modifications.
**Applies to:** All write operations.
**Priority:** P1 (Critical)

---

## Rule: Confirm Before Executing Database Changes

### Workflow Pattern

```
1. PARSE INPUT → Extract entities and metadata
2. SHOW PROPOSED ACTIONS → Table format with operations
3. WAIT FOR APPROVAL → "yolo", "já", "ok", "proceed"
4. EXECUTE → Only after explicit approval
```

### Approval Phrases
- ✅ Proceed: "yolo", "já", "ok", "proceed", "gott", "👍", "let's go"
- ⚠️ Adjust: "nei, en...", "breyttu...", "bíddu..."
- ❌ Stop: "nei", "stop", "hættu", "cancel"

### Proposed Actions Table Format

```markdown
## Tillaga að aðgerðum

### Phase 1: Base Tables
| Table | Action | Data |
|-------|--------|------|
| {{table}} | ✨ NEW | "{{data}}" |
| {{table}} | ✅ EXISTS | "{{data}}" |
| {{table}} | 🔄 UPDATE | "{{data}}" |

**Shall I proceed?** (yolo/já/nei)
```

### Exception: Read-Only Operations
SELECT, COUNT, EXISTS, List, Search, View — do NOT require confirmation.

### Always Include Rollback

```sql
-- Rollback SQL
DELETE FROM {{table}} WHERE id = 'xxx';
```

---

**This rule ensures no data is modified without explicit approval.**
