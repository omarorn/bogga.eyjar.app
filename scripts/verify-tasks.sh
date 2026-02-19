#!/bin/bash

# Task Verification Script
# Purpose: Verify which tasks from tasks.md already exist in codebase
# Usage: ./scripts/verify-tasks.sh

set -e

echo "=================================================="
echo "Task Verification Report"
echo "Generated: $(date)"
echo "=================================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a feature exists
check_feature() {
    local task_id=$1
    local feature_name=$2
    local search_pattern=$3

    echo -e "\n📋 ${YELLOW}${task_id}${NC}: ${feature_name}"
    echo "   Searching for: ${search_pattern}"

    # Search for files
    local files=$(grep -r "${search_pattern}" packages/workers/src/ 2>/dev/null | head -5)

    if [ -z "$files" ]; then
        echo -e "   ${RED}❌ NOT FOUND${NC} - Feature does not exist"
        return 1
    else
        echo -e "   ${GREEN}✅ FOUND${NC} - Files exist:"
        echo "$files" | sed 's/^/      /'

        # Check implementation depth
        local first_file=$(echo "$files" | head -1 | cut -d: -f1)
        if [ -f "$first_file" ]; then
            local line_count=$(wc -l < "$first_file")
            echo "   📊 Implementation depth: ${line_count} lines"

            if [ $line_count -lt 50 ]; then
                echo -e "   ${YELLOW}⚠️  STUB${NC} - Likely incomplete (< 50 lines)"
            elif [ $line_count -lt 100 ]; then
                echo -e "   ${YELLOW}🟠 STARTED${NC} - Partial implementation"
            elif [ $line_count -lt 200 ]; then
                echo -e "   ${GREEN}🟡 PARTIAL${NC} - Substantial work"
            else
                echo -e "   ${GREEN}✅ COMPLETE${NC} - Full implementation"
            fi

            # Check for TODOs
            local todos=$(grep -n "TODO\|FIXME\|XXX\|HACK" "$first_file" 2>/dev/null | wc -l)
            if [ $todos -gt 0 ]; then
                echo -e "   ${YELLOW}⚠️  ${todos} TODO(s) found${NC}"
            fi
        fi
        return 0
    fi
}

# Main verification
echo "Verifying common tasks..."

# Example tasks - customize for your project
check_feature "TASK-130" "Security Headers" "securityHeaders"
check_feature "TASK-131" "CSRF Protection" "csrfProtection"
check_feature "TASK-132" "SQL Injection Audit" "SQL_INJECTION_AUDIT"
check_feature "TASK-135" "Vehicle Fleet Management" "vehicles.ts"
check_feature "TASK-160" "Database Query Optimization" "DATABASE_OPTIMIZATION"

echo ""
echo "=================================================="
echo "Verification Complete"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  1. Review findings above"
echo "  2. Update tasks.md with verified statuses"
echo "  3. Only delegate tasks marked as NOT FOUND or STUB"
echo ""
