-- =============================================================================
-- File     : sql/03_table_creation/staging_tables.sql
-- Purpose  : Create raw landing tables for the seven CSV files, plus the
--            audit.load_log table that the import scripts write to.
-- Depends  : 02_schema_creation/create_schemas.sql
-- Rerun    : Safe (CREATE TABLE IF NOT EXISTS; nothing is dropped).
-- Status   : Not executed against PostgreSQL by the author of this script.
--
-- Design decisions (based on inspection of the actual CSV files)
--   * Every staging column is TEXT. This lets COPY succeed on any value and
--     moves all type conversion and cleaning into one visible place: the
--     INSERT ... SELECT in 04_data_import. Raw values are kept untouched so
--     defects (e.g. the ID suffix described in 04_data_import) stay auditable.
--   * UNLOGGED: staging is reloadable from the CSVs, so crash-safety is not
--     needed and skipping WAL speeds the ~14.3M-row load. Contents are lost
--     after a server crash; just re-run the import scripts.
--   * No keys or indexes on staging. Uniqueness and integrity are verified
--     on core after loading (05_data_validation, 06_constraints).
--
-- Expected CSV row counts (excluding header), measured from the uploaded files
--   customers 1,000,000 | products 50,000 | sessions 7,455,296
--   orders 1,075,683 | order_items 4,280,732 | returns 400,293
--   support_tickets 66,938 | total 14,328,942
-- =============================================================================

\set ON_ERROR_STOP on

-- -----------------------------------------------------------------------------
-- Load log (audit schema): one row per table per load step.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit.load_log (
    load_id       bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    loaded_at     timestamptz NOT NULL DEFAULT now(),
    stage         text        NOT NULL CHECK (stage IN ('staging', 'core')),
    table_name    text        NOT NULL,
    rows_loaded   bigint      NOT NULL,
    rows_expected bigint,
    note          text
);
COMMENT ON TABLE audit.load_log IS 'History of import runs: rows loaded versus rows expected from the CSV files.';

-- -----------------------------------------------------------------------------
-- staging.customers  <- customers.csv
-- -----------------------------------------------------------------------------
CREATE UNLOGGED TABLE IF NOT EXISTS staging.customers (
    customer_id     text,
    signup_date     text,
    region          text,
    segment         text,
    lifetime_orders text,
    lifetime_spend  text,
    email_domain    text
);

-- -----------------------------------------------------------------------------
-- staging.products  <- products.csv
-- -----------------------------------------------------------------------------
CREATE UNLOGGED TABLE IF NOT EXISTS staging.products (
    product_id   text,
    category     text,
    subcategory  text,
    price        text,
    cost         text,
    brand        text,
    launch_date  text,
    avg_rating   text
);

-- -----------------------------------------------------------------------------
-- staging.sessions  <- sessions.csv
-- -----------------------------------------------------------------------------
CREATE UNLOGGED TABLE IF NOT EXISTS staging.sessions (
    session_id    text,
    customer_id   text,
    session_start text,
    device        text,
    channel       text,
    pages_viewed  text,
    converted     text
);

-- -----------------------------------------------------------------------------
-- staging.orders  <- orders.csv
-- -----------------------------------------------------------------------------
CREATE UNLOGGED TABLE IF NOT EXISTS staging.orders (
    order_id       text,
    customer_id    text,
    session_id     text,
    order_date     text,
    status         text,
    item_count     text,
    order_total    text,
    payment_method text
);

-- -----------------------------------------------------------------------------
-- staging.order_items  <- order_items.csv
-- -----------------------------------------------------------------------------
CREATE UNLOGGED TABLE IF NOT EXISTS staging.order_items (
    order_item_id text,
    order_id      text,
    product_id    text,
    quantity      text,
    unit_price    text,
    line_total    text
);

-- -----------------------------------------------------------------------------
-- staging.returns  <- returns.csv
-- -----------------------------------------------------------------------------
CREATE UNLOGGED TABLE IF NOT EXISTS staging.returns (
    return_id     text,
    order_id      text,
    order_item_id text,
    product_id    text,
    return_date   text,
    reason        text,
    refund_amount text
);

-- -----------------------------------------------------------------------------
-- staging.support_tickets  <- support_tickets.csv
-- -----------------------------------------------------------------------------
CREATE UNLOGGED TABLE IF NOT EXISTS staging.support_tickets (
    ticket_id       text,
    customer_id     text,
    order_id        text,
    created_date    text,
    category        text,
    priority        text,
    status          text,
    resolution_days text
);

COMMENT ON TABLE staging.customers       IS 'Raw copy of customers.csv (expected 1,000,000 rows).';
COMMENT ON TABLE staging.products        IS 'Raw copy of products.csv (expected 50,000 rows).';
COMMENT ON TABLE staging.sessions        IS 'Raw copy of sessions.csv (expected 7,455,296 rows).';
COMMENT ON TABLE staging.orders          IS 'Raw copy of orders.csv (expected 1,075,683 rows).';
COMMENT ON TABLE staging.order_items     IS 'Raw copy of order_items.csv (expected 4,280,732 rows).';
COMMENT ON TABLE staging.returns         IS 'Raw copy of returns.csv (expected 400,293 rows).';
COMMENT ON TABLE staging.support_tickets IS 'Raw copy of support_tickets.csv (expected 66,938 rows).';

-- Verify: list the staging tables and their column counts.
SELECT c.relname AS table_name,
       c.relpersistence AS persistence,   -- 'u' = unlogged
       (SELECT count(*) FROM pg_attribute AS a
         WHERE a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped) AS column_count
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'staging' AND c.relkind = 'r'
ORDER BY c.relname;
