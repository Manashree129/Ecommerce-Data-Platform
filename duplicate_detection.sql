-- Detect duplicate values in columns intended to become primary/natural keys.
-- Do not require (order_id, product_id) to be unique: source profiling found
-- 156 repeated pairs, so that pair is not a valid unique key.
SELECT 'customers.customer_id' key_name,count(*) duplicate_groups FROM (SELECT customer_id FROM core.customers GROUP BY customer_id HAVING count(*)>1) d
UNION ALL SELECT 'products.product_id',count(*) FROM (SELECT product_id FROM core.products GROUP BY product_id HAVING count(*)>1) d
UNION ALL SELECT 'sessions.session_id',count(*) FROM (SELECT session_id FROM core.sessions GROUP BY session_id HAVING count(*)>1) d
UNION ALL SELECT 'orders.order_id',count(*) FROM (SELECT order_id FROM core.orders GROUP BY order_id HAVING count(*)>1) d
UNION ALL SELECT 'order_items.order_item_id',count(*) FROM (SELECT order_item_id FROM core.order_items GROUP BY order_item_id HAVING count(*)>1) d
UNION ALL SELECT 'returns.return_id',count(*) FROM (SELECT return_id FROM core.returns GROUP BY return_id HAVING count(*)>1) d
UNION ALL SELECT 'support_tickets.ticket_id',count(*) FROM (SELECT ticket_id FROM core.support_tickets GROUP BY ticket_id HAVING count(*)>1) d
UNION ALL SELECT 'categories.category_name',count(*) FROM (SELECT category_name FROM core.categories GROUP BY category_name HAVING count(*)>1) d
UNION ALL SELECT 'subcategories.(category_id,subcategory_name)',count(*) FROM (SELECT category_id,subcategory_name FROM core.subcategories GROUP BY category_id,subcategory_name HAVING count(*)>1) d
ORDER BY key_name;

-- Sample duplicate IDs for investigation; each query should return zero rows.
SELECT customer_id,count(*) occurrences FROM core.customers GROUP BY customer_id HAVING count(*)>1 ORDER BY occurrences DESC LIMIT 100;
SELECT order_item_id,count(*) occurrences FROM core.order_items GROUP BY order_item_id HAVING count(*)>1 ORDER BY occurrences DESC LIMIT 100;
