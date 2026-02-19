#!/bin/bash

################################################################################
# Litla Gámaleigan - Quick Backup Recovery Verification
#
# Description: Quick verification of backup and recovery infrastructure
# Usage: ./verify-backup-recovery.sh
#
# Features:
# - Verifies all scripts exist and are executable
# - Checks documentation is up to date
# - Validates configuration
# - Provides quick health check
#
# Author: Ómar Örn Magnússon (2076 ehf.)
# Created: January 3, 2026
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0
CHECKS_TOTAL=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
}

log_warning() {
    echo -e "${YELLOW}[⚠ WARN]${NC} $1"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
}

log_error() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
}

log_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check script existence and permissions
check_scripts() {
    log_header "Phase 1: Verifying Scripts"

    if [ -f "scripts/backup-database.sh" ]; then
        log_success "Backup script exists"
    else
        log_error "Backup script missing: scripts/backup-database.sh"
    fi

    if [ -x "scripts/backup-database.sh" ]; then
        log_success "Backup script is executable"
    else
        log_warning "Backup script not executable (run: chmod +x scripts/backup-database.sh)"
    fi

    if [ -f "scripts/restore-database.sh" ]; then
        log_success "Restore script exists"
    else
        log_error "Restore script missing: scripts/restore-database.sh"
    fi

    if [ -x "scripts/restore-database.sh" ]; then
        log_success "Restore script is executable"
    else
        log_warning "Restore script not executable (run: chmod +x scripts/restore-database.sh)"
    fi

    if [ -f "scripts/test-backup-recovery.sh" ]; then
        log_success "Test script exists"
    else
        log_error "Test script missing: scripts/test-backup-recovery.sh"
    fi

    if [ -x "scripts/test-backup-recovery.sh" ]; then
        log_success "Test script is executable"
    else
        log_warning "Test script not executable (run: chmod +x scripts/test-backup-recovery.sh)"
    fi
}

# Check documentation
check_documentation() {
    log_header "Phase 2: Verifying Documentation"

    if [ -f "docs/DATABASE_RECOVERY.md" ]; then
        log_success "Recovery documentation exists"

        # Check documentation size (should be comprehensive)
        DOC_LINES=$(wc -l < docs/DATABASE_RECOVERY.md)
        if [ "$DOC_LINES" -gt 500 ]; then
            log_success "Documentation is comprehensive (${DOC_LINES} lines)"
        else
            log_warning "Documentation may be incomplete (${DOC_LINES} lines, expected >500)"
        fi

        # Check last update date
        LAST_UPDATED=$(grep "Last Updated:" docs/DATABASE_RECOVERY.md | head -1)
        log_info "$LAST_UPDATED"

        # Check last tested date
        LAST_TESTED=$(grep "Last Tested:" docs/DATABASE_RECOVERY.md | head -1)
        log_info "$LAST_TESTED"

    else
        log_error "Recovery documentation missing: docs/DATABASE_RECOVERY.md"
    fi

    if [ -f "docs/BACKUP_RECOVERY_TEST_REPORT.md" ]; then
        log_success "Test report exists"
    else
        log_warning "Test report not found (run verification tests)"
    fi
}

# Check Wrangler configuration
check_wrangler() {
    log_header "Phase 3: Verifying Wrangler Configuration"

    if command -v wrangler &> /dev/null; then
        WRANGLER_VERSION=$(wrangler --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_success "Wrangler CLI installed (${WRANGLER_VERSION})"
    else
        log_error "Wrangler CLI not found (install: npm install -g wrangler)"
    fi

    if [ -f "packages/workers/wrangler.toml" ]; then
        log_success "Wrangler config exists"

        # Check D1 database binding
        if grep -q "litla-gamaleigan-db" packages/workers/wrangler.toml; then
            log_success "D1 database configured"
        else
            log_error "D1 database not configured in wrangler.toml"
        fi

        # Check R2 BACKUPS binding
        if grep -q "litla-backups" packages/workers/wrangler.toml; then
            log_success "R2 backup bucket configured"
        else
            log_error "R2 backup bucket not configured in wrangler.toml"
        fi

    else
        log_error "Wrangler config missing: packages/workers/wrangler.toml"
    fi
}

# Check backup directory structure
check_directories() {
    log_header "Phase 4: Verifying Directory Structure"

    # Check if backup directory can be created
    if [ -d "/tmp/litla-backups" ] || mkdir -p /tmp/litla-backups 2>/dev/null; then
        log_success "Backup directory accessible (/tmp/litla-backups)"
    else
        log_warning "Cannot create backup directory (/tmp/litla-backups)"
    fi

    # Check if restore directory can be created
    if [ -d "/tmp/litla-restore" ] || mkdir -p /tmp/litla-restore 2>/dev/null; then
        log_success "Restore directory accessible (/tmp/litla-restore)"
    else
        log_warning "Cannot create restore directory (/tmp/litla-restore)"
    fi

    # Check if test directory can be created
    if [ -d "/tmp/litla-test" ] || mkdir -p /tmp/litla-test 2>/dev/null; then
        log_success "Test directory accessible (/tmp/litla-test)"
    else
        log_warning "Cannot create test directory (/tmp/litla-test)"
    fi
}

# Check script syntax
check_script_syntax() {
    log_header "Phase 5: Verifying Script Syntax"

    # Check backup script syntax
    if bash -n scripts/backup-database.sh 2>/dev/null; then
        log_success "Backup script syntax valid"
    else
        log_error "Backup script has syntax errors"
    fi

    # Check restore script syntax
    if bash -n scripts/restore-database.sh 2>/dev/null; then
        log_success "Restore script syntax valid"
    else
        log_error "Restore script has syntax errors"
    fi

    # Check test script syntax
    if bash -n scripts/test-backup-recovery.sh 2>/dev/null; then
        log_success "Test script syntax valid"
    else
        log_error "Test script has syntax errors"
    fi
}

# Generate summary report
generate_summary() {
    log_header "Verification Summary"

    PASS_RATE=0
    if [ $CHECKS_TOTAL -gt 0 ]; then
        PASS_RATE=$(echo "scale=1; ($CHECKS_PASSED / $CHECKS_TOTAL) * 100" | bc 2>/dev/null || echo "0")
    fi

    echo ""
    echo -e "${BLUE}Total Checks:${NC} ${CHECKS_TOTAL}"
    echo -e "${GREEN}Passed:${NC}       ${CHECKS_PASSED}"
    echo -e "${YELLOW}Warnings:${NC}     ${CHECKS_WARNING}"
    echo -e "${RED}Failed:${NC}       ${CHECKS_FAILED}"
    echo -e "${CYAN}Pass Rate:${NC}    ${PASS_RATE}%"
    echo ""

    if [ $CHECKS_FAILED -eq 0 ]; then
        if [ $CHECKS_WARNING -eq 0 ]; then
            echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
            echo -e "${GREEN}Backup recovery infrastructure is ready!${NC}"
        else
            echo -e "${YELLOW}⚠️  PASSED WITH WARNINGS${NC}"
            echo -e "${YELLOW}Review warnings above and fix minor issues${NC}"
        fi
    else
        echo -e "${RED}❌ SOME CHECKS FAILED${NC}"
        echo -e "${RED}Fix critical issues before using backup/recovery system${NC}"
    fi

    echo ""
    echo "Next Steps:"
    echo "1. Fix any failed checks or warnings"
    echo "2. Run full backup test: cd packages/workers && npx wrangler d1 export litla-gamaleigan-db --remote --output /tmp/test-backup.sql"
    echo "3. Run automated test suite: ./scripts/test-backup-recovery.sh local"
    echo "4. Set R2 lifecycle rule: npx wrangler r2 bucket lifecycle add litla-backups database-backup-retention database-backups/ --expire-days 28 -y"
    echo "5. Review documentation: docs/DATABASE_RECOVERY.md"
    echo ""
}

# Main execution
main() {
    echo ""
    log_header "Litla Gámaleigan Backup Recovery Verification"
    log_info "Quick health check of backup and recovery infrastructure"
    echo ""

    check_scripts
    check_documentation
    check_wrangler
    check_directories
    check_script_syntax
    generate_summary

    # Exit with proper code
    if [ $CHECKS_FAILED -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
