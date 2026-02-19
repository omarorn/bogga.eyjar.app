---
paths: "src/**/*.ts", "src/**/*.tsx"
---

# HTML Content Escaping

**Purpose:** Prevent XSS and rendering issues when embedding content in HTML.

## escapeHtml Helper

```typescript
function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
```

## When to Escape

| Context | Escape? | Example |
|---------|---------|---------|
| HTML text content | ✅ Yes | `<p>${escapeHtml(userInput)}</p>` |
| HTML attributes | ✅ Yes | `<div title="${escapeHtml(title)}">` |
| JavaScript strings in HTML | ✅ Yes | `onclick="show('${escapeJs(text)}')"` |
| JSON in script tags | ✅ Yes | Use `JSON.stringify()` |
| URL parameters | ✅ Yes | Use `encodeURIComponent()` |

## JSON Content in HTML

```typescript
// For embedding JSON data in HTML
const safeJson = JSON.stringify(data).replace(/</g, '\\u003c').replace(/>/g, '\\u003e');
```

## Never Trust User Input
Always escape before rendering, even if data comes from your own database.
