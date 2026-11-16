
/*
MODULE 15: PERFORMANCE OPTIMIZATION
FILE: explain_analyze.sql

Purpose:
Investigate PostgreSQL query execution plans,
table statistics and index usage.

Run after creating the Module 15 indexes.
*/


-- =========================================
-- 1. EXECUTION PLAN: CUSTOMER ORDER LOOKUP
-- =========================================

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    o.customer_id,
    o.order_id,
    oi.product_id,
    oi.quantity,
    oi.line_total
FROM core.orders AS o
JOIN core.order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.customer_id =
(
    SELECT MIN(customer_id)
    FROM core.orders
);


-- =========================================
-- 2. EXECUTION PLAN: PRODUCT PERFORMANCE
-- =========================================

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    product_id,
    COUNT(*) AS order_line_count,
    SUM(quantity) AS units_sold,
    SUM(line_total) AS total_sales
FROM core.order_items
WHERE product_id =
(
    SELECT MIN(product_id)
    FROM core.order_items
)
GROUP BY product_id;


-- =========================================
-- 3. EXECUTION PLAN: UNRESOLVED TICKETS
-- =========================================

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    ticket_id,
    customer_id
FROM core.support_tickets
WHERE resolution_days IS NULL;


-- =========================================
-- 4. TABLE SIZE ANALYSIS
-- =========================================

SELECT
    schemaname,
    relname AS table_name,
    pg_size_pretty(
        pg_total_relation_size(relid)
    ) AS total_size,
    pg_size_pretty(
        pg_relation_size(relid)
    ) AS table_size
FROM pg_catalog.pg_statio_user_tables
WHERE schemaname = 'core'
ORDER BY pg_total_relation_size(relid) DESC;


-- =========================================
-- 5. INDEX SIZE ANALYSIS
-- =========================================

SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(
        pg_relation_size(indexrelid)
    ) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'core'
ORDER BY pg_relation_size(indexrelid) DESC;


-- =========================================
-- 6. INDEX USAGE STATISTICS
-- =========================================

SELECT
    schemaname,
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan AS index_scans,
    idx_tup_read AS index_tuples_read,
    idx_tup_fetch AS index_tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'core'
ORDER BY idx_scan DESC, relname;


-- =========================================
-- 7. TABLE SCAN STATISTICS
-- =========================================

SELECT
    schemaname,
    relname AS table_name,
    seq_scan,
    seq_tup_read,
    idx_scan,
    n_live_tup AS estimated_live_rows,
    n_dead_tup AS estimated_dead_rows
FROM pg_stat_user_tables
WHERE schemaname = 'core'
ORDER BY seq_tup_read DESC;


-- =========================================
-- 8. INDEX DEFINITIONS
-- =========================================

SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'core'
ORDER BY tablename, indexname;
