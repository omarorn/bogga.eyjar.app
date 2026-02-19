---
paths: "apps/**/*.tsx", "**/*.css", "src/**/*.tsx"
---

# Mobile Touch Target Sizing

All interactive elements must have minimum 44px touch targets for mobile usability.

## Touch Target Requirements

| Element Type | Minimum Size | Recommended Implementation |
|--------------|--------------|---------------------------|
| Buttons | 44px height | `min-height: 44px` or `h-11` (44px) |
| Links | 44px height | `min-h-11 py-2` |
| Input fields | 44px height | `h-11` or `py-3` |
| Icons (clickable) | 44px × 44px | `p-2` on 32px icon, or `p-3` on 24px icon |
| Checkboxes/Radio | 44px × 44px | Larger hit area around actual input |

## Tailwind Class Patterns

```tsx
// ✅ CORRECT: Proper touch targets
<Button className="h-11 px-4">Submit</Button>          // 44px height
<a className="min-h-11 inline-flex items-center">Link</a>
<input className="h-11 px-3" />
<button className="p-3">                               // 24px icon + 12px padding = 48px
  <Icon className="h-6 w-6" />
</button>
```

## Anti-Patterns to Avoid

```tsx
// ❌ WRONG: Touch targets too small
<Button className="h-8 px-2">Submit</Button>           // Only 32px
<a className="py-1">Link</a>                           // Too small
<button className="p-1">                               // Icon + 4px padding = 28px
  <Icon className="h-5 w-5" />
</button>
```

## Mobile-Specific CSS

```css
/* Mobile touch target enforcement */
@media (max-width: 768px) {
  button,
  a,
  input,
  select,
  textarea,
  [role="button"] {
    min-height: 44px;
    min-width: 44px; /* For icon-only buttons */
  }

  /* Icon buttons need padding */
  button:has(svg:only-child) {
    padding: 0.75rem; /* 12px padding around icon */
  }
}
```

## Accessibility Benefits

- **WCAG 2.1 Level AAA**: Meets success criterion 2.5.5 (Target Size)
- **Mobile usability**: Prevents mis-taps on small screens
- **Touch screen friendly**: Works well on phones and tablets
- **Inclusive design**: Helps users with motor impairments

## Testing Checklist

- [ ] All buttons 44px minimum height
- [ ] All links 44px minimum height (when standalone)
- [ ] All input fields 44px minimum height
- [ ] Icon-only buttons have adequate padding (44px × 44px total)
- [ ] Table action buttons properly sized on mobile
- [ ] Modal close buttons meet size requirements

## Context

This project targets mobile users (drivers, field workers) as primary users. All interactive elements must meet minimum touch target sizes to ensure usability on mobile devices.

## Related Guidelines

- **Apple HIG**: Recommends 44pt minimum
- **Material Design**: Recommends 48dp minimum
- **WCAG 2.1**: Requires 44 × 44 CSS pixels (Level AAA)
- **This project**: Follows 44px standard (matches WCAG, close to Apple/Material)
