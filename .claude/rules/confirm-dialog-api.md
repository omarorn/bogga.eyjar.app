---
paths: "apps/litla-admin/**/*.tsx", "**/*Modal.tsx", "**/*Dialog.tsx"
---

# ConfirmDialog Component API

The ConfirmDialog component in this project uses `description` prop, not `message`.

## Prop Name Correction

| If Claude suggests... | Use instead... |
|----------------------|----------------|
| `<ConfirmDialog message="..." />` | `<ConfirmDialog description="..." />` |
| `message` prop | `description` prop |

## Recommended Pattern

```typescript
// ✅ CORRECT: Use description prop
<ConfirmDialog
  open={showConfirm}
  onOpenChange={setShowConfirm}
  title="Confirm Delete"
  description="Are you sure you want to delete this user? This action cannot be undone."
  onConfirm={handleDelete}
  confirmText="Delete"
  cancelText="Cancel"
/>
```

## Anti-Pattern to Avoid

```typescript
// ❌ WRONG: message prop doesn't exist
<ConfirmDialog
  message="Are you sure?"  // TypeScript error
  onConfirm={handleDelete}
/>
```

## Context

This project's ConfirmDialog component (likely from shadcn/ui or custom implementation) uses `description` instead of the more common `message` prop name. Always use `description` for the dialog body text.

## Related Components

This pattern applies to:
- `ConfirmDialog` in user management modals
- `ConfirmDialog` in fleet assignment modals
- `ConfirmDialog` in container assignment modals
