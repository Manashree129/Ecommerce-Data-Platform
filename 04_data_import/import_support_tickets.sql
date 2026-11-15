-- =============================================================================
-- File     : sql/04_data_import/import_support_tickets.sql
-- Project  : FreeEcommerceTwin14M (PostgreSQL)
-- Purpose  : Load support_tickets into staging.support_tickets and typed core.support_tickets
-- Source   : support_tickets(1).csv (uploaded dataset filename)
-- Expected : 66,938 data rows (header excluded)
-- Depends  : 03_table_creation/staging_tables.sql, core_tables.sql
-- Run as   : Start psql from the directory containing the seven CSV files,
--            then execute this script with psql -d free_ecommerce_twin_14m -f
--            <path>/import_support_tickets.sql.
-- Requires : psql client; this script uses the psql \copy meta-command.
-- Rerun    : Reloads the staging table. Core load is skipped only when the
--            target core table already has the complete expected row count;
--            partial core loads raise an exception instead of being ignored.
-- Status   : Generated from the supplied CSVs; not yet executed in PostgreSQL.
-- Cleaning: source resolution_days = -1 is a sentinel for unresolved tickets.
-- Convert -1 to NULL in core while preserving -1 in staging. Profiling found
-- 16,555 such rows, associated with open/in_progress tickets.
-- =============================================================================

\set ON_ERROR_STOP on
\timing on

BEGIN;

-- 1. Reload raw source rows. The staging table preserves the source values.
TRUNCATE TABLE staging.support_tickets;
\copy staging.support_tickets (ticket_id, customer_id, order_id, created_date, category, priority, status, resolution_days) FROM 'support_tickets(1).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- 2. Validate the raw load before transforming it.
DO $$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows FROM staging.support_tickets;
    IF v_rows <> 66938 THEN
        RAISE EXCEPTION 'staging.support_tickets: expected 66938 rows, found %', v_rows;
    END IF;
    IF EXISTS (
        SELECT 1 FROM staging.support_tickets
        WHERE ticket_id IS NULL OR btrim(ticket_id) = ''
    ) THEN
        RAISE EXCEPTION 'staging.support_tickets: blank or NULL key value found in ticket_id';
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'staging', 'support_tickets', count(*), 66938, 'support_tickets(1).csv; raw staging reload'
FROM staging.support_tickets;

-- 3. Validate normalized identifiers and parent-table dependencies.
DO $$
BEGIN
    IF EXISTS (SELECT ticket_id FROM staging.support_tickets GROUP BY ticket_id HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'support_tickets.csv: duplicate ticket_id values found';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.support_tickets WHERE resolution_days = '-1' AND status NOT IN ('open', 'in_progress')) THEN
        RAISE EXCEPTION 'support_tickets.csv: resolution_days = -1 found outside open/in_progress statuses';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.support_tickets WHERE resolution_days <> '-1' AND resolution_days::integer < 0) THEN
        RAISE EXCEPTION 'support_tickets.csv: unexpected negative resolution_days value';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.support_tickets t LEFT JOIN core.customers c ON c.customer_id=t.customer_id WHERE c.customer_id IS NULL) THEN
        RAISE EXCEPTION 'support_tickets.csv: customer_id does not resolve to core.customers';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.support_tickets t LEFT JOIN core.orders o ON o.order_id=t.order_id WHERE o.order_id IS NULL) THEN
        RAISE EXCEPTION 'support_tickets.csv: order_id does not resolve to core.orders';
    END IF;
END $$;

-- Refuse partial or duplicate core loads. An empty table is loaded;
-- a complete table is retained; any partial state requires investigation.
DO $$
DECLARE
    v_core_rows bigint;
BEGIN
    SELECT count(*) INTO v_core_rows FROM core.support_tickets;
    IF v_core_rows NOT IN (0, 66938) THEN
        RAISE EXCEPTION 'core.support_tickets: expected either 0 or 66938 rows before import, found %', v_core_rows;
    END IF;
    IF EXISTS (SELECT ticket_id FROM staging.support_tickets GROUP BY ticket_id HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'staging.support_tickets: duplicate key values found';
    END IF;
END $$;

-- 4. Transform and insert into the typed core table.
INSERT INTO core.support_tickets (ticket_id, customer_id, order_id, created_date, category, priority, status, resolution_days)
SELECT ticket_id, customer_id, order_id, created_date::date,
       category, priority, status,
       NULLIF(resolution_days, '-1')::smallint
FROM staging.support_tickets
WHERE NOT EXISTS (SELECT 1 FROM core.support_tickets);

DO $$
DECLARE
    v_rows bigint;
    v_distinct bigint;
BEGIN
    SELECT count(*), count(DISTINCT ticket_id)
      INTO v_rows, v_distinct
      FROM core.support_tickets;
    IF v_rows <> 66938 OR v_distinct <> 66938 THEN
        RAISE EXCEPTION 'core.support_tickets: expected 66938 rows and unique ticket_id; found rows %, distinct keys %', v_rows, v_distinct;
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'core', 'support_tickets', count(*), 66938, 'core row count after import or verified rerun'
FROM core.support_tickets;

COMMIT;

SELECT 'support_tickets' AS table_name,
       (SELECT count(*) FROM staging.support_tickets) AS staging_rows,
       (SELECT count(*) FROM core.support_tickets) AS core_rows,
       66938::bigint AS expected_rows;
