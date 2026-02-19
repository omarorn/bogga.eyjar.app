---
paths: "**/*.astro"
---

# Astro Import Paths

Astro processes imports from the `src/` directory. Use `/src/` prefix for stylesheet and asset imports, not public directory paths.

## Corrections

| If Claude suggests... | Use instead... |
|----------------------|----------------|
| `<link rel="stylesheet" href="/styles/file.css">` | `<link rel="stylesheet" href="/src/styles/file.css">` |
| `<link rel="stylesheet" href="./styles/file.css">` | `<link rel="stylesheet" href="/src/styles/file.css">` |
| `<script src="/scripts/file.js">` | `<script src="/src/scripts/file.js">` |

## Pattern

**Astro import resolution:**
- `/src/*` → Processed by Astro build system
- `/public/*` → Served statically (no processing)
- `/*` without src/ → Looks in public/ directory

**Use `/src/` for:**
- Stylesheets that need processing
- TypeScript/JavaScript modules
- Components and layouts
- Any build-time assets

**Use `/public/` (or just `/`) for:**
- Static images served as-is
- Favicon files
- robots.txt, sitemap.xml
- Pre-built third-party assets

## Examples

**Correct:**
```astro
<link rel="stylesheet" href="/src/styles/global.css">
<script src="/src/scripts/analytics.ts"></script>
```

**Incorrect:**
```astro
<link rel="stylesheet" href="/styles/global.css">  <!-- Won't be processed -->
<script src="/scripts/analytics.ts"></script>       <!-- Won't be found -->
```

## Context

Discovered when extracting CSS to separate file - using `/styles/` path failed because Astro expected `/src/styles/` for processed assets.
