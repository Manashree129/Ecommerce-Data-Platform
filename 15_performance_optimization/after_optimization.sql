
/*
MODULE 15: PERFORMANCE OPTIMIZATION
FILE: after_optimization.sql

Purpose:
Run the same baseline query after index creation
and compare its execution plan.

Prerequisite:
Run indexing.sql, composite_indexes.sql
and partial_indexes.sql first.
*/

-- Refresh planner statistics
ANALYZE core.orders;
ANALYZE core.order_items;


-- Run exactly the same query as the baseline.

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


-- Compare the new plan with the baseline.
-- Do not assume an index scan must always be faster.
-- PostgreSQL may correctly choose a sequential scan
-- when it estimates that reading most of a table
-- is more efficient.
