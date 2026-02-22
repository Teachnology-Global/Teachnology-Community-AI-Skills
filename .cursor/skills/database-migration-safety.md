---
description: >
  Ensures database schema changes are safe, reversible, and zero-downtime. Enforces
  the expand-contract pattern, rollback scripts, and migration testing before any
  schema change reaches production. Essential for teams using Neon, PlanetScale,
  Supabase, or any hosted Postgres/MySQL.
  Use when: (1) writing or reviewing database migrations, (2) adding/removing columns
  or tables, (3) renaming schema elements, (4) preparing production deployments,
  (5) recovering from a failed migration.
globs: ["**/migrations/**", "**/db/**", "**/*.sql", "**/prisma/schema.prisma", "**/drizzle/**", "**/knexfile*", "**/alembic/**"]
alwaysApply: false
---

# Database Migration Safety

## Purpose

Prevent data loss, production outages, and irreversible schema changes. Every migration must be safe to run, safe to roll back, and tested before it reaches production.

## Activation

This skill activates when you mention:
- "migration", "schema change", "database migration"
- "ALTER TABLE", "DROP COLUMN", "rename column"
- "Prisma migrate", "Drizzle push", "Alembic", "Flyway", "Liquibase"
- "zero downtime", "rollback", "migration rollback"
- "Neon", "PlanetScale", "Supabase schema", "database deployment"

Also activates when working on:
- Files in `migrations/`, `db/migrations/`, `prisma/migrations/`
- `schema.prisma`, `drizzle.config.ts`
- Any `.sql` file with `ALTER`, `DROP`, `CREATE TABLE`, or `RENAME`

## The Golden Rules

1. **Never destroy data directly** — rename or archive, never drop without a safety window
2. **Every migration has a rollback** — if you can't undo it, you can't ship it
3. **Test on a copy of production data first** — staging must mirror production schema + volume
4. **One change per migration** — atomic changes are safer and easier to roll back
5. **Migrations are append-only** — never edit a migration file that has already run

## The Expand-Contract Pattern

The only safe way to rename columns, restructure tables, or change data types in a live system.

```
PHASE 1 — EXPAND (Deploy with old code)
  Add new column/table alongside old one
  Start writing to both

PHASE 2 — MIGRATE (Run background job)
  Backfill existing data to new column/table
  Verify all rows migrated

PHASE 3 — CONTRACT (Deploy with new code)
  Switch reads to new column/table
  New code only uses new schema

PHASE 4 — CLEANUP (After confidence window)
  Drop old column/table (separate migration, separate deploy)
```

### Example: Renaming a Column (Postgres)

```sql
-- ❌ DANGEROUS: breaks running app immediately
ALTER TABLE users RENAME COLUMN full_name TO display_name;

-- ✅ SAFE: Phase 1 - Expand
-- Migration 001: Add new column (nullable, no data loss)
ALTER TABLE users ADD COLUMN display_name TEXT;

-- ✅ SAFE: Phase 2 - Backfill (run as background job or separate migration)
UPDATE users SET display_name = full_name WHERE display_name IS NULL;

-- ✅ SAFE: Phase 3 - Contract (after deploying new code that reads display_name)
-- Make new column required once all rows populated
ALTER TABLE users ALTER COLUMN display_name SET NOT NULL;

-- ✅ SAFE: Phase 4 - Cleanup (separate deploy, after confidence window)
-- Migration 003: Remove old column only after app no longer references it
ALTER TABLE users DROP COLUMN full_name;
```

### Example: Changing Data Type

```sql
-- ❌ DANGEROUS: locks table, loses data if types incompatible
ALTER TABLE orders ALTER COLUMN amount TYPE BIGINT;

-- ✅ SAFE: Add new typed column, migrate data, swap
ALTER TABLE orders ADD COLUMN amount_bigint BIGINT;
UPDATE orders SET amount_bigint = amount::BIGINT;
-- (deploy code that writes to both columns)
-- (verify all rows have amount_bigint)
ALTER TABLE orders ALTER COLUMN amount_bigint SET NOT NULL;
-- (deploy code that reads from amount_bigint)
ALTER TABLE orders DROP COLUMN amount;
ALTER TABLE orders RENAME COLUMN amount_bigint TO amount;
```

## Migration Checklist

Before writing a migration:

```markdown
## Migration Pre-Flight

- [ ] Is this reversible? (rollback script written)
- [ ] Does this use expand-contract for renames/type changes?
- [ ] Will this lock tables? (test with EXPLAIN on large tables)
- [ ] Does the app still work if this migration runs mid-deploy?
- [ ] Is there a backfill strategy for existing rows?
- [ ] Has this been tested against a production-sized dataset?
```

## Rollback Scripts

Every migration file must have a corresponding rollback. Never treat rollback as optional.

### Structure

```
migrations/
  002_add_user_preferences/
    up.sql        ← apply the change
    down.sql      ← undo the change
    README.md     ← what this migration does and why
```

### Rollback Template

```sql
-- down.sql - ROLLBACK for migration 002_add_user_preferences
-- Generated: 2026-02-22
-- Author: [name]
-- Reverts: Added preferences JSONB column to users table

-- VERIFY before running:
-- SELECT COUNT(*) FROM users WHERE preferences IS NOT NULL;
-- If count > 0, decide if you need to backup preferences data first.

BEGIN;

ALTER TABLE users DROP COLUMN IF EXISTS preferences;

-- Verify rollback
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'preferences'
  ) THEN
    RAISE EXCEPTION 'Rollback failed: preferences column still exists';
  END IF;
END $$;

COMMIT;
```

## ORM-Specific Guidance

### Prisma

```bash
# ALWAYS review the generated SQL before applying
npx prisma migrate dev --name add_user_preferences

# Review what prisma generated
cat prisma/migrations/[timestamp]_add_user_preferences/migration.sql

# NEVER use migrate deploy on production without first running on staging
npx prisma migrate deploy  # only after staging validation

# Check migration history is clean
npx prisma migrate status
```

**Prisma safety flags:**
```typescript
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  // shadowDatabaseUrl for safe migrate dev on hosted DBs
  shadowDatabaseUrl = env("SHADOW_DATABASE_URL")
}
```

### Drizzle

```typescript
// Always generate migrations, never use push in production
// ❌ NEVER in production:
// await drizzle.push(schema)

// ✅ Use migration files:
import { migrate } from 'drizzle-orm/postgres-js/migrator';
await migrate(db, { migrationsFolder: './drizzle' });

// Review generated SQL before applying
npx drizzle-kit generate:pg
cat drizzle/[timestamp]_migration.sql  // review this
```

### Alembic (Python/SQLAlchemy)

```bash
# Generate migration
alembic revision --autogenerate -m "add user preferences"

# Always review the generated file
cat alembic/versions/[hash]_add_user_preferences.py

# Test upgrade
alembic upgrade head

# Test downgrade BEFORE upgrading production
alembic downgrade -1
alembic upgrade head
```

## Large Table Safety

For tables with millions of rows, standard `ALTER TABLE` locks the entire table. Use these techniques instead:

### Adding a Column (Postgres 11+)

```sql
-- ✅ Instant on Postgres 11+ with DEFAULT
-- Adding NOT NULL with DEFAULT no longer rewrites the table
ALTER TABLE large_table ADD COLUMN new_col TEXT DEFAULT 'pending' NOT NULL;
-- This is instantaneous — no table lock!

-- ❌ Old pattern (pre-Postgres 11) that causes full table rewrite:
ALTER TABLE large_table ADD COLUMN new_col TEXT NOT NULL DEFAULT 'pending';
```

### Adding an Index Without Locking

```sql
-- ❌ Locks table during index build
CREATE INDEX idx_users_email ON users(email);

-- ✅ Non-blocking (Postgres)
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- ✅ Non-blocking (MySQL)
ALTER TABLE users ADD INDEX idx_email (email) ALGORITHM=INPLACE, LOCK=NONE;
```

### Backfilling Large Tables

```typescript
// Never UPDATE millions of rows in a single transaction
// ❌ This will lock your table and possibly time out:
// await db.execute(sql`UPDATE users SET preferences = '{}' WHERE preferences IS NULL`)

// ✅ Batch in chunks with a delay
async function backfillUserPreferences(batchSize = 1000) {
  let cursor = 0;
  let updated = 0;

  while (true) {
    const result = await db.execute(sql`
      UPDATE users 
      SET preferences = '{}'
      WHERE id IN (
        SELECT id FROM users 
        WHERE preferences IS NULL 
        LIMIT ${batchSize}
      )
      RETURNING id
    `);

    updated += result.rowCount;
    console.log(`Backfilled ${updated} rows`);

    if (result.rowCount < batchSize) break;

    // Pause between batches to reduce load
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  console.log(`Backfill complete: ${updated} rows updated`);
}
```

## Migration Testing Workflow

```markdown
## Migration Test Plan: [Migration Name]

### Environment Checklist
- [ ] Staging DB has production schema (including all previous migrations)
- [ ] Staging DB has production-representative data volume
- [ ] Rollback script is ready and tested

### Apply Test
1. Run `migrate up` on staging
2. Verify: no lock timeouts (check pg_stat_activity)
3. Verify: expected schema change applied
4. Verify: existing data intact (row counts match)
5. Verify: app still works (smoke test critical paths)

### Rollback Test
1. Run `migrate down` on staging (from same state)
2. Verify: schema reverted correctly
3. Verify: data integrity maintained
4. Verify: app works with reverted schema

### Performance Test (for large tables)
1. Run EXPLAIN ANALYZE on queries affected by migration
2. Check index usage post-migration
3. Verify query times acceptable under expected load

### Production Deployment
- [ ] Staging tests passed
- [ ] Rollback tested
- [ ] Deployment window agreed (low-traffic period)
- [ ] Database snapshot taken pre-migration
- [ ] Monitoring alerts active
- [ ] On-call engineer available
```

## Recovery: If a Migration Goes Wrong

```bash
# 1. DON'T PANIC. Take a breath.

# 2. Immediately check what state the migration is in
-- Prisma
npx prisma migrate status

-- Alembic  
alembic current

-- Check if migration partially ran
SELECT * FROM _prisma_migrations ORDER BY started_at DESC LIMIT 5;

# 3. If migration is still running, check for locks
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active' AND query_start < NOW() - INTERVAL '5 minutes';

# 4. If you need to kill a runaway migration
SELECT pg_cancel_backend([pid]);  -- polite
SELECT pg_terminate_backend([pid]);  -- forceful

# 5. Run the rollback script
psql $DATABASE_URL < migrations/[name]/down.sql

# 6. If rollback fails, restore from snapshot
# (This is why you took a snapshot before running the migration)

# 7. Document what happened — this is a learning for the team
```

## Neon-Specific Guidance

For Neon (branching Postgres):

```bash
# Create a branch for testing the migration — FREE and instant
neon branches create --name migration-test --parent main

# Get the connection string for the test branch
neon connection-string migration-test

# Run migration on test branch
DATABASE_URL=[test-branch-url] npx prisma migrate deploy

# Verify it worked
neon branches list

# Promote branch to main only after testing
# (or reset and apply to main after confirming migration is correct)

# Clean up test branch
neon branches delete migration-test
```

## Integration

### With Human Approval
- Migrations that drop data or columns require human approval
- Migrations to production always require approval
- Schema changes affecting security (removing auth tables, etc.) need security sign-off

### With Pre-Release
- Migration test results included in release report
- Rollback procedure documented in release notes
- Database snapshot confirmed before deployment

### With Environment Consistency
- Migration scripts tested on staging before production
- Database versions match across environments
- ORM client version matches database capabilities

### With Error Handling
- Migration failures must be caught and logged with full context
- Partial migration state must be detectable
- Runbook for common migration failures documented
