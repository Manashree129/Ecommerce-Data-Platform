-- EXISTS and NOT EXISTS
SELECT c.customer_id,c.region FROM core.customers c WHERE EXISTS(SELECT 1 FROM core.orders o WHERE o.customer_id=c.customer_id) LIMIT 100;
SELECT c.customer_id,c.region FROM core.customers c WHERE NOT EXISTS(SELECT 1 FROM core.orders o WHERE o.customer_id=c.customer_id) LIMIT 100;
SELECT p.product_id,p.brand,p.price FROM core.products p WHERE EXISTS(SELECT 1 FROM core.returns r WHERE r.product_id=p.product_id) LIMIT 100;
SELECT o.order_id,o.order_date,o.order_total FROM core.orders o WHERE NOT EXISTS(SELECT 1 FROM core.returns r WHERE r.order_id=o.order_id) ORDER BY o.order_date DESC LIMIT 100;
