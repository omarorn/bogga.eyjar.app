---
paths: "src/components/**", "src/pages/**"
---

# Form Component ID Override Pattern

**Purpose:** Ensure form component IDs match what JavaScript expects.

## The Problem

Form generation functions often create IDs with a prefix:
```typescript
// generateInput creates id="input-email"
generateInput({ name: 'email', type: 'text' })
```

But JavaScript may expect just the name:
```typescript
// Expects id="email", gets id="input-email"
document.getElementById('email') // null!
```

## Solution: Explicit ID Override

```typescript
generateInput({
  name: 'email',
  type: 'text',
  id: 'email'  // Explicit ID override
})
```

## Rule
When JavaScript code references form elements by ID, always pass an explicit `id` option to the form generator that matches exactly what JavaScript expects.
