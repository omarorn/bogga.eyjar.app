# Database Backup & Recovery Testing - Quick Start Guide

**Last Updated:** January 2, 2026
**Status:** Ready for Testing
**Test Script:** `scripts/test-backup-recovery.sh`

---

## Quick Start

### Run All Tests (Local Database)

```bash
# From project root
./scripts/test-backup-recovery.sh local
```

**What it tests:**
- ✅ Backup script exists and is executable
- ✅ Backup file creation from local database
- ✅ Backup file size and integrity
- ✅ SQL syntax validation
- ✅ Restore to test database
- ✅ Table structure verification (21 tables)
- ✅ Data integrity (row counts)
- ✅ Foreign key constraints
- ✅ Database indexes
- ✅ Restore script exists and is executable

**Expected Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Litla Gámaleigan Database Backup & Recovery Testing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Phase 1] Preparing Test Environment
[Phase 2] Testing Backup Script
[Phase 3] Creating Local Database Backup
[Phase 4] Validating Backup SQL Syntax
[Phase 5] Creating Test Database
[Phase 6] Restoring Backup to Test Database
[Phase 7] Verifying Table Structure
[Phase 8] Verifying Data Integrity
[Phase 9] Testing Restore Script
[Phase 10] Verifying Foreign Key Constraints
[Phase 11] Verifying Database Indexes
[Phase 12] Generating Test Report

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ALL TESTS PASSED (15/15)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Test Report

After running tests, view detailed report:

```bash
# Report location
ls -lh /tmp/litla-test/test-report-*.txt

# View latest report
cat /tmp/litla-test/test-report-*.txt | tail -50
```

**Report includes:**
- Test execution date and time
- Total tests run and pass rate
- Detailed phase-by-phase results
- Backup file details (size, statements)
- Database verification results
- Recommendations and next steps

---

## Manual Testing Steps

### 1. Test Backup Creation

```bash
# Test local database backup
cd packages/workers
wrangler d1 export litla-gamaleigan-db --local --output /tmp/test-backup.sql

# Verify backup created
ls -lh /tmp/test-backup.sql

# Should be >100KB with SQL statements
head -20 /tmp/test-backup.sql
```

### 2. Test Backup Script

```bash
# Run full backup script (local database)
./scripts/backup-database.sh litla-gamaleigan-db litla-backups

# Check output for:
# - "Database exported successfully"
# - File size in MB
# - R2 upload status (requires auth)
```

### 3. Test Restore to Test Database

```bash
# Create test backup first
wrangler d1 export litla-gamaleigan-db --local --output /tmp/test-restore.sql

# Restore to local database
wrangler d1 execute litla-gamaleigan-db --local --file /tmp/test-restore.sql

# Verify tables restored
wrangler d1 execute litla-gamaleigan-db --local --command "SELECT name FROM sqlite_master WHERE type='table';"
```

### 4. Verify Data Integrity

```bash
# Check row counts
wrangler d1 execute litla-gamaleigan-db --local --command "SELECT COUNT(*) FROM containers;"
wrangler d1 execute litla-gamaleigan-db --local --command "SELECT COUNT(*) FROM customers;"
wrangler d1 execute litla-gamaleigan-db --local --command "SELECT COUNT(*) FROM orders;"

# Verify foreign keys
wrangler d1 execute litla-gamaleigan-db --local --command "PRAGMA foreign_key_check;"

# Should return empty (no violations)
```

---

## Common Issues & Solutions

### Issue: "Wrangler CLI not found"

**Solution:**
```bash
npm install -g wrangler
wrangler --version
```

### Issue: "Authentication error [code: 10000]"

**Solution:**
```bash
# Login to Cloudflare
wrangler login

# Or set API token
export CLOUDFLARE_API_TOKEN="your-token-here"
```

### Issue: "Backup file is empty"

**Cause:** Local database has no data or export failed

**Solution:**
```bash
# Check if local database has data
wrangler d1 execute litla-gamaleigan-db --local --command "SELECT COUNT(*) FROM containers;"

# If 0 rows, local database is empty (expected for fresh install)
# Use remote database instead:
wrangler d1 export litla-gamaleigan-db --remote --output /tmp/test-backup.sql
```

### Issue: "Failed to import backup to database"

**Cause:** SQL syntax error or permissions issue

**Solution:**
```bash
# Validate SQL file
file /tmp/test-backup.sql  # Should show "SQL data"

# Check first few lines
head -20 /tmp/test-backup.sql

# Ensure local database is writable
# Local D1 databases are stored in: .wrangler/state/v3/d1/
```

### Issue: "Table counts are wrong after restore"

**Cause:** Partial import or constraint violations

**Solution:**
```bash
# Check import logs for errors
# Re-run import with verbose output:
wrangler d1 execute litla-gamaleigan-db --local --file /tmp/test-backup.sql 2>&1 | tee import.log

# Review import.log for errors
grep -i error import.log
```

---

## Test Checklist

Use this checklist for manual testing:

```
Backup & Recovery Testing Checklist
====================================
Date: ________________
Tester: _______________

□ Prerequisites
  □ Wrangler CLI installed (wrangler --version)
  □ Authenticated to Cloudflare (wrangler whoami)
  □ Local database has data (or use remote)
  □ Sufficient disk space (/tmp has >100MB free)

□ Backup Creation
  □ Run automated test script (./scripts/test-backup-recovery.sh)
  □ Backup file created in /tmp/litla-test/
  □ Backup file size >100KB
  □ SQL syntax valid (head command shows SQL)

□ Restore Testing
  □ Test database import successful
  □ No SQL errors during import
  □ All 21 tables restored
  □ Row counts reasonable

□ Data Integrity
  □ Container table has data
  □ Customer table has data
  □ Order table has data
  □ Foreign key check passes (PRAGMA foreign_key_check)
  □ Indexes exist (SELECT * FROM sqlite_master WHERE type='index')

□ Script Verification
  □ backup-database.sh exists and is executable
  □ restore-database.sh exists and is executable
  □ test-backup-recovery.sh runs without errors
  □ Test report generated in /tmp/litla-test/

□ Documentation
  □ Test results documented in DATABASE_RECOVERY.md
  □ "Last Tested" date updated
  □ Any issues documented
  □ Next test scheduled

Signed: ______________________ Date: ________
```

---

## Next Steps After Testing

### If All Tests Pass

1. ✅ Update `docs/DATABASE_RECOVERY.md` with "Last Tested" date
2. ✅ Document test results in Testing History section
3. ✅ Schedule next monthly test (1st of next month)
4. ✅ Consider testing remote database backup (requires permissions)

### If Tests Fail

1. ⚠️ Review test report for specific failures
2. ⚠️ Check error messages and logs
3. ⚠️ Fix issues in backup/restore scripts
4. ⚠️ Re-run tests until all pass
5. ⚠️ Document fixes in git commit message

---

## Automated Testing in CI/CD

Add to CI/CD pipeline (future enhancement):

```yaml
# .github/workflows/test-backup-recovery.yml
name: Database Backup & Recovery Tests

on:
  schedule:
    - cron: '0 2 1 * *'  # 1st of each month at 2 AM
  workflow_dispatch:  # Manual trigger

jobs:
  test-backup-recovery:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Wrangler
        run: npm install -g wrangler
      - name: Authenticate
        run: echo "${{ secrets.CLOUDFLARE_API_TOKEN }}" | wrangler login
      - name: Run Tests
        run: ./scripts/test-backup-recovery.sh local
      - name: Upload Test Report
        uses: actions/upload-artifact@v3
        with:
          name: test-report
          path: /tmp/litla-test/test-report-*.txt
```

---

## Reference Links

- **Main Documentation:** `docs/DATABASE_RECOVERY.md`
- **Backup Script:** `scripts/backup-database.sh`
- **Restore Script:** `scripts/restore-database.sh`
- **Test Script:** `scripts/test-backup-recovery.sh`
- **Wrangler D1 Docs:** https://developers.cloudflare.com/d1/
- **Cloudflare Dashboard:** https://dash.cloudflare.com

---

**Questions or Issues?**

Contact: Ómar Örn Magnússon (omar@vertis.is)
