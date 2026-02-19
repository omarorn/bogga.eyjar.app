---
paths: "apps/litla-admin/**/*.tsx", "src/components/**/*.tsx"
---

# Button Component Limitations

The Button component in this project does not support polymorphic `as` prop for changing the rendered element.

## Polymorphic Pattern Limitation

| If Claude suggests... | Use instead... |
|----------------------|----------------|
| `<Button as="label">` | `<span className="button-styles">` |
| `<Button as="a">` | `<a className="button-styles">` |
| Polymorphic Button | Style native elements to match Button |

## File Upload Label Pattern

```typescript
// ✅ CORRECT: Style span to match Button
<span className={cn(
  "inline-flex items-center justify-center rounded-md text-sm font-medium",
  "ring-offset-background transition-colors",
  "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
  "bg-primary text-primary-foreground hover:bg-primary/90",
  "h-10 px-4 py-2 cursor-pointer"
)}>
  <Upload className="mr-2 h-4 w-4" />
  Upload CSV
  <input
    type="file"
    accept=".csv"
    onChange={handleFileUpload}
    className="hidden"
  />
</span>
```

## Anti-Pattern to Avoid

```typescript
// ❌ WRONG: Button doesn't support 'as' prop
<Button as="label" htmlFor="file-upload">
  Upload CSV
  <input id="file-upload" type="file" className="hidden" />
</Button>
```

## Alternative Approaches

**Option 1: Styled native element** (recommended for semantic HTML)
```tsx
<label className={buttonVariants({ variant: "default" })}>
  Upload
  <input type="file" className="hidden" />
</label>
```

**Option 2: Button with hidden input + click handler**
```tsx
<>
  <Button onClick={() => fileInputRef.current?.click()}>
    Upload CSV
  </Button>
  <input
    ref={fileInputRef}
    type="file"
    className="hidden"
    onChange={handleFileUpload}
  />
</>
```

## Context

This project's Button component (likely from shadcn/ui) is not polymorphic. When you need button styling on non-button elements (labels, links, spans), either:
1. Use the native element with button classes
2. Use Button with hidden input pattern
3. Extract `buttonVariants` and apply to any element
