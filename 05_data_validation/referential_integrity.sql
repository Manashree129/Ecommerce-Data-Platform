-- Find orphan foreign-key values before constraints are added. Every count
-- should be zero. These checks validate child-to-parent relationships.
SELECT 'sessions.customer_id -> customers.customer_id' relationship,count(*) orphan_rows FROM core.sessions s LEFT JOIN core.customers c USING(customer_id) WHERE c.customer_id IS NULL
UNION ALL SELECT 'orders.customer_id -> customers.customer_id',count(*) FROM core.orders o LEFT JOIN core.customers c USING(customer_id) WHERE c.customer_id IS NULL
UNION ALL SELECT 'orders.session_id -> sessions.session_id',count(*) FROM core.orders o LEFT JOIN core.sessions s USING(session_id) WHERE s.session_id IS NULL
UNION ALL SELECT 'order_items.order_id -> orders.order_id',count(*) FROM core.order_items oi LEFT JOIN core.orders o USING(order_id) WHERE o.order_id IS NULL
UNION ALL SELECT 'order_items.product_id -> products.product_id',count(*) FROM core.order_items oi LEFT JOIN core.products p USING(product_id) WHERE p.product_id IS NULL
UNION ALL SELECT 'returns.order_id -> orders.order_id',count(*) FROM core.returns r LEFT JOIN core.orders o USING(order_id) WHERE o.order_id IS NULL
UNION ALL SELECT 'returns.order_item_id -> order_items.order_item_id',count(*) FROM core.returns r LEFT JOIN core.order_items oi USING(order_item_id) WHERE oi.order_item_id IS NULL
UNION ALL SELECT 'returns.product_id -> products.product_id',count(*) FROM core.returns r LEFT JOIN core.products p USING(product_id) WHERE p.product_id IS NULL
UNION ALL SELECT 'support_tickets.customer_id -> customers.customer_id',count(*) FROM core.support_tickets st LEFT JOIN core.customers c USING(customer_id) WHERE c.customer_id IS NULL
UNION ALL SELECT 'support_tickets.order_id -> orders.order_id',count(*) FROM core.support_tickets st LEFT JOIN core.orders o USING(order_id) WHERE o.order_id IS NULL
UNION ALL SELECT 'products.subcategory_id -> subcategories.subcategory_id',count(*) FROM core.products p LEFT JOIN core.subcategories sc USING(subcategory_id) WHERE sc.subcategory_id IS NULL
UNION ALL SELECT 'subcategories.category_id -> categories.category_id',count(*) FROM core.subcategories sc LEFT JOIN core.categories c USING(category_id) WHERE c.category_id IS NULL
ORDER BY relationship;
