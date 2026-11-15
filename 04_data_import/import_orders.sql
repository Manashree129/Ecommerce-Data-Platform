-- =============================================================================
-- File     : sql/04_data_import/import_orders.sql
-- Project  : FreeEcommerceTwin14M (PostgreSQL)
-- Purpose  : Load orders into staging.orders and typed core.orders
-- Source   : orders(1).csv (uploaded dataset filename)
-- Expected : 1,075,683 data rows (header excluded)
-- Depends  : 03_table_creation/staging_tables.sql, core_tables.sql
-- Run as   : Start psql from the directory containing the seven CSV files,
--            then execute this script with psql -d free_ecommerce_twin_14m -f
--            <path>/import_orders.sql.
-- Requires : psql client; this script uses the psql \copy meta-command.
-- Rerun    : Reloads the staging table. Core load is skipped only when the
--            target core table already has the complete expected row count;
--            partial core loads raise an exception instead of being ignored.
-- Status   : Generated from the supplied CSVs; not yet executed in PostgreSQL.
-- Cleaning: strip the verified injected suffix from 6 session_id references.
-- order_id values themselves require no modification.
-- =============================================================================

\set ON_ERROR_STOP on
\timing on

BEGIN;

-- 1. Reload raw source rows. The staging table preserves the source values.
TRUNCATE TABLE staging.orders;
\copy staging.orders (order_id, customer_id, session_id, order_date, status, item_count, order_total, payment_method) FROM 'orders(1).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- 2. Validate the raw load before transforming it.
DO $$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows FROM staging.orders;
    IF v_rows <> 1075683 THEN
        RAISE EXCEPTION 'staging.orders: expected 1075683 rows, found %', v_rows;
    END IF;
    IF EXISTS (
        SELECT 1 FROM staging.orders
        WHERE order_id IS NULL OR btrim(order_id) = ''
    ) THEN
        RAISE EXCEPTION 'staging.orders: blank or NULL key value found in order_id';
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'staging', 'orders', count(*), 1075683, 'orders(1).csv; raw staging reload'
FROM staging.orders;

-- 3. Validate normalized identifiers and parent-table dependencies.
DO $$
BEGIN
    IF (SELECT count(*) FROM staging.orders WHERE right(session_id, length('_zdl26nr51f60aaa959f')) = '_zdl26nr51f60aaa959f') <> 6 THEN
        RAISE EXCEPTION 'orders.csv: expected 6 session_id values with the injected suffix';
    END IF;
    IF EXISTS (SELECT order_id FROM staging.orders GROUP BY order_id HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'orders.csv: duplicate order_id values found';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.orders o LEFT JOIN core.customers c ON c.customer_id=o.customer_id WHERE c.customer_id IS NULL) THEN
        RAISE EXCEPTION 'orders.csv: customer_id does not resolve to core.customers';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.orders o LEFT JOIN core.sessions s ON s.session_id=regexp_replace(o.session_id, '_zdl26nr51f60aaa959f$', '') WHERE s.session_id IS NULL) THEN
        RAISE EXCEPTION 'orders.csv: normalized session_id does not resolve to core.sessions; import sessions first';
    END IF;
END $$;

-- Refuse partial or duplicate core loads. An empty table is loaded;
-- a complete table is retained; any partial state requires investigation.
DO $$
DECLARE
    v_core_rows bigint;
BEGIN
    SELECT count(*) INTO v_core_rows FROM core.orders;
    IF v_core_rows NOT IN (0, 1075683) THEN
        RAISE EXCEPTION 'core.orders: expected either 0 or 1075683 rows before import, found %', v_core_rows;
    END IF;
    IF EXISTS (SELECT order_id FROM staging.orders GROUP BY order_id HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'staging.orders: duplicate key values found';
    END IF;
END $$;

-- 4. Transform and insert into the typed core table.
INSERT INTO core.orders (order_id, customer_id, session_id, order_date, status, item_count, order_total, payment_method)
SELECT order_id, customer_id,
       regexp_replace(session_id, '_zdl26nr51f60aaa959f$', ''),
       order_date::date, status, item_count::smallint,
       order_total::numeric(12,2), payment_method
FROM staging.orders
WHERE NOT EXISTS (SELECT 1 FROM core.orders);

DO $$
DECLARE
    v_rows bigint;
    v_distinct bigint;
BEGIN
    SELECT count(*), count(DISTINCT order_id)
      INTO v_rows, v_distinct
      FROM core.orders;
    IF v_rows <> 1075683 OR v_distinct <> 1075683 THEN
        RAISE EXCEPTION 'core.orders: expected 1075683 rows and unique order_id; found rows %, distinct keys %', v_rows, v_distinct;
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'core', 'orders', count(*), 1075683, 'core row count after import or verified rerun'
FROM core.orders;

COMMIT;

SELECT 'orders' AS table_name,
       (SELECT count(*) FROM staging.orders) AS staging_rows,
       (SELECT count(*) FROM core.orders) AS core_rows,
       1075683::bigint AS expected_rows;
