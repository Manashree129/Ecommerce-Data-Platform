-- Revenue analysis. order_total is order-level value; line_total is item-level value.
-- Avoid summing order_total after joining to order_items (would multiply order value).

-- 1. Overall order value by status
SELECT status, COUNT(*) AS order_count,
       SUM(order_total) AS order_value,
       AVG(order_total) AS average_order_value
FROM core.orders
GROUP BY status
ORDER BY order_value DESC;

-- 2. Monthly order value
SELECT date_trunc('month', order_date)::date AS order_month,
       COUNT(*) AS order_count, SUM(order_total) AS order_value
FROM core.orders
GROUP BY 1 ORDER BY 1;

-- 3. Revenue by customer region
SELECT c.region, COUNT(o.order_id) AS order_count,
       SUM(o.order_total) AS order_value
FROM core.customers c
JOIN core.orders o ON o.customer_id = c.customer_id
GROUP BY c.region ORDER BY order_value DESC;

-- 4. Item-line gross value by product category (distinct metric from order_total)
SELECT cat.category_name, SUM(oi.line_total) AS item_line_value
FROM core.order_items oi
JOIN core.products p ON p.product_id = oi.product_id
JOIN core.subcategories sc ON sc.subcategory_id = p.subcategory_id
JOIN core.categories cat ON cat.category_id = sc.category_id
GROUP BY cat.category_name ORDER BY item_line_value DESC;
