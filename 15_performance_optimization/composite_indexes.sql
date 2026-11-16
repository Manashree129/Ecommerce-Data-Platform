
/*
MODULE 15: PERFORMANCE OPTIMIZATION
FILE: composite_indexes.sql

Purpose:
Create multi-column indexes for common
ecommerce query patterns.
*/

-- Customer order lookup, with order_id available
-- as the second indexed column.
CREATE INDEX IF NOT EXISTS idx_orders_customer_order
ON core.orders (customer_id, order_id);


-- Product order-item lookup, with order_id
-- available for further filtering or joining.
CREATE INDEX IF NOT EXISTS idx_order_items_product_order
ON core.order_items (product_id, order_id);


-- Refresh statistics
ANALYZE core.orders;
ANALYZE core.order_items;


-- Verify composite indexes
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'core'
AND indexname IN
(
    'idx_orders_customer_order',
    'idx_order_items_product_order'
);
