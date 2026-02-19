# Production Deployment Testing Scripts

Automated scripts to verify production deployments are working correctly.

## Quick Start

### Run Verification Now

```bash
./scripts/verify-production-deployment.sh
```

This will test:
- ✅ Admin dashboard loads
- ✅ Correct URLs in JavaScript bundles
- ✅ API endpoint connectivity and headers
- ✅ WebSocket endpoint connectivity
- ✅ All admin pages accessible
- ✅ Driver app configuration
- ✅ Landing page loads

### Watch for Deployment Changes

```bash
./scripts/watch-deployment.sh
```

This will:
- Monitor the admin dashboard bundle hash every 30 seconds
- Automatically run verification tests when a new deployment is detected
- Keep watching for changes until you stop it (Ctrl+C)

## Scripts

### `verify-production-deployment.sh`

**Comprehensive deployment verification** - Tests all critical aspects of the production deployment.

**Exit codes:**
- `0` - All tests passed
- `1` - Some tests failed, but deployment mostly working
- `2` - Critical failures detected

**Usage:**
```bash
# Run all tests
./scripts/verify-production-deployment.sh

# Run with verbose output
bash -x ./scripts/verify-production-deployment.sh
```

**What it tests:**

1. **Admin Dashboard HTML** - Verifies the page loads and extracts bundle hash
2. **Deployment Freshness** - Checks if bundle hash changed from previous deployment
3. **JavaScript Bundle URLs** - Verifies correct production URLs in code
4. **API Connectivity** - Tests that `api.gamaleigan.is` is responding
5. **CORS Headers** - Validates cross-origin configuration
6. **Security Headers** - Checks HSTS, CSP, X-Content-Type-Options
7. **WebSocket Connectivity** - Tests that `ws.gamaleigan.is` is accessible
8. **Page Accessibility** - Verifies all admin pages load (/, /gamar, /vidskiptavinir, etc.)
9. **Driver App** - Tests driver app URLs and configuration
10. **Landing Page** - Verifies landing page loads

### `watch-deployment.sh`

**Continuous deployment monitoring** - Watches for deployment changes and auto-runs verification.

**Usage:**
```bash
# Start watching (runs in foreground)
./scripts/watch-deployment.sh

# Run in background with logging
./scripts/watch-deployment.sh > deployment-watch.log 2>&1 &

# Stop background process
pkill -f watch-deployment.sh
```

**Monitoring:**
- Checks every 30 seconds (configurable via `CHECK_INTERVAL` variable)
- Shows progress indicator with check count
- Automatically runs verification when deployment changes
- Continues watching after verification completes

## Example Output

### Verification Script

```
========================================
Production Deployment Verification
========================================

[1/10] Admin Dashboard - HTML Structure
✓ Admin dashboard HTML loads
ℹ Bundle hash: abc123def

[2/10] Deployment Freshness
✓ New deployment detected (bundle hash changed)
ℹ Old: jn_qU5vi → New: abc123def

[3/10] JavaScript Bundle - URL Configuration
✓ No references to old litla.workers.dev domain
✓ Found 15 references to api.gamaleigan.is
✓ Found 3 references to ws.gamaleigan.is

...

========================================
Test Summary
========================================
Passed:   23
Failed:   0
Warnings: 2

✓ All critical tests passed!
```

### Watch Script

```
========================================
Deployment Watcher
========================================

Current bundle hash: jn_qU5vi
Watching for changes... (Ctrl+C to stop)

Checked 12 times (last check: 19:45:32)

✓ New deployment detected!
  Old: jn_qU5vi
  New: abc123def

Running verification tests...

[verification output...]

✓ Verification complete
Continuing to watch for changes...
```

## Troubleshooting

### Script won't execute
```bash
# Make executable
chmod +x scripts/verify-production-deployment.sh
chmod +x scripts/watch-deployment.sh
```

### curl errors
```bash
# Install curl if missing
sudo apt-get install curl  # Ubuntu/Debian
brew install curl          # macOS
```

### Watch script exits immediately
```bash
# Check for syntax errors
bash -n scripts/watch-deployment.sh

# Run with debugging
bash -x scripts/watch-deployment.sh
```

## CI/CD Integration

### GitHub Actions

Add to `.github/workflows/verify-deployment.yml`:

```yaml
name: Verify Deployment

on:
  push:
    branches: [main]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Wait for deployment
        run: sleep 120  # Wait 2 min for Cloudflare Pages
      - name: Verify deployment
        run: ./scripts/verify-production-deployment.sh
```

### Manual Check After Push

```bash
# 1. Push your changes
git push

# 2. Wait ~2 minutes for Cloudflare Pages to build

# 3. Run verification
./scripts/verify-production-deployment.sh
```

## What to Check If Tests Fail

### Old URLs in bundle
- Check `.env.production` files updated
- Verify Cloudflare Pages picked up latest commit
- Check build logs for errors

### API/WebSocket connectivity issues
- Verify custom domains configured in Cloudflare
- Check DNS propagation: `nslookup api.gamaleigan.is`
- Test Worker directly: `curl https://api.gamaleigan.is/api/auth/me`

### Pages not loading
- Check Cloudflare Pages deployment status
- Verify build completed successfully
- Check browser console for JavaScript errors

## Notes

- **Bundle hash changes** indicate a new deployment
- **HTTP 401** from API is expected (unauthenticated)
- **HTTP 426** from WebSocket is expected (upgrade required)
- **Warnings** are informational, not failures
- Scripts require `bash`, `curl`, `grep`, `sed`

## Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Environment variables and deployment
- [TODO.md](../TODO.md) - Project status and progress
- [SESSION.md](../SESSION.md) - Current phase and next actions
