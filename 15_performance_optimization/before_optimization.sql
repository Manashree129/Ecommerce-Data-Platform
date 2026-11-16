
/*
MODULE 15: PERFORMANCE OPTIMIZATION
FILE: before_optimization.sql

Purpose:
Measure query performance before
adding the performance indexes.

Run this before indexing.sql,
composite_indexes.sql and partial_indexes.sql.
*/

-- Check existing indexes first
SELECT
    tablename,
    indexname
FROM pg_indexes
WHERE schemaname = 'core'
ORDER BY tablename, indexname;


-- Baseline query:
-- Retrieve order items for one customer.

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    o.customer_id,
    o.order_id,
    oi.product_id,
    oi.quantity,
    oi.line_total
FROM core.orders AS o
INNER JOIN core.order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.customer_id =
(
    SELECT MIN(customer_id)
    FROM core.orders
);


-- Record these metrics from the execution plan:
-- 1. Execution Time
-- 2. Planning Time
-- 3. Shared Hit Blocks
-- 4. Shared Read Blocks
-- 5. Scan types
-- 6. Estimated rows vs actual rows
