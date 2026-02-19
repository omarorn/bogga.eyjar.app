---
paths: "src/**/*.ts", "src/**/*.tsx"
---

# Icelandic Character Escaping in onclick Attributes

**Purpose:** Handle Icelandic special characters (á, ð, é, í, ó, ú, ý, þ, æ, ö) in JavaScript string literals inside HTML attributes.

## The Problem

```html
<!-- BROKEN: Icelandic chars break the string -->
<button onclick="show('Jón's story about þjóðlíf')">Click</button>
```

## Solution: Manual Escaping

```typescript
function escapeForOnclick(str: string): string {
  return str
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'")
    .replace(/"/g, '&quot;')
    .replace(/\n/g, '\\n');
}

// Usage
const title = "Jón's story about þjóðlíf";
const html = `<button onclick="show('${escapeForOnclick(title)}')">${escapeHtml(title)}</button>`;
```

## Better Alternative: Data Attributes

```html
<button data-title="Jón&#039;s story" onclick="show(this.dataset.title)">Click</button>
```

## Best: Event Listeners (no inline JS)

```typescript
element.addEventListener('click', () => show(title));
```
