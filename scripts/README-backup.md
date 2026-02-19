# Database Backup Script

## Overview

Automated script to backup Litla Gámaleigan's D1 database to R2 bucket for disaster recovery and data archival.

## Features

- **Automated Exports**: Uses Wrangler CLI to export D1 database to SQL dump
- **Cloud Storage**: Uploads backups to R2 bucket for safe, redundant storage
- **Timestamped Files**: Each backup includes timestamp for easy identification
- **Error Handling**: Comprehensive error checking and logging
- **Cleanup**: Removes local files after successful upload

## Usage

### Basic Usage (Default Settings)

```bash
./scripts/backup-database.sh
```

This will backup `litla-gamaleigan-db` to `litla-backups` bucket.

### Custom Database or Bucket

```bash
./scripts/backup-database.sh [database_name] [r2_bucket_name]
```

**Example:**
```bash
./scripts/backup-database.sh my-database my-bucket
```

## Requirements

1. **Wrangler CLI** installed and authenticated:
   ```bash
   npm install -g wrangler
   wrangler login
   ```

2. **D1 Database** must exist:
   ```bash
   wrangler d1 list
   ```

3. **R2 Bucket** must exist:
   ```bash
   wrangler r2 bucket list
   ```

## Output

Backups are stored in R2 with the following structure:

```
litla-backups/
└── database-backups/
    ├── backup-litla-gamaleigan-db-20251230-115551.sql
    ├── backup-litla-gamaleigan-db-20251229-120000.sql
    └── backup-litla-gamaleigan-db-20251228-120000.sql
```

## Backup Rotation

### Automatic Rotation (Recommended)

Set up R2 lifecycle rules to automatically delete backups older than 28 days:

```bash
wrangler r2 bucket lifecycle put litla-backups \
  --expiration-days 28 \
  --prefix database-backups/
```

### Manual Rotation

1. **Via Cloudflare Dashboard:**
   - Go to R2 > litla-backups > database-backups/
   - Delete old backup files manually

2. **Via Wrangler:**
   ```bash
   wrangler r2 object delete litla-backups/database-backups/old-backup.sql
   ```

## Scheduled Backups

### Using Cron (Linux/macOS)

Add to crontab to run weekly backups every Sunday at 2 AM:

```bash
crontab -e
```

Add this line:
```cron
0 2 * * 0 /path/to/Litla_Gamaleigan/scripts/backup-database.sh >> /var/log/litla-backup.log 2>&1
```

### Using GitHub Actions

See `.github/workflows/backup-database.yml` for CI/CD automation.

### Using Cloudflare Workers

Deploy a Worker with Cron Trigger to run backups on schedule (requires Worker to execute shell commands via external API).

## Verification

After running the backup, verify it was uploaded:

1. **Via Cloudflare Dashboard:**
   - Navigate to R2 > litla-backups
   - Open database-backups/ folder
   - Verify latest backup file exists

2. **Download and Test:**
   ```bash
   wrangler r2 object get litla-backups/database-backups/backup-litla-gamaleigan-db-TIMESTAMP.sql \
     --file /tmp/test-backup.sql

   # Verify SQL file is valid
   head -20 /tmp/test-backup.sql
   ```

## Troubleshooting

### Error: "Wrangler CLI not found"

**Solution:** Install Wrangler globally:
```bash
npm install -g wrangler
```

### Error: "Failed to export database"

**Possible Causes:**
- Database doesn't exist (check `wrangler d1 list`)
- Not authenticated (run `wrangler login`)
- Network connectivity issues

### Error: "Failed to upload backup to R2"

**Possible Causes:**
- Bucket doesn't exist (check `wrangler r2 bucket list`)
- Insufficient permissions
- Network connectivity issues

### Backup File is Empty (0 bytes)

**Cause:** Database has no data

**Solution:** This is expected for empty databases. The backup will still contain the schema.

## Recovery

To restore from a backup:

1. **Download backup from R2:**
   ```bash
   wrangler r2 object get litla-backups/database-backups/backup-TIMESTAMP.sql \
     --file /tmp/restore.sql
   ```

2. **Create new database (if needed):**
   ```bash
   wrangler d1 create litla-gamaleigan-db-restored
   ```

3. **Import SQL dump:**
   ```bash
   wrangler d1 execute litla-gamaleigan-db-restored \
     --remote \
     --file /tmp/restore.sql
   ```

4. **Verify data:**
   ```bash
   wrangler d1 execute litla-gamaleigan-db-restored \
     --remote \
     --command "SELECT COUNT(*) FROM gamar;"
   ```

## Security Notes

- Backups contain sensitive data (customer info, IoT data)
- R2 bucket should have private access only
- Consider encrypting backups for extra security
- Regularly test backup restoration process
- Keep backup retention period compliant with data regulations

## Support

For issues or questions:
- **Developer:** Ómar Örn Magnúson (omar@vertis.is)
- **Project Owner:** Gunnar Walsh (Litla Gámaleigan ehf.)
- **Documentation:** See /docs/DEPLOYMENT_CHECKLIST.md

## License

Copyright © 2025 Litla Gámaleigan ehf. All rights reserved.
