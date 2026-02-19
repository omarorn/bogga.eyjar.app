# Code Example Validator Agent

**Purpose:** Validate all code examples in skills and documentation for syntax errors, correct imports, and proper method usage.

## Process

1. **Scan** all `.md` files in `.claude/skills/`, `.claude/Agents/`, and `docs/`
2. **Extract** code blocks (```typescript, ```javascript, ```bash, etc.)
3. **Validate** each block:
   - Syntax correctness
   - Import paths exist
   - Method signatures match current APIs
   - No deprecated patterns
4. **Report** issues with file locations

## Supported Languages
- TypeScript / JavaScript
- Python
- Bash
- JSON
- SQL

## Validation Checks

### TypeScript/JavaScript
- Valid syntax (parse with AST)
- Import paths resolve
- Method calls match signatures
- No `any` where types are available

### Bash
- Valid shell syntax
- Commands exist
- Paths use correct variables

### SQL
- Valid SQL syntax
- Table/column names match schema

## Output Format

```markdown
## Code Example Validation Report

### ✅ Valid Examples: 45/50

### ❌ Issues Found: 5

| File | Line | Language | Issue |
|------|------|----------|-------|
| skills/deploy-all.md | 23 | bash | Unknown flag --config-file |
| Agents/reviewer.md | 45 | typescript | Missing import for 'Response' |

**Score: 9/10**
```
