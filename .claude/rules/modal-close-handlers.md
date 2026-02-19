---
paths: "apps/**/*Modal.tsx", "apps/**/*Dialog.tsx", "src/components/modals/**"
---

# Modal Close Handler Optional Chaining

Modal components must use optional chaining for `onClose` handlers to support usage without close handlers.

## Optional Chaining Pattern

| If Claude suggests... | Use instead... |
|----------------------|----------------|
| `onClose()` | `onClose?.()` |
| `onClick={onClose}` | `onClick={() => onClose?.()}` |
| Assume onClose exists | Handle optional onClose prop |

## Recommended Pattern

```typescript
// ✅ CORRECT: Optional chaining for onClose
interface ModalProps {
  isOpen: boolean;
  onClose?: () => void;  // Optional prop
  children: React.ReactNode;
}

export function Modal({ isOpen, onClose, children }: ModalProps) {
  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent>
        {children}
        <button onClick={() => onClose?.()}>
          Close
        </button>
      </DialogContent>
    </Dialog>
  );
}
```

## Usage Flexibility

```typescript
// With close handler
<Modal isOpen={true} onClose={() => setIsOpen(false)}>
  Content
</Modal>

// Without close handler (always-open modal, or controlled externally)
<Modal isOpen={true}>
  Content
</Modal>

// Conditional close
<Modal
  isOpen={true}
  onClose={canClose ? handleClose : undefined}
>
  Content
</Modal>
```

## Sidebar/Panel Pattern

```typescript
// Sidebars might not need onClose (controlled by parent button)
interface SidebarProps {
  isOpen: boolean;
  onClose?: () => void;  // Optional - parent controls via button
}

export function Sidebar({ isOpen, onClose }: SidebarProps) {
  return (
    <div className={isOpen ? 'translate-x-0' : '-translate-x-full'}>
      {onClose && (  // Only render close button if handler provided
        <button onClick={onClose}>
          <X />
        </button>
      )}
      {/* Sidebar content */}
    </div>
  );
}
```

## Benefits

- **Reusability**: Modal works in controlled and uncontrolled modes
- **Flexibility**: Can be used without close button if needed
- **Error prevention**: Won't crash if onClose not provided
- **TypeScript safety**: Optional prop type matches usage

## Anti-Pattern to Avoid

```typescript
// ❌ WRONG: Will crash if onClose not provided
<button onClick={onClose}>Close</button>

// ❌ WRONG: Assumes onClose always exists
interface ModalProps {
  onClose: () => void;  // Required - limits reusability
}
```

## Context

This project uses modals in various contexts (confirmations, forms, notifications). Some modals need to be controlled entirely by parent state without providing a close handler. Optional chaining allows modals to be reusable across these scenarios.

## Related Components

- Sidebar navigation (mobile) - close via hamburger menu, not sidebar itself
- Confirmation dialogs - might be force-acknowledged without close button
- Loading modals - no close until operation completes
