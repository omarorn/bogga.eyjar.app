# LSP Integration for Claude Code Workflows

**Purpose:** Leverage language server features (via Serena + TypeScript LSP) for intelligent code analysis
**Applies to:** All commands and skills that modify or analyze code
**Priority:** P2 (Best Practice)

---

## When to Use LSP Tools

### Before Writing Code
| Tool | Use Case | Command |
|------|----------|---------|
| `get_symbols_overview` | Understand file structure before editing | `get_symbols_overview(relative_path, depth=1)` |
| `find_symbol` + `include_info` | Check type signatures before modifying | `find_symbol(name, include_info=true)` |
| `find_referencing_symbols` | Map all callers before changing a function | `find_referencing_symbols(name, relative_path)` |
| `search_for_pattern` | Find existing implementations before creating | `search_for_pattern("functionName")` |

### After Writing Code
| Tool | Use Case | Command |
|------|----------|---------|
| `find_symbol` + `include_body` | Verify the edit looks correct | `find_symbol(name, include_body=true)` |
| `find_referencing_symbols` | Confirm callers still work | `find_referencing_symbols(name, relative_path)` |
| `npm run typecheck` | TypeScript compilation check | Shell command |
| `npm run build` | Full build verification | Shell command |

---

## Break Analysis Pattern

Before modifying any exported symbol:

1. **Find all callers:**
   ```
   find_referencing_symbols("functionName", "src/routes/handler.ts")
   ```

2. **Check each caller's usage:** Is the call compatible with your change?

3. **If breaking change needed:** Update all callers in the same commit

4. **Verify after change:**
   ```bash
   npm run typecheck  # Catches type mismatches at call sites
   npm run test       # Catches runtime failures
   ```

---

## Type Contract Verification

When modifying interfaces or function signatures:

1. **Read current contract:**
   ```
   find_symbol("MyInterface", include_info=true)
   ```

2. **Find all implementations:**
   ```
   search_for_pattern("implements MyInterface")
   ```

3. **Find all usages:**
   ```
   find_referencing_symbols("MyInterface", "src/types/index.ts")
   ```

4. **Make the change** ensuring backward compatibility or updating all sites

---

## Dead Code Detection

Use `find_referencing_symbols` to identify unused exports:

```
find_referencing_symbols("exportedFunction", "src/utils/helper.ts")
```

- **0 references** = likely dead code (safe to remove)
- **1+ references** = still in use (do not remove)

---

## Import Health Check

After refactoring (moving/renaming files):

1. Run `npm run typecheck` — catches `Cannot find module` errors
2. Run `npm run test` — catches runtime import failures
3. Use `find_symbol` on moved symbols — confirm they're reachable from new location
4. Check barrel exports (`index.ts`) are updated

---

**This rule ensures LSP tools are used systematically in all code modification workflows.**
