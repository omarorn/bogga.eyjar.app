---
paths: "**/*.astro"
---

# Astro JavaScript Variable Scoping

Astro script tags share the same JavaScript namespace, requiring careful variable naming to avoid conflicts.

## Pattern

| If Claude suggests... | Use instead... |
|----------------------|----------------|
| Declaring new variable with existing name | Reuse existing variable or use unique name |
| Adding `const x` when `x` exists | Use `const xParallax` or reuse existing `x` |
| Multiple `querySelector` for same element | Store in one variable, reference throughout |

## Variable Scoping Rules

**Astro client-side scripts:**
- All `<script>` tags compile to single JavaScript file
- Variables are hoisted to file scope
- Duplicate declarations cause build errors
- Error: `The symbol "X" has already been declared`

**Safe patterns:**
```astro
<script>
  // ✅ GOOD: Single declaration, multiple uses
  const heroVideo = document.querySelector('.hero-video');

  if (heroVideo) {
    // Use for autoplay
    heroVideo.play();

    // Use for event listener
    heroVideo.addEventListener('ended', () => {
      heroVideo.currentTime = 0;
      heroVideo.play();
    });

    // Use for parallax (same variable)
    window.addEventListener('scroll', () => {
      const scrolled = window.pageYOffset;
      heroVideo.style.transform = `translate(-50%, calc(-50% + ${scrolled * 0.5}px))`;
    });
  }
</script>
```

**Unsafe patterns:**
```astro
<script>
  // ❌ BAD: First declaration
  const heroVideo = document.querySelector('.hero-video');

  if (heroVideo) {
    heroVideo.play();
  }

  // ❌ ERROR: Duplicate declaration
  const heroVideo = document.querySelector('.hero-video'); // Build fails!

  if (heroVideo) {
    // Add parallax...
  }
</script>
```

## Solutions

### Solution 1: Reuse Existing Variable

**Before (causes error):**
```astro
<script>
  const heroVideo = document.querySelector('.hero-video');
  heroVideo.play();

  // Later in same script...
  const heroVideo = document.querySelector('.hero-video'); // ERROR!
  heroVideo.style.transform = '...';
</script>
```

**After (fixed):**
```astro
<script>
  const heroVideo = document.querySelector('.hero-video');

  if (heroVideo) {
    // Autoplay feature
    heroVideo.play();

    // Parallax feature (reuse same variable)
    window.addEventListener('scroll', () => {
      heroVideo.style.transform = '...';
    });
  }
</script>
```

### Solution 2: Use Unique Names

**Before (causes error):**
```astro
<script>
  const video = document.querySelector('.hero-video');
  video.play();

  // Adding new feature...
  const video = document.querySelector('.hero-video'); // ERROR!
</script>
```

**After (fixed):**
```astro
<script>
  const video = document.querySelector('.hero-video');
  video.play();

  // Adding new feature with unique name
  const parallaxVideo = document.querySelector('.hero-video');
  window.addEventListener('scroll', () => {
    parallaxVideo.style.transform = '...';
  });
</script>
```

### Solution 3: Organize by Feature

**Group related functionality:**
```astro
<script>
  // Video playback feature
  function setupVideoPlayback() {
    const video = document.querySelector('.hero-video');
    if (!video) return;

    video.play();
    video.addEventListener('ended', () => {
      video.currentTime = 0;
      video.play();
    });
  }

  // Parallax feature
  function setupParallax() {
    const video = document.querySelector('.hero-video');
    if (!video) return;

    window.addEventListener('scroll', () => {
      const scrolled = window.pageYOffset;
      video.style.transform = `translate(-50%, calc(-50% + ${scrolled * 0.5}px))`;
    });
  }

  // Initialize features
  setupVideoPlayback();
  setupParallax();
</script>
```

## Common Errors

### Error 1: Duplicate const declaration

**Build error:**
```
✗ Build failed in 2.10s
The symbol "heroVideo" has already been declared

Location:
  /src/pages/index.astro?astro&type=script&index=0&lang.ts:84:14
```

**Fix:**
1. Search script for existing declaration
2. Either reuse existing variable
3. Or rename new variable to be unique

### Error 2: Browser API not available

**Build error:**
```
The symbol "document" is not defined

Hint:
  Browser APIs are not available on the server.
  Use a `client:only` directive or check for browser environment.
```

**Fix:**
```astro
<script>
  // ✅ Client-side only
  if (typeof window !== 'undefined') {
    const element = document.querySelector('.hero');
    // ...
  }
</script>

<!-- Or use client directive -->
<script is:inline>
  // Runs only in browser
  const element = document.querySelector('.hero');
</script>
```

## Best Practices

### 1. Check Before Declaring

**Before adding new code:**
```bash
# Search for existing declarations
grep -n "const heroVideo" src/pages/index.astro
grep -n "querySelector('.hero-video')" src/pages/index.astro
```

### 2. Use Descriptive Names

```astro
<script>
  // ✅ GOOD: Descriptive, unique names
  const heroVideo = document.querySelector('.hero-video');
  const parallaxContainer = document.querySelector('.parallax-container');
  const scrollIndicator = document.querySelector('.scroll-indicator');

  // ❌ BAD: Generic names (high collision risk)
  const video = document.querySelector('.hero-video');
  const element = document.querySelector('.parallax-container');
  const div = document.querySelector('.scroll-indicator');
</script>
```

### 3. Single Responsibility

```astro
<script>
  // ✅ GOOD: Each feature gets its own function
  function initializeHeroVideo() {
    const video = document.querySelector('.hero-video');
    // Video setup...
  }

  function initializeParallax() {
    const video = document.querySelector('.hero-video');
    // Parallax setup...
  }

  // ❌ BAD: Everything in global scope
  const video1 = document.querySelector('.hero-video');
  const video2 = document.querySelector('.hero-video'); // Name conflict!
</script>
```

## Verification

**After adding script code:**

```bash
# Build to check for errors
npm run build

# Look for duplicate declaration errors
# Expected: Clean build or unrelated errors only
# Not expected: "The symbol X has already been declared"
```

## Context

Discovered on January 1, 2026 while adding parallax scroll effect to hero section. Initial implementation declared `const heroVideo` twice in same script tag, causing build failure. Fixed by renaming second declaration to `const parallaxVideo`.

**Example file:** `apps/litlagamaleigan-web/src/pages/index.astro` (lines 569-602)

## References

- **Astro Scripts:** https://docs.astro.build/en/guides/client-side-scripts/
- **Astro Troubleshooting:** https://docs.astro.build/en/guides/troubleshooting/
- **JavaScript Scoping:** https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/const
