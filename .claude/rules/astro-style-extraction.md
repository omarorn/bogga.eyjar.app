---
paths: "**/*.astro"
---

# Astro Style Tag Extraction

When Astro files contain large CSS blocks (>300 lines), extract them to separate stylesheet files for better maintainability and reusability.

## Pattern

| If Claude suggests... | Use instead... |
|----------------------|----------------|
| Keeping large CSS inline in `<style>` tags | Extract to separate `.css` file in `src/styles/` |
| Multiple `<style>` blocks in one Astro file | Consolidate and extract to single stylesheet |

## Implementation

**Before (inline styles):**
```astro
---
// frontmatter
---

<head>
    <style>
        /* 500+ lines of CSS */
    </style>
</head>
```

**After (extracted styles):**
```astro
---
// frontmatter
---

<head>
    <link rel="stylesheet" href="/src/styles/page-name.css">
</head>
```

Create `src/styles/page-name.css`:
```css
/* All extracted styles */
```

## Benefits

- **Maintainability**: CSS can be edited independently
- **Reusability**: Styles can be shared across multiple pages
- **File size**: Astro files become 50-70% smaller
- **Tooling**: Better CSS editor support (linting, formatting, autocomplete)

## Threshold

Extract when:
- `<style>` block exceeds ~300 lines
- CSS represents >50% of file content
- Styles could be reused on other pages
- File becomes difficult to navigate

## Context

Discovered during refactoring session where index.astro had 791 lines of CSS (63% of file). Extraction reduced file from 1,256 to 467 lines.
