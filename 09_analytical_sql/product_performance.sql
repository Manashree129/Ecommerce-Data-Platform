-- Product performance from order-item facts.
-- line_total is used to avoid multiplying order-level totals across item rows.

SELECT p.product_id, p.brand, cat.category_name, sc.subcategory_name,
       SUM(oi.quantity) AS units_sold,
       COUNT(DISTINCT oi.order_id) AS orders_containing_product,
       SUM(oi.line_total) AS gross_item_line_value,
       SUM(oi.quantity * p.cost) AS estimated_product_cost,
       SUM(oi.line_total) - SUM(oi.quantity * p.cost) AS estimated_gross_margin
FROM core.order_items oi
JOIN core.products p ON p.product_id = oi.product_id
JOIN core.subcategories sc ON sc.subcategory_id = p.subcategory_id
JOIN core.categories cat ON cat.category_id = sc.category_id
GROUP BY p.product_id, p.brand, cat.category_name, sc.subcategory_name
ORDER BY gross_item_line_value DESC
LIMIT 500;

-- Category-level performance
SELECT cat.category_name, SUM(oi.quantity) AS units_sold,
       SUM(oi.line_total) AS gross_item_line_value,
       COUNT(DISTINCT oi.order_id) AS distinct_orders
FROM core.order_items oi
JOIN core.products p ON p.product_id = oi.product_id
JOIN core.subcategories sc ON sc.subcategory_id = p.subcategory_id
JOIN core.categories cat ON cat.category_id = sc.category_id
GROUP BY cat.category_name ORDER BY gross_item_line_value DESC;
