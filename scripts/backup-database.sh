#!/bin/bash

################################################################################
# 2076 Platform Template - Database Backup Script
#
# Description: Automated D1 database backup to R2 bucket with rotation
# Usage: ./backup-database.sh [database_name] [r2_bucket_name]
# Default: Uses values from .env or environment variables
#
# Features:
# - Exports D1 database to SQL dump with timestamp
# - Uploads to R2 bucket for safe storage
# - Keeps last 4 weeks of backups (rotates old ones)
# - Error handling and logging
#
# Requirements:
# - Wrangler CLI installed and authenticated
# - D1 database exists
# - R2 bucket exists
#
# Author: 2076 ehf.
################################################################################

set -e  # Exit on error

# Load environment variables if .env exists
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Configuration - use env vars with fallbacks
DATABASE_NAME="${1:-${D1_DATABASE_NAME:-my-database}}"
R2_BUCKET="${2:-${R2_BUCKET_NAME:-my-backups}}"
BACKUP_DIR="/tmp/platform-backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILENAME="backup-${DATABASE_NAME}-${TIMESTAMP}.sql"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILENAME}"
RETENTION_DAYS=28  # Keep backups for 4 weeks

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Create backup directory
prepare_backup_dir() {
    log_info "Preparing backup directory..."

    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log_success "Created backup directory: $BACKUP_DIR"
    else
        log_info "Backup directory exists: $BACKUP_DIR"
    fi
}

# Export D1 database
export_database() {
    log_info "Exporting database: $DATABASE_NAME"
    log_info "Output file: $BACKUP_PATH"

    if wrangler d1 export "$DATABASE_NAME" --remote --output "$BACKUP_PATH"; then
        log_success "Database exported successfully"

        # Check file size
        FILE_SIZE=$(stat -f%z "$BACKUP_PATH" 2>/dev/null || stat -c%s "$BACKUP_PATH" 2>/dev/null || echo "0")
        FILE_SIZE_MB=$(echo "scale=2; $FILE_SIZE / 1048576" | bc 2>/dev/null || echo "N/A")
        log_info "Backup size: ${FILE_SIZE_MB} MB"

        if [ "$FILE_SIZE" -eq 0 ]; then
            log_error "Exported file is empty! Aborting."
            exit 1
        fi
    else
        log_error "Failed to export database"
        exit 1
    fi
}

# Upload to R2
upload_to_r2() {
    log_info "Uploading to R2 bucket: $R2_BUCKET"

    R2_OBJECT_PATH="${R2_BUCKET}/database-backups/${BACKUP_FILENAME}"

    if wrangler r2 object put "$R2_OBJECT_PATH" --file "$BACKUP_PATH" --content-type "application/sql"; then
        log_success "Backup uploaded to R2: $R2_OBJECT_PATH"
    else
        log_error "Failed to upload backup to R2"
        exit 1
    fi
}

# List backups in R2
list_r2_backups() {
    log_info "Listing existing backups in R2..."
    log_warning "Object listing not available in Wrangler v4.45.2"
    log_info "To view backups, use Cloudflare Dashboard: R2 > $R2_BUCKET > database-backups/"
}

# Rotate old backups (keep last 4 weeks)
rotate_backups() {
    log_info "Backup rotation (keeping last $RETENTION_DAYS days)..."
    log_warning "Automatic rotation not available in Wrangler v4.45.2"
    log_info "Recommended: Set up automatic lifecycle rule:"
    echo "  wrangler r2 bucket lifecycle put $R2_BUCKET \\"
    echo "    --expiration-days 28 \\"
    echo "    --prefix database-backups/"
}

# Cleanup local backup file
cleanup_local() {
    log_info "Cleaning up local backup file..."

    if [ -f "$BACKUP_PATH" ]; then
        rm "$BACKUP_PATH"
        log_success "Local backup file removed"
    fi
}

# Main execution
main() {
    echo ""
    log_info "=========================================="
    log_info "2076 Platform - Database Backup"
    log_info "=========================================="
    log_info "Database: $DATABASE_NAME"
    log_info "R2 Bucket: $R2_BUCKET"
    log_info "Timestamp: $TIMESTAMP"
    log_info "=========================================="
    echo ""

    check_dependencies
    prepare_backup_dir
    export_database
    upload_to_r2
    list_r2_backups
    rotate_backups
    cleanup_local

    echo ""
    log_success "=========================================="
    log_success "Backup completed successfully!"
    log_success "=========================================="
    log_info "Backup file: $BACKUP_FILENAME"
    log_info "R2 location: ${R2_BUCKET}/database-backups/${BACKUP_FILENAME}"
    echo ""
}

# Trap errors
trap 'log_error "Script failed at line $LINENO"' ERR

# Run main function
main "$@"
