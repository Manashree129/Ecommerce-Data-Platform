-- =============================================================================
-- 07_crud_operations/select.sql
-- Purpose: Demonstrate SELECT queries for individual records and joined views.
-- Read-only: Safe to run against the loaded core schema.
-- =============================================================================

-- 1. Inspect a customer by its primary key (replace with an existing ID).
SELECT *
FROM core.customers
WHERE customer_id = 'REPLACE_WITH_CUSTOMER_ID';

-- 2. Browse a limited set of recent orders.
SELECT order_id, customer_id, order_date, status, order_total, payment_method
FROM core.orders
ORDER BY order_date DESC, order_id
LIMIT 50;

-- 3. Inspect order lines with product details.
SELECT
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    p.brand,
    c.category_name,
    sc.subcategory_name,
    oi.quantity,
    oi.unit_price,
    oi.line_total
FROM core.order_items AS oi
JOIN core.products AS p
  ON p.product_id = oi.product_id
JOIN core.subcategories AS sc
  ON sc.subcategory_id = p.subcategory_id
JOIN core.categories AS c
  ON c.category_id = sc.category_id
ORDER BY oi.order_id, oi.order_item_id
LIMIT 100;

-- 4. Customer order summary.
SELECT
    c.customer_id,
    c.region,
    count(o.order_id) AS order_count,
    coalesce(sum(o.order_total), 0) AS gross_order_value
FROM core.customers AS c
LEFT JOIN core.orders AS o
  ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.region
ORDER BY gross_order_value DESC
LIMIT 50;
