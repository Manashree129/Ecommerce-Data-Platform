-- Non-correlated subqueries
SELECT order_id,customer_id,order_total FROM core.orders WHERE order_total>(SELECT avg(order_total) FROM core.orders) ORDER BY order_total DESC LIMIT 100;
SELECT p.product_id,cat.category_name,p.price FROM core.products p JOIN core.subcategories sc USING(subcategory_id) JOIN core.categories cat USING(category_id) WHERE p.price>(SELECT avg(p2.price) FROM core.products p2 JOIN core.subcategories sc2 USING(subcategory_id) WHERE sc2.category_id=sc.category_id) ORDER BY p.price DESC LIMIT 100;
SELECT customer_id,region,segment FROM core.customers WHERE customer_id IN (SELECT customer_id FROM core.orders) LIMIT 100;
SELECT order_id,order_total FROM core.orders WHERE order_total IN (SELECT DISTINCT order_total FROM core.orders ORDER BY order_total DESC LIMIT 5) ORDER BY order_total DESC LIMIT 100;
