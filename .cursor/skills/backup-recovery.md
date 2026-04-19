---
description: >
  Ensures every production application has a tested backup and recovery strategy.
  Covers database backups (Neon, Supabase, MongoDB), file storage backups (S3, Vercel
  Blob), automated backup schedules, retention policies, and the recovery playbook
  every founder needs when things go wrong. Use when: (1) deploying to production,
  (2) reviewing data protection, (3) setting up automated backups, (4) testing
  recovery procedures, (5) asking "what happens if the database dies?"
globs: ["**/vercel.json", "**/.github/workflows/**", "**/backup**", "**/scripts/*backup*", "**/docker-compose*"]
alwaysApply: false
tags: [product]
---

# Backup & Recovery

## Purpose

Database outages, accidental deletions, and corruption happen. When they do, the difference between "5-minute restore" and "we lost all user data" is whether you have automated backups that have been tested.

**For non-technical founders:** The only rule that matters here is "backup before it matters." When a teacher is running their course platform and their database corrupts on Friday night at 8pm, they need one command to restore — not a 3-hour debugging session.

## Activation

This skill activates when you mention:
- "backup", "restore", "disaster recovery"
- "database backup", "db backup", "pg_dump"
- "data loss", "deleted by mistake", "corruption"
- "RPO", "RTO", "recovery point", "recovery time"
- "point-in-time restore", "snapshot"
- "what happens if the database goes down"

Also activates when:
- Deploying to production for the first time
- Setting up a Neon, Supabase, or any managed database
- Reviewing a production-readiness checklist
- After an incident where data was lost

## Core Concepts

### RPO (Recovery Point Objective)
How much data can you afford to lose? The time between your last backup and the failure.
- **RPO = 0:** Zero data loss — requires continuous replication (expensive)
- **RPO = 1 hour:** Last backup was 1 hour ago — 1 hour of transactions lost
- **RPO = 24 hours:** Daily backups — a full day of transactions lost

### RTO (Recovery Time Objective)
How long to get back online after a failure?
- **RTO < 5 min:** Automated failover + point-in-time restore
- **RTO < 1 hour:** Manual restore from latest backup
- **RTO < 24 hours:** You have backups but need to rebuild

**For TYO community products:** Target RPO ≤ 1 hour, RTO ≤ 1 hour. Most managed databases meet these with their default configurations.

## Database Backup Strategies

### Neon (PostgreSQL) — Built-in Protection

Neon provides automatic backups and point-in-time recovery out of the box:

```sql
-- Neon automatic backups:
-- ✅ Continuous WAL archiving (point-in-time recovery)
-- ✅ Default retention: 7 days
-- ✅ Automatic daily snapshots
-- ✅ Branch-based "undo" (create a branch from a past point)

-- To restore to a specific time:
-- 1. Go to Neon console → Project → Create Branch → "From Point-in-Time"
-- 2. Select the timestamp before the problem
-- 3. Verify data on the branch
-- 4. Promote the branch (swap it with main)
```

**You still need to configure:**
```yaml
# governance.yaml overrides for Neon backup awareness
# Neon default PITR is 7 days. For production, extend:
neon_branch_retention: 14  # days
```

**Neon-specific risks:**
- Branches consume compute; clean up old branches
- PITR depends on WAL retention — if retention expires, you can't restore
- **Always verify a backup is restorable** — a backup you haven't tested is not a backup

### Supabase (PostgreSQL) — Built-in Protection

```bash
# Supabase daily backups (kept for 7 days on Pro, 14 on Team)
# Manual backups via Dashboard → Database → Backups

# Export your database locally for off-site backup:
pg_dump -h db.project.supabase.co -U postgres \
  --no-owner --no-acl \
  your_database > backup_$(date +%Y%m%d_%H%M%S).sql
```

### MongoDB (Atlas) — Continuous Snapshots

```javascript
// Atlas continuous snapshots:
// ✅ Every 6 hours by default (configurable)
// ✅ Point-in-time recovery
// ✅ Daily, weekly, monthly retention tiers

// Manual backup:
// 1. Atlas Console → Clusters → Backup → Snapshots → Take Snapshot
// 2. Name it (e.g. "pre-deploy-20260419")
// 3. Restore from snapshot when needed
```

## Automated Backup Script

For projects on platforms without built-in PITR, or for off-site backup:

```bash
#!/bin/bash
# scripts/backup.sh — Run this daily via cron or GitHub Actions

set -euo pipefail

# Configuration
DB_URL="${DATABASE_URL:?Set DATABASE_URL}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

# PostgreSQL backup
BACKUP_FILE="$BACKUP_DIR/db_$(date +%Y%m%d_%H%M%S).sql.gz"
pg_dump "$DB_URL" | gzip > "$BACKUP_FILE"

# Upload to S3-compatible storage
aws s3 cp "$BACKUP_FILE" "s3://your-backup-bucket/$(basename $BACKUP_FILE)"

# Clean old local backups
find "$BACKUP_DIR" -name "db_*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $BACKUP_FILE"
```

**Run via GitHub Actions (daily at 2am UTC):**
```yaml
# .github/workflows/backup.yml
name: Database Backup
on:
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: neondatabase/action-backup@v1
        with:
          project-id: ${{ secrets.NEON_PROJECT_ID }}
          api-key: ${{ secrets.NEON_API_KEY }}
          retention-days: '30'
```

## Recovery Playbook

### When Things Go Wrong — The First 5 Minutes

```
┌─────────────────────────────────────────┐
│  1. STOP — Don't panic-don't delete     │
│     Don't try to "fix it live"          │
│     Don't delete any existing data      │
├─────────────────────────────────────────┤
│  2. DIAGNOSE — What happened?           │
│     Check Neon/Supabase status page      │
│     Check your monitoring alerts         │
│     Is it corruption, deletion, outage?  │
├─────────────────────────────────────────┤
│  3. ISOLATE — Stop further damage       │
│     Put up maintenance page              │
│     Don't write to the damaged database  │
│     Note the time of the incident        │
├─────────────────────────────────────────┤
│  4. RESTORE — Recover from backup       │
│     Point-in-time recovery (best option) │
│     Or restore latest backup to new DB   │
├─────────────────────────────────────────┤
│  5. VERIFY — Check the restored data     │
│     Does it look right? Count rows.       │
│     Test a few user workflows             │
│     When verified → switch to restored DB │
├─────────────────────────────────────────┤
│  6. NOTIFY — Tell your users            │
│     "We had an issue, it's resolved"     │
│     Be honest, be brief                   │
│     Document what happened (post-mortem)  │
└─────────────────────────────────────────┘
```

### Neon Point-in-Time Recovery (Step-by-Step)

```bash
# 1. Find the incident time
# Check logs for the exact moment data was lost

# 2. Create a recovery branch from 1 minute before the incident
# Neon Console → Create Branch → "From Point-in-Time"
# Time: 2026-04-19T14:23:00Z  (adjust to before the problem)

# 3. Test the recovered branch
NEON_BRANCH_URL="postgresql://..."  # Branch connection string
psql "$NEON_BRANCH_URL" -c "SELECT count(*) FROM users;"
psql "$NEON_BRANCH_URL" -c "SELECT * FROM orders ORDER BY created_at DESC LIMIT 5;"

# 4. If data looks good → promote branch
# Neon Console → Branch → Promote

# 5. Update your DATABASE_URL to point to the restored branch
# Vercel: vercel env add DATABASE_URL production
```

## Backup Verification — Test Monthly

**A backup that hasn't been restored is not a backup — it's a hope.**

```bash
# scripts/verify-backup.sh
# Run this monthly. Automate it via GitHub Actions cron.

set -euo pipefail

LATEST=$(ls -t ./backups/db_*.sql.gz | head -1)
echo "Testing backup: $LATEST"

# Restore to a temporary database
TEMP_DB="backup_test_$(date +%s)"
createdb "$TEMP_DB"
gunzip -c "$LATEST" | psql "$TEMP_DB"

# Verify
ROW_COUNT=$(psql "$TEMP_DB" -t -c "SELECT count(*) FROM users;")
echo "Restored $ROW_COUNT user records"

if [ "$ROW_COUNT" -gt 0 ]; then
  echo "✅ Backup verified successfully"
else
  echo "❌ Backup verification FAILED — no user records found"
  # Alert your monitoring system
fi

# Cleanup
dropdb "$TEMP_DB"
```

## File Storage Backups

If your app stores uploaded files (images, documents, etc.):

```bash
# S3-compatible storage — cross-region replication
aws s3 sync s3://production-bucket s3://backup-bucket \
  --region us-west-2 \
  --storage-class GLACIER_IR

# Vercel Blob — no native backup, export periodically
# Store important uploads in a separate S3 bucket as backup
```

## Checklist — Before Going Live

- [ ] Database has automated backups enabled (verify in provider console)
- [ ] Backup retention is ≥ 7 days (≥ 14 for production)
- [ ] Point-in-time recovery is enabled
- [ ] You have tested restoring a backup (at least once)
- [ ] Monthly backup verification is automated (GitHub Actions cron)
- [ ] Off-site backup exists (S3, different region)
- [ ] Recovery playbook is documented (see above)
- [ ] DATABASE_URL is stored in environment (not hardcoded)
- [ ] File uploads are backed up separately (or in a bucket with versioning)
- [ ] You know how to contact your database provider's support
- [ ] Maintenance page is deployable (for "we're restoring" messaging)

## Common TYO Community Mistakes

| Mistake | Why It's Dangerous | The Fix |
|---|---|---|
| No backups on the free tier | Free tier often has no backups | Add cron-based backup script (zero cost) |
| Backups in same account/region | Account/region outage = backup also gone | Cross-region S3 copy |
| Never tested a restore | Backup might be corrupted | Monthly restore test |
| Backing up only the database, not files | User uploads are data too | S3 versioning + cross-region replication |
| No RPO/RTO targets | No idea how much data loss is acceptable | Set targets, choose backup strategy accordingly |
| Backup script uses hardcoded credentials | Secret in script = leaked in git | Use GitHub secrets or environment variables |
