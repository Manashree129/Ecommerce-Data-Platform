-- =============================================================================
-- File     : sql/04_data_import/import_customers.sql
-- Project  : FreeEcommerceTwin14M (PostgreSQL)
-- Purpose  : Load customers into staging.customers and typed core.customers
-- Source   : customers(1).csv (uploaded dataset filename)
-- Expected : 1,000,000 data rows (header excluded)
-- Depends  : 03_table_creation/staging_tables.sql, core_tables.sql
-- Run as   : Start psql from the directory containing the seven CSV files,
--            then execute this script with psql -d free_ecommerce_twin_14m -f
--            <path>/import_customers.sql.
-- Requires : psql client; this script uses the psql \copy meta-command.
-- Rerun    : Reloads the staging table. Core load is skipped only when the
--            target core table already has the complete expected row count;
--            partial core loads raise an exception instead of being ignored.
-- Status   : Generated from the supplied CSVs; not yet executed in PostgreSQL.

-- =============================================================================

\set ON_ERROR_STOP on
\timing on

BEGIN;

-- 1. Reload raw source rows. The staging table preserves the source values.
TRUNCATE TABLE staging.customers;
\copy staging.customers (customer_id, signup_date, region, segment, lifetime_orders, lifetime_spend, email_domain) FROM 'customers(1).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- 2. Validate the raw load before transforming it.
DO $$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows FROM staging.customers;
    IF v_rows <> 1000000 THEN
        RAISE EXCEPTION 'staging.customers: expected 1000000 rows, found %', v_rows;
    END IF;
    IF EXISTS (
        SELECT 1 FROM staging.customers
        WHERE customer_id IS NULL OR btrim(customer_id) = ''
    ) THEN
        RAISE EXCEPTION 'staging.customers: blank or NULL key value found in customer_id';
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'staging', 'customers', count(*), 1000000, 'customers(1).csv; raw staging reload'
FROM staging.customers;

-- Refuse partial or duplicate core loads. An empty table is loaded;
-- a complete table is retained; any partial state requires investigation.
DO $$
DECLARE
    v_core_rows bigint;
BEGIN
    SELECT count(*) INTO v_core_rows FROM core.customers;
    IF v_core_rows NOT IN (0, 1000000) THEN
        RAISE EXCEPTION 'core.customers: expected either 0 or 1000000 rows before import, found %', v_core_rows;
    END IF;
    IF EXISTS (SELECT customer_id FROM staging.customers GROUP BY customer_id HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'staging.customers: duplicate key values found';
    END IF;
END $$;

-- 3. Typed load. All source customer fields were populated and parseable
-- during inspection; casts intentionally fail the transaction on bad values.
INSERT INTO core.customers (
    customer_id, signup_date, region, segment,
    lifetime_orders, lifetime_spend, email_domain
)
SELECT customer_id,
       signup_date::date,
       region,
       segment,
       lifetime_orders::integer,
       lifetime_spend::numeric(12,2),
       email_domain
FROM staging.customers
WHERE NOT EXISTS (SELECT 1 FROM core.customers);

DO $$
DECLARE
    v_rows bigint;
    v_distinct bigint;
BEGIN
    SELECT count(*), count(DISTINCT customer_id)
      INTO v_rows, v_distinct
      FROM core.customers;
    IF v_rows <> 1000000 OR v_distinct <> 1000000 THEN
        RAISE EXCEPTION 'core.customers: expected 1000000 rows and unique customer_id; found rows %, distinct keys %', v_rows, v_distinct;
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'core', 'customers', count(*), 1000000, 'core row count after import or verified rerun'
FROM core.customers;

COMMIT;

SELECT 'customers' AS table_name,
       (SELECT count(*) FROM staging.customers) AS staging_rows,
       (SELECT count(*) FROM core.customers) AS core_rows,
       1000000::bigint AS expected_rows;
