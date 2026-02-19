#!/bin/bash

# Deploy Admin App to Cloudflare Pages
# This script builds the admin app and deploys it to Cloudflare Pages

set -e  # Exit on error

# Load environment variables if .env exists
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Configuration
PROJECT_NAME="${PAGES_PROJECT_NAME:-my-admin}"
APP_DIR="${APP_DIR:-apps/admin}"

echo "🚀 Deploying Admin App to Cloudflare Pages"
echo "=========================================="
echo "Project: $PROJECT_NAME"
echo ""

# Navigate to admin directory
cd "$(dirname "$0")/../$APP_DIR"

# Build the app
echo "📦 Building application..."
npm run build

# Check if build succeeded
if [ ! -d "dist" ]; then
  echo "❌ Build failed - dist folder not found"
  exit 1
fi

echo "✅ Build complete"

# Deploy to Cloudflare Pages
echo ""
echo "☁️  Deploying to Cloudflare Pages..."
npx wrangler pages deploy dist --project-name="$PROJECT_NAME" --commit-dirty=true

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 Admin app deployed to: https://$PROJECT_NAME.pages.dev"
