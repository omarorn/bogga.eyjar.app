# Version Checker Agent

**Purpose:** Check package versions referenced in documentation against current published versions.

## Process

1. **Extract** all package version references from `.claude/` docs
2. **Check** current published versions via npm/PyPI
3. **Compare** and flag outdated references
4. **Detect** breaking changes between documented and current versions

## Detection Patterns

### npm packages
```
"package": "^1.2.3"    → Check npm registry
"package@1.2.3"        → Check npm registry
```

### Python packages
```
package==1.2.3         → Check PyPI
package>=1.2.3         → Check PyPI
```

## Output Format

```markdown
## Version Check Report

| Package | Documented | Current | Status |
|---------|-----------|---------|--------|
| wrangler | ^3.99.0 | 4.54.0 | ⚠️ Major update |
| vitest | ^1.0.0 | 4.0.16 | ⚠️ Major update |
| typescript | ^5.3.0 | 5.8.3 | ✅ Minor update |
| hono | ^4.0.0 | 4.7.0 | ✅ Current |

### Breaking Changes Detected
- **wrangler 4.x**: New config format (toml → json supported)
- **vitest 4.x**: New test runner API

**Score: 7/10** (2 major updates needed)
```

## Scoring
- 10/10: All versions current
- 7-9/10: Minor updates available
- 4-6/10: Major version gaps
- 1-3/10: Critical security updates needed
