-- COUNT, SUM, AVG, MIN, MAX, GROUP BY and HAVING
SELECT status,count(*) AS order_count,sum(order_total) AS total_value,avg(order_total) AS avg_value FROM core.orders GROUP BY status ORDER BY order_count DESC;
SELECT c.region,count(DISTINCT o.order_id) AS orders,sum(o.order_total) AS order_value,avg(o.order_total) AS avg_order_value FROM core.customers c JOIN core.orders o USING(customer_id) GROUP BY c.region ORDER BY order_value DESC;
SELECT cat.category_name,count(DISTINCT oi.order_id) AS orders,sum(oi.quantity) AS units_sold,sum(oi.line_total) AS line_value FROM core.order_items oi JOIN core.products p USING(product_id) JOIN core.subcategories sc USING(subcategory_id) JOIN core.categories cat USING(category_id) GROUP BY cat.category_name HAVING sum(oi.line_total)>0 ORDER BY line_value DESC;
SELECT customer_id,count(*) AS order_count FROM core.orders GROUP BY customer_id HAVING count(*)>5 ORDER BY order_count DESC LIMIT 100;
