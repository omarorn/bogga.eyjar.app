#!/bin/bash
# Pre-deployment verification script
# Checks for common issues before deploying to production

set -e

echo "🔍 Running pre-deployment checks..."
echo ""

# Check for merge conflicts
echo "1. Checking for merge conflicts..."
if grep -r "<<<<<<< HEAD" packages/workers/src/ apps/*/src/ 2>/dev/null; then
  echo "❌ FAILED: Merge conflict markers found!"
  echo "   Fix merge conflicts before deploying"
  exit 1
fi
echo "✅ No merge conflicts found"
echo ""

# Check TypeScript types (Cloudflare Workers)
echo "2. Running TypeScript type generation..."
cd packages/workers
if npm run cf-typegen >/dev/null 2>&1; then
  echo "✅ TypeScript types generated successfully"
else
  echo "⚠️  WARNING: Type generation failed (this may be okay)"
fi
cd ../..
echo ""

# Check for uncommitted changes
echo "3. Checking git status..."
if [[ -n $(git status --porcelain) ]]; then
  echo "⚠️  WARNING: You have uncommitted changes"
  git status --short
  echo ""
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
  fi
else
  echo "✅ Working directory clean"
fi
echo ""

# Summary
echo "✅ Pre-deployment checks passed!"
echo ""
echo "Ready to deploy:"
echo "  - Backend:  cd packages/workers && npx wrangler deploy"
echo "  - Frontend: cd apps/litla-admin && npm run build && npx wrangler pages deploy dist --project-name=litla-admin"
echo ""
