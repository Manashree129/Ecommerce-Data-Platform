-- INNER, LEFT, RIGHT and FULL joins
SELECT o.order_id,o.order_date,o.status,o.order_total,c.region,c.segment FROM core.orders o INNER JOIN core.customers c USING(customer_id) ORDER BY o.order_date DESC LIMIT 100;
SELECT c.customer_id,c.region,count(o.order_id) AS order_count FROM core.customers c LEFT JOIN core.orders o USING(customer_id) GROUP BY c.customer_id,c.region ORDER BY order_count DESC LIMIT 100;
SELECT oi.order_item_id,oi.order_id,p.product_id,cat.category_name,sc.subcategory_name,oi.quantity,oi.line_total FROM core.order_items oi JOIN core.products p USING(product_id) JOIN core.subcategories sc USING(subcategory_id) JOIN core.categories cat USING(category_id) LIMIT 100;
WITH sold AS (SELECT DISTINCT product_id FROM core.order_items) SELECT p.product_id AS catalogue_product_id,s.product_id AS sold_product_id FROM core.products p FULL OUTER JOIN sold s USING(product_id) WHERE p.product_id IS NULL OR s.product_id IS NULL;
SELECT c.customer_id,o.order_id FROM core.orders o RIGHT JOIN core.customers c USING(customer_id) LIMIT 100;
