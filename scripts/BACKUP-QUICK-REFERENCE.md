# Database Backup - Quick Reference Card

## Run Backup Now

```bash
./scripts/backup-database.sh
```

## View Backups

**Cloudflare Dashboard:**
https://dash.cloudflare.com/ → R2 → litla-backups → database-backups/

## Restore from Backup

```bash
# 1. Download backup from R2
wrangler r2 object get litla-backups/database-backups/backup-TIMESTAMP.sql \
  --file /tmp/restore.sql

# 2. Import to database
wrangler d1 execute litla-gamaleigan-db --remote --file /tmp/restore.sql
```

## Check Lifecycle Rules

```bash
wrangler r2 bucket lifecycle list litla-backups
```

## Scheduled Backups (Weekly)

Add to crontab:
```bash
0 2 * * 0 /path/to/scripts/backup-database.sh >> /var/log/litla-backup.log 2>&1
```

## Backup Details

- **Database:** litla-gamaleigan-db
- **R2 Bucket:** litla-backups
- **Path:** database-backups/
- **Retention:** 28 days (automatic)
- **Format:** SQL dump with timestamp
- **Naming:** backup-litla-gamaleigan-db-YYYYMMDD-HHMMSS.sql

## Status

✅ **Fully Configured and Tested**
- Backup script: Working
- R2 upload: Working
- Lifecycle rule: Active (28-day retention)
- Documentation: Complete

## Support

**Documentation:**
- Full Guide: `/scripts/README-backup.md`
- Cron Examples: `/scripts/cron-backup-example.txt`

**Developer:** Ómar Örn Magnúson (omar@vertis.is)
