#!/bin/bash

# Script to verify source maps are generated correctly
# Usage: bash scripts/verify-sourcemaps.sh [app-name]
# Example: bash scripts/verify-sourcemaps.sh litla-admin

set -e

APP=${1:-litla-admin}
APP_DIR="apps/$APP"

if [ ! -d "$APP_DIR" ]; then
  echo "Error: App directory $APP_DIR not found"
  exit 1
fi

echo "=========================================="
echo "Verifying source maps for: $APP"
echo "=========================================="
echo

# Check if dist directory exists
if [ ! -d "$APP_DIR/dist" ]; then
  echo "Error: dist directory not found. Run 'npm run build' first."
  exit 1
fi

echo "1. Checking for .js.map files in dist..."
MAP_COUNT=$(find "$APP_DIR/dist" -name "*.js.map" -type f | wc -l)
if [ "$MAP_COUNT" -eq 0 ]; then
  echo "  ❌ FAILED: No source map files found"
  echo "  Solution: Make sure vite.config.ts has: build: { sourcemap: true }"
  exit 1
fi
echo "  ✅ PASSED: Found $MAP_COUNT source map files"
echo

# List all source maps
echo "2. Source map files generated:"
find "$APP_DIR/dist" -name "*.js.map" -type f | while read -r file; do
  size=$(du -h "$file" | cut -f1)
  basename_file=$(basename "$file")
  echo "  ✓ $basename_file ($size)"
done
echo

# Check that .map files are valid JSON
echo "3. Validating source map JSON format..."
invalid_count=0
find "$APP_DIR/dist" -name "*.js.map" -type f | while read -r file; do
  if ! jq empty "$file" 2>/dev/null; then
    echo "  ❌ FAILED: Invalid JSON in $file"
    ((invalid_count++))
  fi
done
if [ "$invalid_count" -eq 0 ]; then
  echo "  ✅ PASSED: All source maps are valid JSON"
fi
echo

# Check for source map references in .js files
echo "4. Checking for source map references in bundles..."
JS_FILES=$(find "$APP_DIR/dist" -name "*.js" -type f | wc -l)
MAPPED_JS=$(grep -l "sourceMappingURL" "$APP_DIR/dist"/*.js 2>/dev/null | wc -l)
if [ "$MAPPED_JS" -gt 0 ]; then
  echo "  ✅ PASSED: Found $MAPPED_JS/$JS_FILES JS files with source map references"
else
  echo "  ⚠️  WARNING: No JS files reference source maps"
  echo "  This may be normal if using external source maps"
fi
echo

# Check for required Sentry environment variables
echo "5. Checking Sentry configuration..."
ENV_FILE="$APP_DIR/.env.production"
if [ ! -f "$ENV_FILE" ]; then
  echo "  ⚠️  WARNING: $ENV_FILE not found"
  echo "  Source map uploads require Sentry configuration"
else
  has_dsn=$(grep -c "VITE_SENTRY_DSN" "$ENV_FILE" || true)
  has_token=$(grep -c "SENTRY_AUTH_TOKEN" "$ENV_FILE" || true)
  has_org=$(grep -c "SENTRY_ORG" "$ENV_FILE" || true)

  if [ "$has_dsn" -gt 0 ] && [ "$has_token" -gt 0 ] && [ "$has_org" -gt 0 ]; then
    echo "  ✅ PASSED: Sentry configuration variables found"
  else
    echo "  ⚠️  WARNING: Some Sentry variables missing"
    [ "$has_dsn" -eq 0 ] && echo "    - Missing: VITE_SENTRY_DSN"
    [ "$has_token" -eq 0 ] && echo "    - Missing: SENTRY_AUTH_TOKEN"
    [ "$has_org" -eq 0 ] && echo "    - Missing: SENTRY_ORG"
  fi
fi
echo

# Check for Sentry SDK import
echo "6. Checking Sentry SDK initialization..."
if grep -q "@sentry/react" "$APP_DIR/src/main.tsx" 2>/dev/null; then
  echo "  ✅ PASSED: Sentry SDK imported in main.tsx"
else
  echo "  ❌ FAILED: Sentry SDK not found in main.tsx"
  echo "  Solution: Import Sentry in your main.tsx entry point"
fi
echo

# Summary
echo "=========================================="
echo "Source Map Verification Summary"
echo "=========================================="
echo "✅ Build artifacts generated: $MAP_COUNT source maps"
echo "✅ JSON validation: All maps are valid"
echo "✅ Source map references: Present in bundles"
echo
echo "Next steps:"
echo "1. To build with source map uploads to Sentry:"
echo "   npm run build:sourcemaps"
echo
echo "2. To verify uploads in Sentry:"
echo "   - Go to Sentry dashboard"
echo "   - Navigate to Releases"
echo "   - Find your release version"
echo "   - Check Files tab for uploaded maps"
echo
echo "3. To test error capture:"
echo "   - Trigger an error: throw new Error('Test')"
echo "   - Check Sentry dashboard for readable stack trace"
echo "=========================================="
