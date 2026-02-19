#!/bin/bash

# Test Sentry Auth Token Configuration
# Usage: bash scripts/test-sentry-auth.sh [app-name]
# Example: bash scripts/test-sentry-auth.sh litla-admin

set -e

APP_NAME=${1:-litla-admin}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Testing Sentry Auth Token Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Determine app path
if [ "$APP_NAME" = "litla-admin" ]; then
    APP_PATH="apps/litla-admin"
    PROJECT="litla-admin"
elif [ "$APP_NAME" = "litla-drivers" ]; then
    APP_PATH="apps/litla-drivers"
    PROJECT="litla-drivers"
else
    echo "❌ Invalid app name. Use 'litla-admin' or 'litla-drivers'"
    exit 1
fi

echo "📦 App: $APP_NAME"
echo "📁 Path: $APP_PATH"
echo ""

# Check .env file exists
echo "1️⃣  Checking .env file..."
if [ ! -f "$APP_PATH/.env" ]; then
    echo "   ❌ .env file not found at $APP_PATH/.env"
    echo "   💡 Run: cp $APP_PATH/.env.example $APP_PATH/.env"
    exit 1
fi
echo "   ✅ .env file exists"
echo ""

# Load environment variables
echo "2️⃣  Loading environment variables..."
cd "$APP_PATH"
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi
echo "   ✅ Loaded .env"
echo ""

# Check SENTRY_AUTH_TOKEN
echo "3️⃣  Checking SENTRY_AUTH_TOKEN..."
if [ -z "$SENTRY_AUTH_TOKEN" ]; then
    echo "   ❌ SENTRY_AUTH_TOKEN is not set"
    echo "   💡 Add to .env: SENTRY_AUTH_TOKEN=sntrys_ey...your-token...xYz"
    echo "   📖 See docs/SENTRY_AUTH_SETUP.md for setup guide"
    exit 1
fi

# Check token format (should start with 'sntrys_')
if [[ ! "$SENTRY_AUTH_TOKEN" =~ ^sntrys_ ]]; then
    echo "   ⚠️  Token doesn't start with 'sntrys_' - might be invalid"
    echo "   💡 Check your token at: https://sentry.io/settings/account/api/auth-tokens/"
fi

# Mask token for display (show first 10 and last 4 chars)
TOKEN_LENGTH=${#SENTRY_AUTH_TOKEN}
TOKEN_DISPLAY="${SENTRY_AUTH_TOKEN:0:10}...${SENTRY_AUTH_TOKEN: -4}"
echo "   ✅ SENTRY_AUTH_TOKEN is set: $TOKEN_DISPLAY"
echo ""

# Check SENTRY_ORG
echo "4️⃣  Checking SENTRY_ORG..."
if [ -z "$SENTRY_ORG" ]; then
    echo "   ❌ SENTRY_ORG is not set"
    echo "   💡 Add to .env: SENTRY_ORG=litla-gamaleigan"
    exit 1
fi
echo "   ✅ SENTRY_ORG=$SENTRY_ORG"
echo ""

# Check SENTRY_PROJECT
echo "5️⃣  Checking SENTRY_PROJECT..."
if [ -z "$SENTRY_PROJECT" ]; then
    echo "   ❌ SENTRY_PROJECT is not set"
    echo "   💡 Add to .env: SENTRY_PROJECT=$PROJECT"
    exit 1
fi

if [ "$SENTRY_PROJECT" != "$PROJECT" ]; then
    echo "   ⚠️  SENTRY_PROJECT mismatch: expected '$PROJECT', got '$SENTRY_PROJECT'"
    echo "   💡 Update .env: SENTRY_PROJECT=$PROJECT"
fi
echo "   ✅ SENTRY_PROJECT=$SENTRY_PROJECT"
echo ""

# Test token with Sentry API
echo "6️⃣  Testing token with Sentry API..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
    "https://sentry.io/api/0/organizations/$SENTRY_ORG/projects/")

if [ "$RESPONSE" = "200" ]; then
    echo "   ✅ Token is valid (HTTP 200)"
    echo ""

    # Get project list
    echo "7️⃣  Fetching projects..."
    PROJECT_LIST=$(curl -s \
        -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
        "https://sentry.io/api/0/organizations/$SENTRY_ORG/projects/" \
        | grep -o '"slug":"[^"]*"' | cut -d'"' -f4)

    if echo "$PROJECT_LIST" | grep -q "$SENTRY_PROJECT"; then
        echo "   ✅ Project '$SENTRY_PROJECT' found in organization"
    else
        echo "   ⚠️  Project '$SENTRY_PROJECT' not found in organization"
        echo "   Available projects:"
        echo "$PROJECT_LIST" | sed 's/^/      - /'
    fi
elif [ "$RESPONSE" = "401" ]; then
    echo "   ❌ Token is invalid (HTTP 401 Unauthorized)"
    echo "   💡 Check token at: https://sentry.io/settings/account/api/auth-tokens/"
    exit 1
elif [ "$RESPONSE" = "403" ]; then
    echo "   ❌ Token lacks permissions (HTTP 403 Forbidden)"
    echo "   💡 Token needs scopes: project:read, project:write, project:releases"
    exit 1
elif [ "$RESPONSE" = "404" ]; then
    echo "   ❌ Organization not found (HTTP 404)"
    echo "   💡 Check SENTRY_ORG=$SENTRY_ORG is correct"
    exit 1
else
    echo "   ⚠️  Unexpected response (HTTP $RESPONSE)"
    echo "   💡 Check your internet connection and try again"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All checks passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📖 Next steps:"
echo "   1. Test source map upload:"
echo "      cd $APP_PATH"
echo "      SENTRY_UPLOAD_MAPS=true npm run build"
echo ""
echo "   2. Verify upload in Sentry:"
echo "      https://sentry.io/organizations/$SENTRY_ORG/projects/$SENTRY_PROJECT/settings/source-maps/"
echo ""
echo "   3. See docs/SENTRY_AUTH_SETUP.md for more info"
echo ""
