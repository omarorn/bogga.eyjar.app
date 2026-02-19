---
name: db-backup
description: Create timestamped backup of D1 database
command: /db-backup
---

# Database Backup

Create a timestamped backup of the D1 database.

## Steps

1. Create backup:
```bash
npx wrangler d1 export {{D1_DATABASE_NAME}} --remote --output=backup-$(date +%Y%m%d-%H%M%S).sql
```

2. Show backup info:
   - File size
   - Record counts by table
   - Timestamp

3. Optional: Upload to R2 for long-term storage:
```bash
npx wrangler r2 object put {{R2_BUCKET_NAME}}/backups/backup-$(date +%Y%m%d).sql --file=backup-*.sql
```

4. Show restore instructions:
```bash
# To restore from backup:
npx wrangler d1 execute {{D1_DATABASE_NAME}} --remote --file=backup-YYYYMMDD.sql
```

## Notes
- Always backup before destructive operations
- Keep at least 7 days of backups
- Test restore periodically
