#!/bin/bash
#
# verify-next-tasks.sh
# Pre-delegation verification for next task batch (TASK-121, TASK-122, TASK-150)
#
# Usage: ./scripts/verify-next-tasks.sh
#
# Created: January 3, 2026
#

set -e  # Exit on error

echo "==================================="
echo "Pre-Delegation Task Verification"
echo "Next Batch: TASK-121, TASK-122, TASK-150"
echo "==================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verification functions
check_exists() {
    if [ -n "$1" ]; then
        echo -e "${GREEN}✅ EXISTS${NC}"
        return 0
    else
        echo -e "${RED}❌ NOT FOUND${NC}"
        return 1
    fi
}

check_not_exists() {
    if [ -z "$1" ]; then
        echo -e "${GREEN}✅ NOT FOUND (ready to implement)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  ALREADY EXISTS${NC}"
        return 1
    fi
}

# ==============================================
# TASK-121: Integration Testing
# ==============================================
echo "-----------------------------------"
echo "TASK-121: Integration Testing (12h)"
echo "-----------------------------------"

echo -n "1. Check for integration test files: "
INTEGRATION_TESTS=$(find . -name "*.test.ts" -o -name "*.spec.ts" 2>/dev/null | grep -i integration || true)
check_not_exists "$INTEGRATION_TESTS"

echo -n "2. Check for supertest/API testing lib: "
API_TEST_LIB=$(grep -E "supertest|@testcontainers|msw" package.json packages/*/package.json 2>/dev/null || true)
check_not_exists "$API_TEST_LIB"

echo -n "3. Check for integration test config: "
INTEGRATION_CONFIG=$(find . -name "vitest.integration.config.ts" -o -name "jest.integration.config.js" 2>/dev/null || true)
check_not_exists "$INTEGRATION_CONFIG"

echo -n "4. Check for API test utilities: "
API_UTILS=$(find tests -name "*api*.ts" -o -name "*request*.ts" 2>/dev/null | head -5 || true)
if [ -z "$API_UTILS" ]; then
    echo -e "${GREEN}✅ NOT FOUND (ready to implement)${NC}"
    TASK_121_READY=true
else
    echo -e "${YELLOW}⚠️  FOUND: $API_UTILS${NC}"
    TASK_121_READY=false
fi

if [ "$TASK_121_READY" = true ]; then
    echo -e "\n${GREEN}✅ TASK-121: Ready to delegate${NC}"
    echo "   - No existing integration tests"
    echo "   - No API testing library installed"
    echo "   - Agent can implement from scratch"
else
    echo -e "\n${YELLOW}⚠️  TASK-121: Partial implementation exists${NC}"
    echo "   - Review existing tests before delegating"
    echo "   - May need to enhance rather than create"
fi

echo ""

# ==============================================
# TASK-122: Load Testing
# ==============================================
echo "-----------------------------------"
echo "TASK-122: Load Testing (16h)"
echo "-----------------------------------"

echo -n "1. Check for k6 installation: "
K6_INSTALLED=$(grep -E "\"k6\":|@k6/" package.json packages/*/package.json 2>/dev/null || true)
check_not_exists "$K6_INSTALLED"

echo -n "2. Check for Artillery installation: "
ARTILLERY_INSTALLED=$(grep "artillery" package.json packages/*/package.json 2>/dev/null || true)
check_not_exists "$ARTILLERY_INSTALLED"

echo -n "3. Check for load test scripts: "
LOAD_SCRIPTS=$(find . -name "*load*.js" -o -name "*stress*.js" -o -name "*benchmark*.js" 2>/dev/null | grep -v node_modules || true)
check_not_exists "$LOAD_SCRIPTS"

echo -n "4. Check for performance test config: "
PERF_CONFIG=$(find . -name "k6.*.js" -o -name "artillery.*.yml" 2>/dev/null || true)
check_not_exists "$PERF_CONFIG"

echo -n "5. Check for load testing docs: "
LOAD_DOCS=$(find docs -name "*LOAD*" -o -name "*PERFORMANCE*" 2>/dev/null || true)
if [ -z "$LOAD_DOCS" ]; then
    echo -e "${GREEN}✅ NOT FOUND (ready to implement)${NC}"
    TASK_122_READY=true
else
    echo -e "${YELLOW}⚠️  FOUND: $LOAD_DOCS${NC}"
    TASK_122_READY=false
fi

if [ "$TASK_122_READY" = true ]; then
    echo -e "\n${GREEN}✅ TASK-122: Ready to delegate${NC}"
    echo "   - No load testing framework installed"
    echo "   - No load test scripts exist"
    echo "   - Agent can implement from scratch"
else
    echo -e "\n${YELLOW}⚠️  TASK-122: Partial implementation exists${NC}"
    echo "   - Review existing setup before delegating"
fi

echo ""

# ==============================================
# TASK-150: i18n Framework
# ==============================================
echo "-----------------------------------"
echo "TASK-150: i18n Framework (24h)"
echo "-----------------------------------"

echo -n "1. Check for i18next: "
I18NEXT_INSTALLED=$(grep -E "i18next|react-i18next" package.json packages/*/package.json apps/*/package.json 2>/dev/null || true)
check_not_exists "$I18NEXT_INSTALLED"

echo -n "2. Check for react-intl: "
REACT_INTL=$(grep "react-intl" package.json packages/*/package.json apps/*/package.json 2>/dev/null || true)
check_not_exists "$REACT_INTL"

echo -n "3. Check for vue-i18n: "
VUE_I18N=$(grep "vue-i18n" package.json packages/*/package.json apps/*/package.json 2>/dev/null || true)
check_not_exists "$VUE_I18N"

echo -n "4. Check for translation files: "
TRANSLATION_FILES=$(find . -path "*/locales/*.json" -o -path "*/i18n/*.json" -o -path "*/translations/*.json" 2>/dev/null | grep -v node_modules | head -5 || true)
check_not_exists "$TRANSLATION_FILES"

echo -n "5. Check for i18n config: "
I18N_CONFIG=$(find apps -name "i18n.ts" -o -name "i18n.js" -o -name "i18n.config.ts" 2>/dev/null || true)
check_not_exists "$I18N_CONFIG"

echo -n "6. Check for existing Icelandic content: "
ICELANDIC_CONTENT=$(grep -r "Íslenska\|Íslensku" apps/*/src --include="*.tsx" --include="*.ts" 2>/dev/null | wc -l || echo "0")
if [ "$ICELANDIC_CONTENT" -gt 0 ]; then
    echo -e "${GREEN}✅ FOUND ($ICELANDIC_CONTENT references)${NC}"
    echo "   - Existing Icelandic content can be extracted to translations"
    TASK_150_READY=true
else
    echo -e "${YELLOW}⚠️  NO ICELANDIC CONTENT FOUND${NC}"
    TASK_150_READY=false
fi

if [ "$TASK_150_READY" = true ]; then
    echo -e "\n${GREEN}✅ TASK-150: Ready to delegate${NC}"
    echo "   - No i18n framework installed"
    echo "   - No translation files exist"
    echo "   - Agent can implement i18n from scratch"
else
    echo -e "\n${YELLOW}⚠️  TASK-150: May need investigation${NC}"
    echo "   - Verify Icelandic content exists in codebase"
fi

echo ""

# ==============================================
# Summary
# ==============================================
echo "==================================="
echo "Summary"
echo "==================================="

READY_COUNT=0
if [ "$TASK_121_READY" = true ]; then ((READY_COUNT++)); fi
if [ "$TASK_122_READY" = true ]; then ((READY_COUNT++)); fi
if [ "$TASK_150_READY" = true ]; then ((READY_COUNT++)); fi

echo "Tasks ready to delegate: $READY_COUNT / 3"
echo ""

if [ "$TASK_121_READY" = true ]; then
    echo -e "${GREEN}✅ TASK-121: Integration Testing (12h)${NC}"
else
    echo -e "${YELLOW}⚠️  TASK-121: Review existing tests first${NC}"
fi

if [ "$TASK_122_READY" = true ]; then
    echo -e "${GREEN}✅ TASK-122: Load Testing (16h)${NC}"
else
    echo -e "${YELLOW}⚠️  TASK-122: Review existing setup first${NC}"
fi

if [ "$TASK_150_READY" = true ]; then
    echo -e "${GREEN}✅ TASK-150: i18n Framework (24h)${NC}"
else
    echo -e "${YELLOW}⚠️  TASK-150: Investigate Icelandic content first${NC}"
fi

echo ""
echo "==================================="
echo "Next Actions"
echo "==================================="
echo "1. Wait for current 5 agents to complete"
echo "2. Collect and verify their results"
echo "3. Delegate next batch (TASK-121, TASK-122, TASK-150)"
echo "4. Continue passive monitoring"
echo ""
echo "See: docs/AGENT_RESULTS_COLLECTION_PROTOCOL.md"
echo "==================================="
