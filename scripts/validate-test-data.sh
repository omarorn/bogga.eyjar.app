#!/bin/bash

# Validate test data SQL script against actual D1 database schema
# Usage: ./scripts/validate-test-data.sh [sql-file] [database-name]
# Example: ./scripts/validate-test-data.sh tests/setup-test-data.sql litla-gamaleigan-db

set -e

SQL_FILE="${1:-tests/setup-test-data.sql}"
DB_NAME="${2:-litla-gamaleigan-db}"

if [ ! -f "$SQL_FILE" ]; then
  echo "❌ Error: SQL file not found: $SQL_FILE"
  exit 1
fi

echo "🔍 Validating $SQL_FILE against $DB_NAME schema..."
echo ""

# Extract table names from INSERT statements
TABLES=$(grep -oP '(?<=INSERT.*INTO\s)\w+' "$SQL_FILE" | sort -u)

ERRORS=0
WARNINGS=0

for TABLE in $TABLES; do
  echo "📋 Checking table: $TABLE"

  # Get actual schema
  SCHEMA=$(npx wrangler d1 execute "$DB_NAME" --local --command "PRAGMA table_info($TABLE)" 2>&1)

  if echo "$SCHEMA" | grep -q "no such table"; then
    echo "  ❌ ERROR: Table '$TABLE' does not exist in database"
    ((ERRORS++))
    continue
  fi

  # Extract column names from schema
  ACTUAL_COLUMNS=$(echo "$SCHEMA" | grep -oP '(?<="name": ")[^"]+' | tr '\n' ' ')

  # Extract column names from SQL file for this table
  SQL_COLUMNS=$(grep -A 20 "INSERT.*INTO $TABLE" "$SQL_FILE" | \
                grep -oP '(?<=\(|\,)\s*\w+(?=\,|\))' | \
                tr -d ' ' | \
                head -20 | \
                tr '\n' ' ')

  echo "  📝 Actual columns: $ACTUAL_COLUMNS"
  echo "  📄 SQL columns:    $SQL_COLUMNS"

  # Check for column mismatches
  for COL in $SQL_COLUMNS; do
    if ! echo "$ACTUAL_COLUMNS" | grep -qw "$COL"; then
      echo "  ⚠️  WARNING: Column '$COL' in SQL not found in table schema"
      ((WARNINGS++))
    fi
  done

  # Check CHECK constraints
  CONSTRAINTS=$(npx wrangler d1 execute "$DB_NAME" --local \
    --command "SELECT sql FROM sqlite_master WHERE name='$TABLE'" 2>&1 | \
    grep -oP 'CHECK\s*\([^)]+\)' || true)

  if [ -n "$CONSTRAINTS" ]; then
    echo "  🔒 CHECK constraints found:"
    echo "$CONSTRAINTS" | sed 's/^/     /'
  fi

  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary:"
echo "  Tables checked: $(echo "$TABLES" | wc -w)"
echo "  ❌ Errors: $ERRORS"
echo "  ⚠️  Warnings: $WARNINGS"
echo ""

if [ $ERRORS -gt 0 ]; then
  echo "❌ Validation FAILED - fix errors before using this SQL file"
  exit 1
elif [ $WARNINGS -gt 0 ]; then
  echo "⚠️  Validation passed with warnings - review and update SQL file"
  exit 0
else
  echo "✅ Validation PASSED - SQL file matches database schema"
  exit 0
fi
