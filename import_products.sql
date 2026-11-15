-- =============================================================================
-- File     : sql/04_data_import/import_products.sql
-- Project  : FreeEcommerceTwin14M (PostgreSQL)
-- Purpose  : Load products and populate normalized category/subcategory lookup tables
-- Source   : products(1).csv (uploaded dataset filename)
-- Expected : 50,000 data rows (header excluded)
-- Depends  : 03_table_creation/staging_tables.sql, core_tables.sql
-- Run as   : Start psql from the directory containing the seven CSV files,
--            then execute this script with psql -d free_ecommerce_twin_14m -f
--            <path>/import_products.sql.
-- Requires : psql client; this script uses the psql \copy meta-command.
-- Rerun    : Reloads the staging table. Core load is skipped only when the
--            target core table already has the complete expected row count;
--            partial core loads raise an exception instead of being ignored.
-- Status   : Generated from the supplied CSVs; not yet executed in PostgreSQL.
-- Cleaning: no ID changes required. Category/subcategory are normalized into
-- core.categories and core.subcategories. Inspection found 6 categories and
-- 27 subcategories; each subcategory maps to exactly one category.
-- Known characteristic retained: product launch dates may follow some order
-- item dates; this import does not rewrite those source dates.
-- =============================================================================

\set ON_ERROR_STOP on
\timing on

BEGIN;

-- 1. Reload raw source rows. The staging table preserves the source values.
TRUNCATE TABLE staging.products;
\copy staging.products (product_id, category, subcategory, price, cost, brand, launch_date, avg_rating) FROM 'products(1).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- 2. Validate the raw load before transforming it.
DO $$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows FROM staging.products;
    IF v_rows <> 50000 THEN
        RAISE EXCEPTION 'staging.products: expected 50000 rows, found %', v_rows;
    END IF;
    IF EXISTS (
        SELECT 1 FROM staging.products
        WHERE product_id IS NULL OR btrim(product_id) = ''
    ) THEN
        RAISE EXCEPTION 'staging.products: blank or NULL key value found in product_id';
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'staging', 'products', count(*), 50000, 'products(1).csv; raw staging reload'
FROM staging.products;

-- Validate product keys, category labels, and source functional dependency.
DO $$
BEGIN
    IF EXISTS (SELECT product_id FROM staging.products GROUP BY product_id HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'staging.products: duplicate product_id values found';
    END IF;
    IF EXISTS (SELECT 1 FROM staging.products WHERE category IS NULL OR btrim(category) = ''
               OR subcategory IS NULL OR btrim(subcategory) = '') THEN
        RAISE EXCEPTION 'staging.products: blank category or subcategory found';
    END IF;
    IF (SELECT count(DISTINCT category) FROM staging.products) <> 6 THEN
        RAISE EXCEPTION 'products.csv: expected 6 distinct categories';
    END IF;
    IF (SELECT count(DISTINCT (category, subcategory)) FROM staging.products) <> 27 THEN
        RAISE EXCEPTION 'products.csv: expected 27 distinct category/subcategory pairs';
    END IF;
    IF EXISTS (
        SELECT subcategory
        FROM staging.products
        GROUP BY subcategory
        HAVING count(DISTINCT category) > 1
    ) THEN
        RAISE EXCEPTION 'products.csv: a subcategory maps to more than one category';
    END IF;
END $$;

-- Populate lookup tables idempotently by natural name. These tables do not
-- receive formal UNIQUE/FK constraints until the constraints module.
DO $$
BEGIN
    IF EXISTS (SELECT category_name FROM core.categories GROUP BY category_name HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'core.categories contains duplicate category_name values';
    END IF;
    IF EXISTS (
        SELECT category_id, subcategory_name
        FROM core.subcategories
        GROUP BY category_id, subcategory_name
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION 'core.subcategories contains duplicate category/subcategory pairs';
    END IF;
END $$;

INSERT INTO core.categories (category_name)
SELECT DISTINCT s.category
FROM staging.products AS s
WHERE NOT EXISTS (
    SELECT 1 FROM core.categories AS c WHERE c.category_name = s.category
)
ORDER BY s.category;

INSERT INTO core.subcategories (category_id, subcategory_name)
SELECT DISTINCT c.category_id, s.subcategory
FROM staging.products AS s
JOIN core.categories AS c ON c.category_name = s.category
WHERE NOT EXISTS (
    SELECT 1
    FROM core.subcategories AS sc
    WHERE sc.category_id = c.category_id
      AND sc.subcategory_name = s.subcategory
)
ORDER BY c.category_id, s.subcategory;

DO $$
BEGIN
    IF (SELECT count(*) FROM core.categories) <> 6 THEN
        RAISE EXCEPTION 'core.categories must contain exactly 6 rows';
    END IF;
    IF (SELECT count(*) FROM core.subcategories) <> 27 THEN
        RAISE EXCEPTION 'core.subcategories must contain exactly 27 rows';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM staging.products AS s
        LEFT JOIN core.categories AS c ON c.category_name = s.category
        LEFT JOIN core.subcategories AS sc
          ON sc.category_id = c.category_id
         AND sc.subcategory_name = s.subcategory
        WHERE c.category_id IS NULL OR sc.subcategory_id IS NULL
    ) THEN
        RAISE EXCEPTION 'products.csv contains a category/subcategory pair not mapped in core lookup tables';
    END IF;
END $$;

-- Refuse partial or duplicate core loads. An empty table is loaded;
-- a complete table is retained; any partial state requires investigation.
DO $$
DECLARE
    v_core_rows bigint;
BEGIN
    SELECT count(*) INTO v_core_rows FROM core.products;
    IF v_core_rows NOT IN (0, 50000) THEN
        RAISE EXCEPTION 'core.products: expected either 0 or 50000 rows before import, found %', v_core_rows;
    END IF;
    IF EXISTS (SELECT product_id FROM staging.products GROUP BY product_id HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'staging.products: duplicate key values found';
    END IF;
END $$;

-- Insert products using the normalized subcategory lookup.
INSERT INTO core.products (
    product_id, subcategory_id, price, cost, brand, launch_date, avg_rating
)
SELECT s.product_id,
       sc.subcategory_id,
       s.price::numeric(10,2),
       s.cost::numeric(10,2),
       s.brand,
       s.launch_date::date,
       s.avg_rating::numeric(2,1)
FROM staging.products AS s
JOIN core.categories AS c
  ON c.category_name = s.category
JOIN core.subcategories AS sc
  ON sc.category_id = c.category_id
 AND sc.subcategory_name = s.subcategory
WHERE NOT EXISTS (SELECT 1 FROM core.products);

DO $$
DECLARE
    v_rows bigint;
    v_distinct bigint;
BEGIN
    SELECT count(*), count(DISTINCT product_id)
      INTO v_rows, v_distinct
      FROM core.products;
    IF v_rows <> 50000 OR v_distinct <> 50000 THEN
        RAISE EXCEPTION 'core.products: expected 50000 rows and unique product_id; found rows %, distinct keys %', v_rows, v_distinct;
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'core', 'products', count(*), 50000, 'core row count after import or verified rerun'
FROM core.products;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'core', 'categories', count(*), 6, 'normalized product category lookup'
FROM core.categories;
INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'core', 'subcategories', count(*), 27, 'normalized product subcategory lookup'
FROM core.subcategories;

COMMIT;

SELECT 'products' AS table_name,
       (SELECT count(*) FROM staging.products) AS staging_rows,
       (SELECT count(*) FROM core.products) AS core_rows,
       50000::bigint AS expected_rows;
SELECT 'categories' AS table_name, count(*) AS actual_rows, 6 AS expected_rows FROM core.categories;
SELECT 'subcategories' AS table_name, count(*) AS actual_rows, 27 AS expected_rows FROM core.subcategories;
