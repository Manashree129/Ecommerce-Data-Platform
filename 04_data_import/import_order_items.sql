-- =============================================================================
-- File     : sql/04_data_import/import_order_items.sql
-- Project  : FreeEcommerceTwin14M (PostgreSQL)
-- Purpose  : Load order_items into staging.order_items and typed core.order_items
-- Source   : order_items(1).csv (uploaded dataset filename)
-- Expected : 4,280,732 data rows (header excluded)
-- Depends  : 03_table_creation/staging_tables.sql, core_tables.sql
-- Run as   : Start psql from the directory containing the seven CSV files,
--            then execute this script with psql -d free_ecommerce_twin_14m -f
--            <path>/import_order_items.sql.
-- Requires : psql client; this script uses the psql \copy meta-command.
-- Rerun    : Reloads the staging table. Core load is skipped only when the
--            target core table already has the complete expected row count;
--            partial core loads raise an exception instead of being ignored.
-- Status   : Generated from the supplied CSVs; not yet executed in PostgreSQL.
-- Cleaning: strip the verified injected suffix from 24 order_item_id values.
-- No uniqueness rule is applied to (order_id, product_id): the source contains
-- 156 repeated product lines within orders, which are valid separate lines.
-- =============================================================================

\set ON_ERROR_STOP on
\timing on

BEGIN;

-- 1. Reload raw source rows. The staging table preserves the source values.
TRUNCATE TABLE staging.order_items;
\copy staging.order_items (order_item_id, order_id, product_id, quantity, unit_price, line_total) FROM 'order_items(1).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- 2. Validate the raw load before transforming it.
DO $$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows FROM staging.order_items;
    IF v_rows <> 4280732 THEN
        RAISE EXCEPTION 'staging.order_items: expected 4280732 rows, found %', v_rows;
    END IF;
    IF EXISTS (
        SELECT 1 FROM staging.order_items
        WHERE order_item_id IS NULL OR btrim(order_item_id) = ''
    ) THEN
        RAISE EXCEPTION 'staging.order_items: blank or NULL key value found in order_item_id';
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'staging', 'order_items', count(*), 4280732, 'order_items(1).csv; raw staging reload'
FROM staging.order_items;

-- 3. Validate normalized identifiers and parent-table dependencies.
DO $$
BEGIN
    IF (SELECT count(*) FROM staging.order_items WHERE right(order_item_id, length('_zdl26nr51f60aaa959f')) = '_zdl26nr51f60aaa959f') <> 24 THEN
        RAISE EXCEPTION 'order_items.csv: expected 24 order_item_id values with the injected suffix';
    END IF;
    IF EXISTS (SELECT regexp_replace(order_item_id, '_zdl26nr51f60aaa959f$', '') FROM staging.order_items GROUP BY regexp_replace(order_item_id, '_zdl26nr51f60aaa959f$', '') HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'order_items.csv: duplicate order_item_id after suffix normalization';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.order_items s LEFT JOIN core.orders o ON o.order_id=s.order_id WHERE o.order_id IS NULL) THEN
        RAISE EXCEPTION 'order_items.csv: order_id does not resolve to core.orders; import orders first';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.order_items s LEFT JOIN core.products p ON p.product_id=s.product_id WHERE p.product_id IS NULL) THEN
        RAISE EXCEPTION 'order_items.csv: product_id does not resolve to core.products; import products first';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.order_items WHERE round(quantity::numeric * unit_price::numeric, 2) <> line_total::numeric) THEN
        RAISE EXCEPTION 'order_items.csv: quantity * unit_price does not equal line_total';
    END IF;
END $$;

-- Refuse partial or duplicate core loads. An empty table is loaded;
-- a complete table is retained; any partial state requires investigation.
DO $$
DECLARE
    v_core_rows bigint;
BEGIN
    SELECT count(*) INTO v_core_rows FROM core.order_items;
    IF v_core_rows NOT IN (0, 4280732) THEN
        RAISE EXCEPTION 'core.order_items: expected either 0 or 4280732 rows before import, found %', v_core_rows;
    END IF;
    IF EXISTS (SELECT order_item_id FROM staging.order_items GROUP BY order_item_id HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'staging.order_items: duplicate key values found';
    END IF;
END $$;

-- 4. Transform and insert into the typed core table.
INSERT INTO core.order_items (order_item_id, order_id, product_id, quantity, unit_price, line_total)
SELECT regexp_replace(order_item_id, '_zdl26nr51f60aaa959f$', ''),
       order_id, product_id, quantity::smallint,
       unit_price::numeric(10,2), line_total::numeric(12,2)
FROM staging.order_items
WHERE NOT EXISTS (SELECT 1 FROM core.order_items);

DO $$
DECLARE
    v_rows bigint;
    v_distinct bigint;
BEGIN
    SELECT count(*), count(DISTINCT order_item_id)
      INTO v_rows, v_distinct
      FROM core.order_items;
    IF v_rows <> 4280732 OR v_distinct <> 4280732 THEN
        RAISE EXCEPTION 'core.order_items: expected 4280732 rows and unique order_item_id; found rows %, distinct keys %', v_rows, v_distinct;
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'core', 'order_items', count(*), 4280732, 'core row count after import or verified rerun'
FROM core.order_items;

COMMIT;

SELECT 'order_items' AS table_name,
       (SELECT count(*) FROM staging.order_items) AS staging_rows,
       (SELECT count(*) FROM core.order_items) AS core_rows,
       4280732::bigint AS expected_rows;
