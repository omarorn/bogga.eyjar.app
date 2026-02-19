#!/bin/bash
# Production Deployment Verification Script
# Tests that all production domains are correctly configured and working

# Don't exit on errors - collect all test results
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0
WARNINGS=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Production Deployment Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Test 1: Check Admin Dashboard HTML
echo -e "\n${BLUE}[1/10] Admin Dashboard - HTML Structure${NC}"
ADMIN_HTML=$(curl -s --max-time 30 https://admin.gamaleigan.is)
BUNDLE_HASH=$(echo "$ADMIN_HTML" | grep -o 'src="/assets/index-[^"]*\.js"' | head -1 | sed 's/.*index-\([^"]*\)\.js.*/\1/')

if [ -n "$BUNDLE_HASH" ]; then
    pass "Admin dashboard HTML loads"
    info "Bundle hash: $BUNDLE_HASH"
else
    fail "Admin dashboard HTML missing or malformed"
fi

# Test 2: Check if deployment is recent (bundle hash changed)
echo -e "\n${BLUE}[2/10] Deployment Freshness${NC}"
OLD_BUNDLE="jn_qU5vi"
if [ "$BUNDLE_HASH" = "$OLD_BUNDLE" ]; then
    warn "Bundle hash unchanged - deployment may not have completed"
    warn "Old: $OLD_BUNDLE | Current: $BUNDLE_HASH"
else
    pass "New deployment detected (bundle hash changed)"
    info "Old: $OLD_BUNDLE → New: $BUNDLE_HASH"
fi

# Test 3: Check JavaScript bundle for correct URLs
echo -e "\n${BLUE}[3/10] JavaScript Bundle - URL Configuration${NC}"
if [ -n "$BUNDLE_HASH" ]; then
    BUNDLE_URL="https://admin.gamaleigan.is/assets/index-${BUNDLE_HASH}.js"
    BUNDLE_JS=$(curl -s --max-time 30 "$BUNDLE_URL")

    # Check for old URLs (should be 0)
    OLD_URL_COUNT=$(echo "$BUNDLE_JS" | grep -o "litla\.workers\.dev" | wc -l)
    if [ "$OLD_URL_COUNT" -eq 0 ]; then
        pass "No references to old litla.workers.dev domain"
    else
        fail "Found $OLD_URL_COUNT references to litla.workers.dev"
    fi

    # Check for new API URL (should be present)
    NEW_API_COUNT=$(echo "$BUNDLE_JS" | grep -o "api\.gamaleigan\.is" | wc -l)
    if [ "$NEW_API_COUNT" -gt 0 ]; then
        pass "Found $NEW_API_COUNT references to api.gamaleigan.is"
    else
        fail "No references to api.gamaleigan.is found"
    fi

    # Check for WebSocket URL (should be present)
    NEW_WS_COUNT=$(echo "$BUNDLE_JS" | grep -o "ws\.gamaleigan\.is" | wc -l)
    if [ "$NEW_WS_COUNT" -gt 0 ]; then
        pass "Found $NEW_WS_COUNT references to ws.gamaleigan.is"
    else
        warn "No references to ws.gamaleigan.is found (may use variable)"
    fi
else
    warn "Skipping bundle check - no bundle hash found"
fi

# Test 4: API Endpoint - Connectivity
echo -e "\n${BLUE}[4/10] API Endpoint - Connectivity${NC}"
API_STATUS=$(curl -s --max-time 15 -o /dev/null -w "%{http_code}" https://api.gamaleigan.is/api/auth/me)
if [ "$API_STATUS" = "401" ]; then
    pass "API endpoint responding (HTTP 401 - expected for unauthenticated)"
elif [ "$API_STATUS" = "200" ]; then
    pass "API endpoint responding (HTTP 200)"
else
    fail "API endpoint returned unexpected status: HTTP $API_STATUS"
fi

# Test 5: API Endpoint - CORS Headers
echo -e "\n${BLUE}[5/10] API Endpoint - CORS Configuration${NC}"
CORS_HEADER=$(curl -s --max-time 15 -I https://api.gamaleigan.is/api/auth/me | grep -i "access-control-allow-origin")
if echo "$CORS_HEADER" | grep -q "admin.gamaleigan.is"; then
    pass "CORS configured for admin.gamaleigan.is"
elif echo "$CORS_HEADER" | grep -q "litla.gamaleigan.is"; then
    pass "CORS configured for litla.gamaleigan.is"
else
    warn "CORS header found but domain unclear: $CORS_HEADER"
fi

# Test 6: API Endpoint - Security Headers
echo -e "\n${BLUE}[6/10] API Endpoint - Security Headers${NC}"
HEADERS=$(curl -s --max-time 15 -I https://api.gamaleigan.is/api/auth/me)

if echo "$HEADERS" | grep -qi "strict-transport-security"; then
    pass "HSTS header present"
else
    warn "HSTS header missing"
fi

if echo "$HEADERS" | grep -qi "content-security-policy"; then
    pass "CSP header present"
else
    warn "CSP header missing"
fi

if echo "$HEADERS" | grep -qi "x-content-type-options"; then
    pass "X-Content-Type-Options header present"
else
    warn "X-Content-Type-Options header missing"
fi

# Test 7: WebSocket Endpoint - Connectivity
echo -e "\n${BLUE}[7/10] WebSocket Endpoint - Connectivity${NC}"
WS_STATUS=$(curl -s --max-time 15 -o /dev/null -w "%{http_code}" "https://ws.gamaleigan.is/ws/stjornbord" --http1.1)
if [ "$WS_STATUS" = "426" ]; then
    pass "WebSocket endpoint responding (HTTP 426 Upgrade Required - expected)"
elif [ "$WS_STATUS" = "101" ]; then
    pass "WebSocket endpoint responding (HTTP 101 Switching Protocols)"
else
    fail "WebSocket endpoint returned unexpected status: HTTP $WS_STATUS"
fi

# Test 8: Admin Pages - Accessibility
echo -e "\n${BLUE}[8/10] Admin Pages - Accessibility${NC}"
PAGES=(
    "/"
    "/gamar"
    "/vidskiptavinir"
    "/pantanir"
    "/bilaflotin"
    "/notendur"
)

for page in "${PAGES[@]}"; do
    PAGE_STATUS=$(curl -s --max-time 15 -o /dev/null -w "%{http_code}" "https://admin.gamaleigan.is$page")
    if [ "$PAGE_STATUS" = "200" ]; then
        pass "Page loads: $page"
    else
        fail "Page failed: $page (HTTP $PAGE_STATUS)"
    fi
done

# Test 9: Driver App - URL Configuration
echo -e "\n${BLUE}[9/10] Driver App - Configuration${NC}"
DRIVER_HTML=$(curl -s --max-time 30 https://okumenn.gamaleigan.is)
DRIVER_BUNDLE=$(echo "$DRIVER_HTML" | grep -o 'src="/assets/index-[^"]*\.js"' | head -1)

if [ -n "$DRIVER_BUNDLE" ]; then
    pass "Driver app HTML loads"

    # Extract and check driver bundle
    DRIVER_HASH=$(echo "$DRIVER_BUNDLE" | sed 's/.*index-\([^"]*\)\.js.*/\1/')
    DRIVER_JS=$(curl -s --max-time 30 "https://okumenn.gamaleigan.is/assets/index-${DRIVER_HASH}.js")

    DRIVER_OLD_COUNT=$(echo "$DRIVER_JS" | grep -o "litla\.workers\.dev" | wc -l)
    if [ "$DRIVER_OLD_COUNT" -eq 0 ]; then
        pass "Driver app: No old URLs"
    else
        fail "Driver app: Found $DRIVER_OLD_COUNT old URLs"
    fi
else
    fail "Driver app HTML missing or malformed"
fi

# Test 10: Landing Page - API Configuration
echo -e "\n${BLUE}[10/10] Landing Page - Configuration${NC}"
LANDING_HTML=$(curl -s --max-time 30 https://litla.gamaleigan.is)
if echo "$LANDING_HTML" | grep -q "Litla Gámaleigan"; then
    pass "Landing page loads"
else
    fail "Landing page missing or malformed"
fi

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${RED}Failed:${NC}   $FAILED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical tests passed!${NC}"
    exit 0
elif [ $FAILED -le 2 ] && [ $PASSED -gt 15 ]; then
    echo -e "${YELLOW}⚠ Some tests failed, but deployment mostly working${NC}"
    exit 1
else
    echo -e "${RED}✗ Deployment verification failed${NC}"
    exit 1
fi
