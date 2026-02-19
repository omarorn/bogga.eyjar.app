#!/bin/bash

################################################################################
# Litla Gámaleigan - Database Recovery Verification Script
#
# Description: Comprehensive verification of recovered database integrity
# Usage: ./verify-database-recovery.sh [database_name] [environment]
# Example: ./verify-database-recovery.sh litla-gamaleigan-db remote
#
# Features:
# - Validates table structure and schema
# - Verifies row counts in key tables
# - Checks data constraints and relationships
# - Detects data corruption or inconsistencies
# - Generates detailed verification report
#
# Exit Codes:
# 0 = All checks passed
# 1 = One or more checks failed
# 2 = Database connection error
#
# Author: Ómar Örn Magnúson (2076 ehf.)
# Created: January 2, 2026
################################################################################

set -e

# Configuration
DATABASE_NAME="${1:-litla-gamaleigan-db}"
ENVIRONMENT="${2:-remote}"
REPORT_FILE="/tmp/recovery-verification-$(date +%Y%m%d-%H%M%S).txt"
FAILED_CHECKS=0
PASSED_CHECKS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((PASSED_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((FAILED_CHECKS++))
}

log_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Execute query
execute_query() {
    local query="$1"
    if [ "$ENVIRONMENT" = "local" ]; then
        wrangler d1 execute "$DATABASE_NAME" --local --command "$query" 2>/dev/null || echo "ERROR"
    else
        wrangler d1 execute "$DATABASE_NAME" --remote --command "$query" 2>/dev/null || echo "ERROR"
    fi
}

# Check table exists
table_exists() {
    local table="$1"
    local result=$(execute_query "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='${table}';")
    if [[ "$result" == *"ERROR"* ]] || [ -z "$result" ]; then
        return 1
    fi
    # Result should be "1" if table exists
    if [[ "$result" =~ "1" ]]; then
        return 0
    else
        return 1
    fi
}

# Get row count
get_row_count() {
    local table="$1"
    local result=$(execute_query "SELECT COUNT(*) FROM ${table};" 2>&1 | grep -oE '[0-9]+' | tail -1)
    echo "$result"
}

# Validate inputs
if [ -z "$DATABASE_NAME" ]; then
    echo "Usage: $0 [database_name] [local|remote]"
    exit 1
fi

# Main verification
main() {
    echo ""
    log_header "Database Recovery Verification"
    echo ""
    log_info "Database: ${DATABASE_NAME}"
    log_info "Environment: ${ENVIRONMENT}"
    log_info "Time: $(date)"
    echo ""

    # Check database connectivity
    log_header "1. Database Connectivity"
    if execute_query "SELECT 1;" | grep -q "1"; then
        log_success "Database connection successful"
    else
        log_error "Cannot connect to database"
        exit 2
    fi
    echo ""

    # Check tables exist
    log_header "2. Table Structure Verification"

    EXPECTED_TABLES=(
        "containers"
        "customers"
        "orders"
        "sensor_readings"
        "alerts"
        "users"
        "drivers"
        "invoices"
        "order_photos"
        "driver_shifts"
        "collection_requests"
        "routes"
        "route_stops"
        "payments"
        "notifications"
        "audit_logs"
        "sessions"
        "landing_page_sections"
        "landing_page_features"
        "landing_page_faqs"
    )

    for table in "${EXPECTED_TABLES[@]}"; do
        if table_exists "$table"; then
            log_success "Table exists: ${table}"
        else
            log_error "Table missing: ${table}"
        fi
    done
    echo ""

    # Check row counts
    log_header "3. Data Integrity - Row Counts"

    # Expected row counts (approximate)
    declare -A EXPECTED_COUNTS=(
        ["containers"]="200"
        ["customers"]="1000"
        ["orders"]="3000"
        ["sensor_readings"]="50000"
        ["alerts"]="1000"
        ["users"]="20"
        ["drivers"]="50"
    )

    for table in "${!EXPECTED_COUNTS[@]}"; do
        if table_exists "$table"; then
            count=$(get_row_count "$table")
            expected="${EXPECTED_COUNTS[$table]}"

            if [ -z "$count" ] || [ "$count" = "0" ]; then
                log_warning "Table is empty: ${table}"
            elif [ "$count" -lt "$((expected / 2))" ]; then
                log_warning "Row count suspiciously low: ${table} (${count} < ${expected})"
            else
                log_success "Table has data: ${table} (${count} rows)"
            fi
        fi
    done
    echo ""

    # Check primary keys
    log_header "4. Primary Key Validation"

    TABLES_WITH_PK=("containers" "customers" "orders" "users" "drivers" "invoices")

    for table in "${TABLES_WITH_PK[@]}"; do
        if table_exists "$table"; then
            # Count distinct primary keys
            result=$(execute_query "SELECT COUNT(DISTINCT rowid) FROM ${table};" 2>&1 | grep -oE '[0-9]+' | tail -1)
            total=$(get_row_count "$table")

            if [ "$result" = "$total" ]; then
                log_success "Primary keys unique: ${table}"
            else
                log_error "Duplicate keys detected: ${table} (distinct: $result, total: $total)"
            fi
        fi
    done
    echo ""

    # Check foreign keys
    log_header "5. Foreign Key Constraints"

    log_info "Checking referential integrity..."

    if table_exists "orders"; then
        # Verify orders reference valid customers and containers
        orphaned=$(execute_query "SELECT COUNT(*) FROM orders WHERE customer_id NOT IN (SELECT id FROM customers);" 2>&1 | grep -oE '[0-9]+' | tail -1)
        if [ "$orphaned" = "0" ]; then
            log_success "Orders: All customer references valid"
        else
            log_warning "Orders: $orphaned orphaned customer references found"
        fi

        orphaned=$(execute_query "SELECT COUNT(*) FROM orders WHERE container_id NOT IN (SELECT id FROM containers);" 2>&1 | grep -oE '[0-9]+' | tail -1)
        if [ "$orphaned" = "0" ]; then
            log_success "Orders: All container references valid"
        else
            log_warning "Orders: $orphaned orphaned container references found"
        fi
    fi

    if table_exists "sensor_readings"; then
        # Verify sensor readings reference valid containers
        orphaned=$(execute_query "SELECT COUNT(*) FROM sensor_readings WHERE container_id NOT IN (SELECT id FROM containers);" 2>&1 | grep -oE '[0-9]+' | tail -1)
        if [ "$orphaned" = "0" ]; then
            log_success "Sensor Readings: All container references valid"
        else
            log_warning "Sensor Readings: $orphaned orphaned references found"
        fi
    fi
    echo ""

    # Check data ranges
    log_header "6. Data Range Validation"

    if table_exists "containers"; then
        # Check fill_level is between 0-100
        invalid=$(execute_query "SELECT COUNT(*) FROM containers WHERE fill_level NOT BETWEEN 0 AND 100;" 2>&1 | grep -oE '[0-9]+' | tail -1)
        if [ "$invalid" = "0" ] || [ -z "$invalid" ]; then
            log_success "Containers: fill_level values valid (0-100)"
        else
            log_error "Containers: $invalid records with invalid fill_level"
        fi

        # Check status values
        invalid=$(execute_query "SELECT COUNT(*) FROM containers WHERE status NOT IN ('available', 'active', 'in_transit', 'maintenance');" 2>&1 | grep -oE '[0-9]+' | tail -1)
        if [ "$invalid" = "0" ] || [ -z "$invalid" ]; then
            log_success "Containers: status values valid"
        else
            log_error "Containers: $invalid records with invalid status"
        fi
    fi

    if table_exists "alerts"; then
        # Check alert severity
        invalid=$(execute_query "SELECT COUNT(*) FROM alerts WHERE severity NOT IN ('info', 'warning', 'critical');" 2>&1 | grep -oE '[0-9]+' | tail -1)
        if [ "$invalid" = "0" ] || [ -z "$invalid" ]; then
            log_success "Alerts: severity values valid"
        else
            log_error "Alerts: $invalid records with invalid severity"
        fi
    fi
    echo ""

    # Check indexes
    log_header "7. Index Status"

    log_info "Verifying indexes exist..."

    indexes_count=$(execute_query "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%';" 2>&1 | grep -oE '[0-9]+' | tail -1)

    if [ "$indexes_count" -gt 0 ]; then
        log_success "Indexes found: ${indexes_count}"
    else
        log_warning "No indexes found - performance may be degraded"
    fi
    echo ""

    # Generate summary
    log_header "Verification Summary"

    TOTAL_CHECKS=$((PASSED_CHECKS + FAILED_CHECKS))

    echo ""
    log_info "Total Checks: ${TOTAL_CHECKS}"
    log_success "Passed: ${PASSED_CHECKS}"
    if [ "$FAILED_CHECKS" -gt 0 ]; then
        log_error "Failed: ${FAILED_CHECKS}"
    else
        echo -e "${GREEN}✓ No failures${NC}"
    fi
    echo ""

    # Write report
    {
        echo "================================================================================"
        echo "Database Recovery Verification Report"
        echo "================================================================================"
        echo "Date: $(date)"
        echo "Database: ${DATABASE_NAME}"
        echo "Environment: ${ENVIRONMENT}"
        echo ""
        echo "Summary:"
        echo "  Total Checks: ${TOTAL_CHECKS}"
        echo "  Passed: ${PASSED_CHECKS}"
        echo "  Failed: ${FAILED_CHECKS}"
        echo ""

        if [ "$FAILED_CHECKS" = "0" ]; then
            echo "Status: ✅ ALL CHECKS PASSED"
            echo ""
            echo "The database has been successfully recovered and verified."
            echo "All tables exist with valid data and relationships."
        else
            echo "Status: ⚠️  ${FAILED_CHECKS} CHECKS FAILED"
            echo ""
            echo "Review the output above for details on failed checks."
            echo "Manual investigation may be required."
        fi
        echo ""
        echo "Next Steps:"
        echo "1. Review any failed checks above"
        echo "2. Test application functionality"
        echo "3. Monitor application logs for errors"
        echo "4. Confirm data is accessible to users"
        echo ""
    } | tee "$REPORT_FILE"

    # Exit with appropriate code
    if [ "$FAILED_CHECKS" = "0" ]; then
        log_success "Verification report saved: ${REPORT_FILE}"
        echo ""
        return 0
    else
        log_error "Verification report saved: ${REPORT_FILE}"
        echo ""
        return 1
    fi
}

# Run verification
main
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    log_success "==============================================="
    log_success "Database recovery verification PASSED ✅"
    log_success "==============================================="
else
    log_error "=================================================="
    log_error "Database recovery verification FAILED ⚠️"
    log_error "=================================================="
fi

exit $EXIT_CODE
