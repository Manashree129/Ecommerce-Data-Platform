
/*
MODULE 15: PERFORMANCE OPTIMIZATION
FILE: indexing.sql

Purpose:
Create standard indexes for frequently used joins
and filtering operations.

Note:
Primary-key indexes are already created by the
PRIMARY KEY constraints. Do not recreate them.
*/

-- Orders: customer-based order lookup
CREATE INDEX IF NOT EXISTS idx_orders_customer_id
ON core.orders (customer_id);


-- Order items: join orders with order items
CREATE INDEX IF NOT EXISTS idx_order_items_order_id
ON core.order_items (order_id);


-- Order items: product-based analysis
CREATE INDEX IF NOT EXISTS idx_order_items_product_id
ON core.order_items (product_id);


-- Returns: retrieve returns for an order
CREATE INDEX IF NOT EXISTS idx_returns_order_id
ON core.returns (order_id);


-- Sessions: customer activity lookup
CREATE INDEX IF NOT EXISTS idx_sessions_customer_id
ON core.sessions (customer_id);


-- Support tickets: customer support history
CREATE INDEX IF NOT EXISTS idx_support_tickets_customer_id
ON core.support_tickets (customer_id);


-- Update planner statistics after index creation
ANALYZE core.orders;
ANALYZE core.order_items;
ANALYZE core.returns;
ANALYZE core.sessions;
ANALYZE core.support_tickets;


-- Verify indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'core'
ORDER BY tablename, indexname;
