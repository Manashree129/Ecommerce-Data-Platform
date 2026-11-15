-- =============================================================================
-- File     : sql/03_table_creation/core_tables.sql
-- Purpose  : Create the typed core tables.
-- Depends  : 02_schema_creation/create_schemas.sql
-- Rerun    : Safe (CREATE TABLE IF NOT EXISTS). If a column type must change,
--            use ALTER TABLE; IF NOT EXISTS will not modify an existing table.
-- Status   : Not executed against PostgreSQL by the author of this script.
--
-- Scope of this file
--   Columns, data types, NOT NULL and documentation only. PRIMARY KEY, FOREIGN
--   KEY, UNIQUE, CHECK and DEFAULT constraints are added AFTER the bulk load and
--   validation, in 06_constraints. Adding keys after a 4-7M row load is much
--   faster than maintaining them during the load, and validation (module 05)
--   gets to look at the data before any constraint can reject it.
--
-- Column names are identical to the CSV headers. No columns were added.
--
-- Type choices (from measured value ranges in the uploaded files)
--   * IDs are text: they are formatted natural keys (C00000001, SKU000001,
--     OI000000000001 ...). Surrogate keys would be invented columns.
--   * Money is numeric(p,2), never float. Largest observed values:
--       unit_price 950.74, line_total 3,802.96, order_total 5,243.80,
--       lifetime_spend 12,080.82, refund_amount 3,802.96.
--   * Dates are date: every date column in the CSVs is YYYY-MM-DD with no time
--     component (including sessions.session_start).
--   * avg_rating is numeric(2,1): one decimal, observed range 2.1 to 5.0.
--   * quantity (1-4), item_count (1-17), pages_viewed (1-20) and
--     resolution_days (1-13) fit smallint.
-- =============================================================================

\set ON_ERROR_STOP on

CREATE TABLE IF NOT EXISTS core.customers (
    customer_id     text          NOT NULL,
    signup_date     date          NOT NULL,
    region          text          NOT NULL,
    segment         text          NOT NULL,
    lifetime_orders integer       NOT NULL,
    lifetime_spend  numeric(12,2) NOT NULL,
    email_domain    text          NOT NULL
);

CREATE TABLE IF NOT EXISTS core.products (
    product_id   text          NOT NULL,
    category     text          NOT NULL,
    subcategory  text          NOT NULL,
    price        numeric(10,2) NOT NULL,
    cost         numeric(10,2) NOT NULL,
    brand        text          NOT NULL,
    launch_date  date          NOT NULL,
    avg_rating   numeric(2,1)  NOT NULL
);

CREATE TABLE IF NOT EXISTS core.sessions (
    session_id    text     NOT NULL,
    customer_id   text     NOT NULL,
    session_start date     NOT NULL,
    device        text     NOT NULL,
    channel       text     NOT NULL,
    pages_viewed  smallint NOT NULL,
    converted     boolean  NOT NULL
);

CREATE TABLE IF NOT EXISTS core.orders (
    order_id       text          NOT NULL,
    customer_id    text          NOT NULL,
    session_id     text          NOT NULL,
    order_date     date          NOT NULL,
    status         text          NOT NULL,
    item_count     smallint      NOT NULL,
    order_total    numeric(12,2) NOT NULL,
    payment_method text          NOT NULL
);

CREATE TABLE IF NOT EXISTS core.order_items (
    order_item_id text          NOT NULL,
    order_id      text          NOT NULL,
    product_id    text          NOT NULL,
    quantity      smallint      NOT NULL,
    unit_price    numeric(10,2) NOT NULL,
    line_total    numeric(12,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS core.returns (
    return_id     text          NOT NULL,
    order_id      text          NOT NULL,
    order_item_id text          NOT NULL,
    product_id    text          NOT NULL,
    return_date   date          NOT NULL,
    reason        text          NOT NULL,
    refund_amount numeric(12,2) NOT NULL
);

-- resolution_days is the only nullable column in the dataset: NULL means the
-- ticket is not yet resolved (see column comment).
CREATE TABLE IF NOT EXISTS core.support_tickets (
    ticket_id       text     NOT NULL,
    customer_id     text     NOT NULL,
    order_id        text     NOT NULL,
    created_date    date     NOT NULL,
    category        text     NOT NULL,
    priority        text     NOT NULL,
    status          text     NOT NULL,
    resolution_days smallint
);

-- -----------------------------------------------------------------------------
-- Documentation of verified business meaning (each statement was checked
-- against the uploaded CSVs; counts of mismatches were 0 unless stated).
-- -----------------------------------------------------------------------------
COMMENT ON COLUMN core.customers.lifetime_orders IS
    'Number of the customer''s orders with status delivered or shipped. Cancelled and returned orders are not counted.';
COMMENT ON COLUMN core.customers.lifetime_spend IS
    'Sum of order_total over the customer''s delivered/shipped orders, minus refund_amount of returns filed against those orders.';

COMMENT ON COLUMN core.sessions.session_start IS
    'Date only; the source has no time-of-day component.';
COMMENT ON COLUMN core.sessions.converted IS
    'True for exactly the sessions that produced an order (1:1 with orders.session_id, same customer, same day).';

COMMENT ON COLUMN core.orders.session_id IS
    'The converting session. One-to-one: no session is shared by two orders.';
COMMENT ON COLUMN core.orders.item_count IS
    'Number of order_items rows (lines) in the order. It is NOT the sum of quantity.';
COMMENT ON COLUMN core.orders.order_total IS
    'Equals sum(order_items.line_total) for the order. Applies to orders of every status, including cancelled.';

COMMENT ON COLUMN core.order_items.unit_price IS
    'Equals products.price for the product in every row of the source data.';
COMMENT ON COLUMN core.order_items.line_total IS
    'Equals quantity * unit_price.';

COMMENT ON COLUMN core.returns.refund_amount IS
    'Equals the line_total of the returned order line (full-line refund) in every row of the source data.';

COMMENT ON COLUMN core.support_tickets.resolution_days IS
    'Days to resolve (1-13). NULL = unresolved. The source file stores -1 for these; the import converts -1 to NULL. In the source, -1 occurs only for status open/in_progress and every open/in_progress ticket has -1.';

-- Verify: tables, column counts and approximate row counts (0 before import).
SELECT c.relname AS table_name,
       (SELECT count(*) FROM pg_attribute AS a
         WHERE a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped) AS column_count
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'core' AND c.relkind = 'r'
ORDER BY c.relname;
