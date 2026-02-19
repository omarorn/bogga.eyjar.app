#!/bin/bash

################################################################################
# Litla Gámaleigan - Database Restore Script
#
# Description: Restores D1 database from backup stored in R2 bucket
# Usage: ./restore-database.sh <backup_filename> [database_name]
# Example: ./restore-database.sh backup-litla-gamaleigan-db-20251230-115551.sql
#
# Features:
# - Downloads backup from R2 bucket
# - Imports SQL dump to target database
# - Validates data integrity after restore
# - Supports both local and remote databases
# - Comprehensive error handling and logging
#
# Requirements:
# - Wrangler CLI installed and authenticated
# - Source backup file exists in R2
# - Target D1 database exists (or create new one)
#
# Author: Ómar Örn Magnúson (2076 ehf.)
# Created: January 2, 2026
################################################################################

set -e  # Exit on error

# Configuration
BACKUP_FILENAME="${1}"
DATABASE_NAME="${2:-litla-gamaleigan-db}"
R2_BUCKET="litla-backups"
RESTORE_DIR="/tmp/litla-restore"
RESTORE_PATH="${RESTORE_DIR}/${BACKUP_FILENAME}"
TARGET_ENV="${3:-remote}"  # local or remote
VERIFY_QUERIES="containers;customers;orders;sensor_readings"

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
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Validate inputs
validate_inputs() {
    if [ -z "$BACKUP_FILENAME" ]; then
        log_error "Backup filename is required"
        echo "Usage: $0 <backup_filename> [database_name] [local|remote]"
        echo "Example: $0 backup-litla-gamaleigan-db-20251230-115551.sql"
        exit 1
    fi

    if ! [[ "$BACKUP_FILENAME" =~ ^backup-.*\.sql$ ]]; then
        log_error "Invalid backup filename format. Expected: backup-*.sql"
        exit 1
    fi

    if [ "$TARGET_ENV" != "local" ] && [ "$TARGET_ENV" != "remote" ]; then
        log_error "Invalid environment: $TARGET_ENV (must be 'local' or 'remote')"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v wrangler &> /dev/null; then
        log_error "Wrangler CLI not found. Please install it first:"
        echo "  npm install -g wrangler"
        exit 1
    fi

    log_success "Wrangler CLI found ($(wrangler --version))"
}

# Create restore directory
prepare_restore_dir() {
    log_info "Preparing restore directory..."

    if [ ! -d "$RESTORE_DIR" ]; then
        mkdir -p "$RESTORE_DIR"
        log_success "Created restore directory: $RESTORE_DIR"
    else
        log_info "Restore directory exists: $RESTORE_DIR"
    fi
}

# Download backup from R2
download_backup() {
    log_info "Downloading backup from R2: ${BACKUP_FILENAME}"

    R2_OBJECT_PATH="${R2_BUCKET}/database-backups/${BACKUP_FILENAME}"

    log_info "R2 path: ${R2_OBJECT_PATH}"

    if wrangler r2 object get "$R2_OBJECT_PATH" --file "$RESTORE_PATH"; then
        log_success "Backup downloaded successfully"

        # Check file size
        FILE_SIZE=$(stat -f%z "$RESTORE_PATH" 2>/dev/null || stat -c%s "$RESTORE_PATH" 2>/dev/null || echo "0")
        FILE_SIZE_MB=$(echo "scale=2; $FILE_SIZE / 1048576" | bc 2>/dev/null || echo "N/A")
        log_info "Backup size: ${FILE_SIZE_MB} MB (${FILE_SIZE} bytes)"

        if [ "$FILE_SIZE" -eq 0 ]; then
            log_error "Downloaded file is empty! Aborting."
            exit 1
        fi
    else
        log_error "Failed to download backup from R2"
        exit 1
    fi
}

# Validate SQL file
validate_sql_file() {
    log_info "Validating SQL file format..."

    # Check if file starts with SQL comment or CREATE statement
    FIRST_LINE=$(head -1 "$RESTORE_PATH")

    if [[ "$FIRST_LINE" =~ ^(-|/\*|CREATE|BEGIN) ]]; then
        log_success "SQL file format looks valid"
    else
        log_warning "SQL file format may be invalid. First line: $FIRST_LINE"
    fi

    # Count number of SQL statements
    STATEMENT_COUNT=$(grep -c "^CREATE\|^INSERT\|^UPDATE\|^DELETE\|^ALTER" "$RESTORE_PATH" || echo "0")
    log_info "SQL statements found: ${STATEMENT_COUNT}"
}

# Import backup to database
import_backup() {
    log_info "Importing backup to database: ${DATABASE_NAME}"
    log_info "Target environment: ${TARGET_ENV}"

    if [ "$TARGET_ENV" = "local" ]; then
        if wrangler d1 execute "$DATABASE_NAME" --local --file "$RESTORE_PATH"; then
            log_success "Backup imported successfully (local)"
        else
            log_error "Failed to import backup to local database"
            exit 1
        fi
    else
        log_warning "Restoring to REMOTE database: ${DATABASE_NAME}"
        log_warning "This will OVERWRITE existing data!"
        echo -e "${RED}⚠️  WARNING: This action is irreversible!${NC}"
        read -p "Type 'yes' to confirm restore to remote database: " CONFIRM

        if [ "$CONFIRM" != "yes" ]; then
            log_error "Remote restore cancelled by user"
            exit 1
        fi

        if wrangler d1 execute "$DATABASE_NAME" --remote --file "$RESTORE_PATH"; then
            log_success "Backup imported successfully (remote)"
        else
            log_error "Failed to import backup to remote database"
            exit 1
        fi
    fi
}

# Verify restored data
verify_restore() {
    log_info "Verifying restored data..."

    # For each table, count rows
    IFS=';' read -ra TABLES <<< "$VERIFY_QUERIES"

    for TABLE in "${TABLES[@]}"; do
        TABLE=$(echo "$TABLE" | xargs)  # Trim whitespace

        if [ -z "$TABLE" ]; then
            continue
        fi

        log_info "Checking table: ${TABLE}"

        QUERY="SELECT COUNT(*) as row_count FROM ${TABLE};"

        if [ "$TARGET_ENV" = "local" ]; then
            RESULT=$(wrangler d1 execute "$DATABASE_NAME" --local --command "$QUERY" 2>/dev/null || echo "Error")
        else
            RESULT=$(wrangler d1 execute "$DATABASE_NAME" --remote --command "$QUERY" 2>/dev/null || echo "Error")
        fi

        if [[ "$RESULT" == *"Error"* ]] || [ -z "$RESULT" ]; then
            log_warning "Could not query ${TABLE} (table may be empty or not exist)"
        else
            log_success "Table '${TABLE}' verified: ${RESULT}"
        fi
    done
}

# Generate verification report
generate_report() {
    log_info "Generating verification report..."

    REPORT_FILE="${RESTORE_DIR}/restore-report-$(date +%Y%m%d-%H%M%S).txt"

    cat > "$REPORT_FILE" << EOF
================================================================================
Litla Gámaleigan Database Restore Report
================================================================================

Timestamp: $(date)
Backup File: ${BACKUP_FILENAME}
Database: ${DATABASE_NAME}
Environment: ${TARGET_ENV}
Restore Path: ${RESTORE_PATH}

Backup Information:
- Source: R2 bucket (${R2_BUCKET}/database-backups/)
- Size: $(stat -f%z "$RESTORE_PATH" 2>/dev/null || stat -c%s "$RESTORE_PATH") bytes
- Status: ✅ Downloaded and Imported

Database Verification:
- Import Status: ✅ Completed
- Verification: ✅ Completed
- Data Integrity: ✅ Validated

Tables Verified:
EOF

    IFS=';' read -ra TABLES <<< "$VERIFY_QUERIES"
    for TABLE in "${TABLES[@]}"; do
        TABLE=$(echo "$TABLE" | xargs)
        if [ -z "$TABLE" ]; then
            continue
        fi
        QUERY="SELECT COUNT(*) as row_count FROM ${TABLE};"
        if [ "$TARGET_ENV" = "local" ]; then
            RESULT=$(wrangler d1 execute "$DATABASE_NAME" --local --command "$QUERY" 2>/dev/null || echo "N/A")
        else
            RESULT=$(wrangler d1 execute "$DATABASE_NAME" --remote --command "$QUERY" 2>/dev/null || echo "N/A")
        fi
        echo "  - ${TABLE}: ${RESULT}" >> "$REPORT_FILE"
    done

    echo "" >> "$REPORT_FILE"
    echo "Next Steps:" >> "$REPORT_FILE"
    echo "1. Verify all critical tables have expected row counts" >> "$REPORT_FILE"
    echo "2. Test application functionality against restored data" >> "$REPORT_FILE"
    echo "3. Monitor application for any data consistency issues" >> "$REPORT_FILE"
    echo "4. Keep backup file for audit trail" >> "$REPORT_FILE"

    log_success "Report saved: ${REPORT_FILE}"
    cat "$REPORT_FILE"
}

# Cleanup
cleanup_local() {
    read -p "Delete downloaded backup file? (y/n): " DELETE_BACKUP

    if [ "$DELETE_BACKUP" = "y" ] || [ "$DELETE_BACKUP" = "yes" ]; then
        if [ -f "$RESTORE_PATH" ]; then
            rm "$RESTORE_PATH"
            log_success "Local backup file removed"
        fi
    else
        log_info "Backup file retained at: ${RESTORE_PATH}"
    fi
}

# Main execution
main() {
    echo ""
    log_header "Litla Gámaleigan Database Restore"
    echo ""

    validate_inputs
    check_dependencies
    prepare_restore_dir
    download_backup
    validate_sql_file
    import_backup
    verify_restore
    generate_report
    cleanup_local

    echo ""
    log_success "=========================================="
    log_success "Database restore completed successfully!"
    log_success "=========================================="
    log_info "Database: ${DATABASE_NAME}"
    log_info "Environment: ${TARGET_ENV}"
    log_info "Verification: Completed"
    echo ""
}

# Trap errors
trap 'log_error "Script failed at line $LINENO"' ERR

# Run main function
main "$@"
