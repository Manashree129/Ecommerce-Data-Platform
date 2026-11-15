-- =============================================================================
-- File     : sql/04_data_import/import_returns.sql
-- Project  : FreeEcommerceTwin14M (PostgreSQL)
-- Purpose  : Load returns into staging.returns and typed core.returns
-- Source   : returns(1).csv (uploaded dataset filename)
-- Expected : 400,293 data rows (header excluded)
-- Depends  : 03_table_creation/staging_tables.sql, core_tables.sql
-- Run as   : Start psql from the directory containing the seven CSV files,
--            then execute this script with psql -d free_ecommerce_twin_14m -f
--            <path>/import_returns.sql.
-- Requires : psql client; this script uses the psql \copy meta-command.
-- Rerun    : Reloads the staging table. Core load is skipped only when the
--            target core table already has the complete expected row count;
--            partial core loads raise an exception instead of being ignored.
-- Status   : Generated from the supplied CSVs; not yet executed in PostgreSQL.
-- Cleaning: strip the verified injected suffix from 4 return_id values.
-- Returns associated with cancelled or shipped orders are retained as source
-- business-rule exceptions; this import does not discard them.
-- =============================================================================

\set ON_ERROR_STOP on
\timing on

BEGIN;

-- 1. Reload raw source rows. The staging table preserves the source values.
TRUNCATE TABLE staging.returns;
\copy staging.returns (return_id, order_id, order_item_id, product_id, return_date, reason, refund_amount) FROM 'returns(1).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- 2. Validate the raw load before transforming it.
DO $$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows FROM staging.returns;
    IF v_rows <> 400293 THEN
        RAISE EXCEPTION 'staging.returns: expected 400293 rows, found %', v_rows;
    END IF;
    IF EXISTS (
        SELECT 1 FROM staging.returns
        WHERE return_id IS NULL OR btrim(return_id) = ''
    ) THEN
        RAISE EXCEPTION 'staging.returns: blank or NULL key value found in return_id';
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'staging', 'returns', count(*), 400293, 'returns(1).csv; raw staging reload'
FROM staging.returns;

-- 3. Validate normalized identifiers and parent-table dependencies.
DO $$
BEGIN
    IF (SELECT count(*) FROM staging.returns WHERE right(return_id, length('_zdl26nr51f60aaa959f')) = '_zdl26nr51f60aaa959f') <> 4 THEN
        RAISE EXCEPTION 'returns.csv: expected 4 return_id values with the injected suffix';
    END IF;
    IF EXISTS (SELECT regexp_replace(return_id, '_zdl26nr51f60aaa959f$', '') FROM staging.returns GROUP BY regexp_replace(return_id, '_zdl26nr51f60aaa959f$', '') HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'returns.csv: duplicate return_id after suffix normalization';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.returns r LEFT JOIN core.orders o ON o.order_id=r.order_id WHERE o.order_id IS NULL) THEN
        RAISE EXCEPTION 'returns.csv: order_id does not resolve to core.orders';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.returns r LEFT JOIN core.order_items oi ON oi.order_item_id=r.order_item_id WHERE oi.order_item_id IS NULL) THEN
        RAISE EXCEPTION 'returns.csv: order_item_id does not resolve to core.order_items';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.returns r LEFT JOIN core.products p ON p.product_id=r.product_id WHERE p.product_id IS NULL) THEN
        RAISE EXCEPTION 'returns.csv: product_id does not resolve to core.products';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.returns r JOIN core.order_items oi ON oi.order_item_id=r.order_item_id WHERE r.refund_amount::numeric <> oi.line_total) THEN
        RAISE EXCEPTION 'returns.csv: refund_amount differs from the corresponding full order-item line_total';
    END IF;
END $$;

-- Refuse partial or duplicate core loads. An empty table is loaded;
-- a complete table is retained; any partial state requires investigation.
DO $$
DECLARE
    v_core_rows bigint;
BEGIN
    SELECT count(*) INTO v_core_rows FROM core.returns;
    IF v_core_rows NOT IN (0, 400293) THEN
        RAISE EXCEPTION 'core.returns: expected either 0 or 400293 rows before import, found %', v_core_rows;
    END IF;
    IF EXISTS (SELECT return_id FROM staging.returns GROUP BY return_id HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'staging.returns: duplicate key values found';
    END IF;
END $$;

-- 4. Transform and insert into the typed core table.
INSERT INTO core.returns (return_id, order_id, order_item_id, product_id, return_date, reason, refund_amount)
SELECT regexp_replace(s.return_id, '_zdl26nr51f60aaa959f$', ''),
       s.order_id, s.order_item_id, s.product_id,
       s.return_date::date, s.reason, s.refund_amount::numeric(12,2)
FROM staging.returns AS s
WHERE NOT EXISTS (SELECT 1 FROM core.returns);

DO $$
DECLARE
    v_rows bigint;
    v_distinct bigint;
BEGIN
    SELECT count(*), count(DISTINCT return_id)
      INTO v_rows, v_distinct
      FROM core.returns;
    IF v_rows <> 400293 OR v_distinct <> 400293 THEN
        RAISE EXCEPTION 'core.returns: expected 400293 rows and unique return_id; found rows %, distinct keys %', v_rows, v_distinct;
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'core', 'returns', count(*), 400293, 'core row count after import or verified rerun'
FROM core.returns;

COMMIT;

SELECT 'returns' AS table_name,
       (SELECT count(*) FROM staging.returns) AS staging_rows,
       (SELECT count(*) FROM core.returns) AS core_rows,
       400293::bigint AS expected_rows;
