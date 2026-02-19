# UI Component Pattern Template

**Purpose:** Standardize UI component implementation for consistent, accessible, dark-mode-ready interfaces
**Applies to:** Files matching `**/components/**/*.ts`, `**/ui/**/*.ts`
**Priority:** P2 (Configuration)
**Created:** January 2025
**Author:** 2076 ehf

---

## Rule: All UI Components Must Follow Standard Factory Pattern

### Component Factory Structure

```typescript
// ✅ GOOD: Standard component factory
export interface ComponentOptions {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  className?: string;
  // Component-specific options
}

export function generateComponent(
  content: string,
  options: ComponentOptions = {}
): string {
  const {
    variant = 'primary',
    size = 'md',
    disabled = false,
    className = ''
  } = options;
  
  const baseClasses = getBaseClasses();
  const variantClasses = getVariantClasses(variant);
  const sizeClasses = getSizeClasses(size);
  const stateClasses = disabled ? 'opacity-50 cursor-not-allowed' : '';
  
  return `
    <div class="${baseClasses} ${variantClasses} ${sizeClasses} ${stateClasses} ${className}">
      ${content}
    </div>
  `;
}
```

---

## Button Component Pattern

```typescript
// components/button.ts

export interface ButtonOptions {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  type?: 'button' | 'submit' | 'reset';
  onclick?: string;
  className?: string;
  ariaLabel?: string;
}

export function generateButton(
  content: string,
  options: ButtonOptions = {}
): string {
  const {
    variant = 'primary',
    size = 'md',
    disabled = false,
    type = 'button',
    onclick,
    className = '',
    ariaLabel
  } = options;

  // Base classes - always applied
  const base = [
    'inline-flex items-center justify-center',
    'font-medium rounded-lg',
    'transition-all duration-200',
    'focus:outline-none focus:ring-2 focus:ring-offset-2',
    'disabled:opacity-50 disabled:cursor-not-allowed'
  ].join(' ');

  // Variant classes - light and dark mode
  const variants: Record<string, string> = {
    primary: [
      'bg-blue-600 text-white',
      'hover:bg-blue-700',
      'focus:ring-blue-500',
      'dark:bg-blue-500 dark:hover:bg-blue-600'
    ].join(' '),
    secondary: [
      'bg-gray-200 text-gray-900',
      'hover:bg-gray-300',
      'focus:ring-gray-500',
      'dark:bg-gray-700 dark:text-gray-100 dark:hover:bg-gray-600'
    ].join(' '),
    ghost: [
      'bg-transparent text-gray-700',
      'hover:bg-gray-100',
      'focus:ring-gray-500',
      'dark:text-gray-300 dark:hover:bg-gray-800'
    ].join(' '),
    danger: [
      'bg-red-600 text-white',
      'hover:bg-red-700',
      'focus:ring-red-500',
      'dark:bg-red-500 dark:hover:bg-red-600'
    ].join(' ')
  };

  // Size classes - including min touch target (44px)
  const sizes: Record<string, string> = {
    sm: 'px-3 py-1.5 text-sm min-h-[36px]',
    md: 'px-4 py-2 text-base min-h-[44px]',
    lg: 'px-6 py-3 text-lg min-h-[52px]'
  };

  const classes = [
    base,
    variants[variant],
    sizes[size],
    className
  ].filter(Boolean).join(' ');

  const attrs = [
    `type="${type}"`,
    disabled ? 'disabled' : '',
    onclick ? `onclick="${onclick}"` : '',
    ariaLabel ? `aria-label="${ariaLabel}"` : ''
  ].filter(Boolean).join(' ');

  return `<button class="${classes}" ${attrs}>${content}</button>`;
}

// CSS to inject (for dynamic rendering)
export function getButtonCSS(): string {
  return `
    /* Button focus ring offset for dark mode */
    .dark button:focus {
      --tw-ring-offset-color: #1f2937;
    }
  `;
}
```

---

## Card Component Pattern

```typescript
// components/card.ts

export interface CardOptions {
  variant?: 'default' | 'elevated' | 'outlined' | 'interactive';
  padding?: 'none' | 'sm' | 'md' | 'lg';
  clickable?: boolean;
  onclick?: string;
  className?: string;
}

export function generateCard(
  content: string,
  options: CardOptions = {}
): string {
  const {
    variant = 'default',
    padding = 'md',
    clickable = false,
    onclick,
    className = ''
  } = options;

  const base = 'rounded-xl overflow-hidden';

  const variants: Record<string, string> = {
    default: [
      'bg-white dark:bg-gray-800',
      'border border-gray-200 dark:border-gray-700'
    ].join(' '),
    elevated: [
      'bg-white dark:bg-gray-800',
      'shadow-lg dark:shadow-gray-900/50'
    ].join(' '),
    outlined: [
      'bg-transparent',
      'border-2 border-gray-300 dark:border-gray-600'
    ].join(' '),
    interactive: [
      'bg-white dark:bg-gray-800',
      'shadow-md hover:shadow-lg',
      'transform hover:-translate-y-1',
      'transition-all duration-200',
      'cursor-pointer'
    ].join(' ')
  };

  const paddings: Record<string, string> = {
    none: '',
    sm: 'p-3',
    md: 'p-4 md:p-6',
    lg: 'p-6 md:p-8'
  };

  const clickableClasses = clickable ? [
    'cursor-pointer',
    'hover:shadow-lg',
    'transition-shadow duration-200'
  ].join(' ') : '';

  const tag = clickable || onclick ? 'button' : 'div';
  const clickAttr = onclick ? `onclick="${onclick}"` : '';

  return `
    <${tag} 
      class="${base} ${variants[variant]} ${paddings[padding]} ${clickableClasses} ${className}"
      ${clickAttr}
    >
      ${content}
    </${tag}>
  `;
}
```

---

## Dark Mode Requirements

### Always Include Both Modes

```typescript
// ✅ GOOD: Both light and dark classes
const classes = 'bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100';

// ❌ BAD: Missing dark mode
const classes = 'bg-white text-gray-900';
```

### Color Mapping Reference

| Light Mode | Dark Mode | Usage |
|------------|-----------|-------|
| `bg-white` | `dark:bg-gray-800` | Card backgrounds |
| `bg-gray-50` | `dark:bg-gray-900` | Page backgrounds |
| `bg-gray-100` | `dark:bg-gray-700` | Hover states |
| `text-gray-900` | `dark:text-gray-100` | Primary text |
| `text-gray-600` | `dark:text-gray-400` | Secondary text |
| `border-gray-200` | `dark:border-gray-700` | Borders |

---

## Accessibility Requirements

### Minimum Touch Target

```typescript
// ✅ GOOD: 44px minimum touch target
const button = 'min-h-[44px] min-w-[44px] p-2';

// ❌ BAD: Too small for touch
const button = 'p-1 text-sm';
```

### Focus States

```typescript
// ✅ GOOD: Visible focus ring
const focusClasses = [
  'focus:outline-none',
  'focus:ring-2',
  'focus:ring-blue-500',
  'focus:ring-offset-2',
  'dark:focus:ring-offset-gray-800'
].join(' ');
```

### ARIA Labels

```typescript
// ✅ GOOD: Icon button with label
generateButton('🔍', { ariaLabel: 'Search' });

// ❌ BAD: Icon button without accessible name
generateButton('🔍');
```

---

## Component Library Integration

### Export Pattern

```typescript
// components/index.ts
export { generateButton, getButtonCSS, type ButtonOptions } from './button';
export { generateCard, type CardOptions } from './card';
export { generateModal, type ModalOptions } from './modal';

// Convenience function to get all CSS
export function getAllComponentCSS(): string {
  return [
    getButtonCSS(),
    getCardCSS(),
    getModalCSS()
  ].join('\n');
}
```

### Usage in Pages

```typescript
import { generateButton, generateCard, getAllComponentCSS } from '../components';

export function renderPage(): string {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <style>${getAllComponentCSS()}</style>
    </head>
    <body>
      ${generateCard(`
        <h2>Title</h2>
        <p>Content here</p>
        ${generateButton('Click Me', { variant: 'primary' })}
      `, { variant: 'elevated' })}
    </body>
    </html>
  `;
}
```

---

## Verification Checklist

- [ ] Component has light AND dark mode classes
- [ ] Touch targets are minimum 44px
- [ ] Focus states are visible
- [ ] Icon-only elements have aria-label
- [ ] Component follows factory pattern
- [ ] CSS is exportable for injection

---

## References

- **Tailwind CSS:** https://tailwindcss.com/docs
- **WCAG Touch Target:** https://www.w3.org/WAI/WCAG21/Understanding/target-size.html

---

**This template ensures consistent, accessible, dark-mode-ready UI components.**
