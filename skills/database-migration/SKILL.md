---
name: database-migration
description: Use this skill when asked to write a database migration, change a schema, move data between tables, or plan a zero-downtime schema change — automatically selected for "add a column", "rename a table", "migrate data", or "write a migration script".
license: MIT
---

# Database Migration

## When to Use This Skill

- Adding, removing, or renaming columns or tables
- Changing column types or constraints
- Migrating data from one structure to another
- Planning a zero-downtime deployment involving schema changes
- Writing or reviewing rollback scripts for a migration

---

## Process

### 1. Pre-Migration Assessment

Answer these questions before writing a single line of SQL:

| Question | Why It Matters |
|----------|---------------|
| How large is the affected table? | Large tables (> 1M rows) need online DDL or batching |
| Is this table written to constantly? | Locks can cause timeouts/downtime |
| Does the change affect the API contract? | May require backward-compatible interim steps |
| Is there a rollback path? | Every migration needs a down script |
| What is the deployment window? | Determines whether zero-downtime patterns are needed |

```sql
-- Check table size (PostgreSQL)
SELECT pg_size_pretty(pg_total_relation_size('table_name')) AS total_size,
       reltuples::bigint AS estimated_rows
FROM pg_class WHERE relname = 'table_name';

-- Check table size (MySQL)
SELECT table_rows, data_length / 1024 / 1024 AS data_mb
FROM information_schema.tables
WHERE table_name = 'table_name';
```

### 2. Migration File Structure

Name migrations with a timestamp prefix for deterministic ordering:

```
migrations/
  20240115120000_add_user_verified_at.sql
  20240115120000_add_user_verified_at.down.sql
```

Or use your ORM's migration tool:

```bash
# Prisma
npx prisma migrate dev --name add_user_verified_at

# TypeORM
npx typeorm migration:create -n AddUserVerifiedAt

# Alembic (Python / SQLAlchemy)
alembic revision --autogenerate -m "add_user_verified_at"

# EF Core (.NET)
dotnet ef migrations add AddUserVerifiedAt

# Flyway
# Name file: V20240115120000__add_user_verified_at.sql

# Rails ActiveRecord
rails generate migration AddVerifiedAtToUsers verified_at:datetime
```

### 3. Write the UP Migration

Structure every migration file as:

```sql
-- Migration: 20240115120000_add_user_verified_at
-- Description: Add verified_at timestamp to users table
-- Estimated rows: ~500,000
-- Estimated duration: < 1 second (online DDL safe)
-- Rollback: 20240115120000_add_user_verified_at.down.sql

BEGIN;

ALTER TABLE users ADD COLUMN verified_at TIMESTAMPTZ DEFAULT NULL;

-- Backfill existing verified users (batch to avoid lock)
UPDATE users SET verified_at = created_at WHERE is_verified = true;

COMMIT;
```

### 4. Write the DOWN Migration

Every UP must have a DOWN:

```sql
-- Rollback: 20240115120000_add_user_verified_at.down.sql

BEGIN;

ALTER TABLE users DROP COLUMN IF EXISTS verified_at;

COMMIT;
```

> **Rule**: DOWN scripts must be tested before the UP runs in production.

### 5. Zero-Downtime Patterns

#### Adding a Column
```sql
-- SAFE: nullable column with no default (instant, no rewrite)
ALTER TABLE orders ADD COLUMN notes TEXT;

-- SAFE in PostgreSQL 11+: column with default (stored in catalog, not rewritten)
ALTER TABLE orders ADD COLUMN is_priority BOOLEAN DEFAULT false NOT NULL;

-- UNSAFE: NOT NULL with no default on large table (full rewrite)
-- Instead: 1) add nullable, 2) backfill, 3) add NOT NULL constraint
ALTER TABLE orders ADD COLUMN priority_level INT;
UPDATE orders SET priority_level = 0 WHERE priority_level IS NULL; -- batch this
ALTER TABLE orders ALTER COLUMN priority_level SET NOT NULL;
```

#### Renaming a Column (Expand-Contract)
```
Step 1: Add new column (old name still exists)
Step 2: Dual-write to both old and new column in application code
Step 3: Backfill new column from old
Step 4: Read from new column in application code
Step 5: Stop writing to old column
Step 6: Drop old column (separate migration)
```

#### Renaming a Table
```sql
-- Step 1: create a view with the old name pointing to new table
-- Step 2: update all application queries
-- Step 3: drop the view
CREATE VIEW old_table_name AS SELECT * FROM new_table_name;
```

#### Adding an Index (without locking)
```sql
-- PostgreSQL: CREATE INDEX CONCURRENTLY (no table lock)
CREATE INDEX CONCURRENTLY idx_orders_customer_id ON orders(customer_id);

-- MySQL: online DDL is default for InnoDB since 5.6
ALTER TABLE orders ADD INDEX idx_orders_customer_id (customer_id), ALGORITHM=INPLACE, LOCK=NONE;
```

#### Removing a Column (safe sequence)
```
Step 1: Stop reading the column in application code
Step 2: Stop writing the column in application code
Step 3: Deploy application changes
Step 4: Run DROP COLUMN migration (only after step 3 is live)
```

### 6. Large Table Data Migrations (Batching)

Never migrate millions of rows in a single transaction:

```sql
-- PostgreSQL: batch update to avoid lock escalation and replication lag
DO $$
DECLARE
  batch_size INT := 1000;
  affected   INT;
BEGIN
  LOOP
    UPDATE orders
    SET    new_status = old_status::new_enum
    WHERE  id IN (
             SELECT id FROM orders
             WHERE  new_status IS NULL
             LIMIT  batch_size
             FOR UPDATE SKIP LOCKED
           );
    GET DIAGNOSTICS affected = ROW_COUNT;
    EXIT WHEN affected = 0;
    PERFORM pg_sleep(0.1); -- brief pause to reduce I/O pressure
  END LOOP;
END $$;
```

```python
# Python batch migration
BATCH_SIZE = 1000
last_id = 0
while True:
    rows = db.execute(
        "SELECT id FROM orders WHERE new_status IS NULL AND id > %s LIMIT %s",
        (last_id, BATCH_SIZE)
    ).fetchall()
    if not rows:
        break
    ids = [r[0] for r in rows]
    db.execute("UPDATE orders SET new_status = old_status WHERE id = ANY(%s)", (ids,))
    db.commit()
    last_id = ids[-1]
    time.sleep(0.05)
```

### 7. Validation Queries

Run these after the migration to confirm correctness:

```sql
-- Verify no NULLs where NOT NULL was added
SELECT COUNT(*) FROM users WHERE verified_at IS NULL AND is_verified = true;
-- Expected: 0

-- Verify row count unchanged after data migration
SELECT COUNT(*) FROM orders;               -- before: store this number
SELECT COUNT(*) FROM orders_new;           -- after: must match

-- Verify index was created successfully
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'orders';

-- Verify foreign key integrity
SELECT COUNT(*) FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
WHERE c.id IS NULL;
-- Expected: 0
```

### 8. Migration Execution Checklist

```bash
# Dry-run / review
psql $DATABASE_URL -c "\i migration.sql" --dry-run   # or use --echo-queries

# Take a backup before running destructive migrations
pg_dump $DATABASE_URL | gzip > backup_$(date +%Y%m%d%H%M%S).sql.gz

# Run in a transaction (for transactional DDL databases)
psql $DATABASE_URL -1 -f migration.sql

# Monitor for locks during migration
SELECT pid, wait_event_type, wait_event, query
FROM pg_stat_activity
WHERE wait_event IS NOT NULL;
```

---

## Tools & Resources

- **Prisma**: https://www.prisma.io/docs/concepts/components/prisma-migrate
- **Alembic**: https://alembic.sqlalchemy.org/
- **Flyway**: https://flywaydb.org/
- **Liquibase**: https://www.liquibase.org/
- **pg-osc** (PostgreSQL online schema changes): https://github.com/shayonj/pg-osc
- **gh-ost** (MySQL online schema changes): https://github.com/github/gh-ost

---

## Checklist

- [ ] Table size and write volume assessed
- [ ] Zero-downtime pattern chosen if table > 100K rows or high-write
- [ ] UP migration written with transaction boundary
- [ ] DOWN (rollback) migration written and tested
- [ ] Batching used for data migrations > 10K rows
- [ ] Index creation uses `CONCURRENTLY` (PostgreSQL) or `LOCK=NONE` (MySQL)
- [ ] Column additions are nullable or have DB-level defaults
- [ ] Validation queries prepared and ready to run post-migration
- [ ] Backup taken before running destructive changes
- [ ] Migration tested on a staging environment with production-scale data
- [ ] Application code deployed before dropping old columns/tables
