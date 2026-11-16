-- 10_views/create_views.sql
-- Re-runnable view definitions for the reporting layer.

CREATE OR REPLACE VIEW reporting.vw_order_details AS
SELECT o.order_id, o.order_date, o.status, o.payment_method,
       o.customer_id, c.region, c.segment,
       o.session_id, o.item_count, o.order_total
FROM core.orders AS o
JOIN core.customers AS c ON c.customer_id = o.customer_id;

CREATE OR REPLACE VIEW reporting.vw_product_catalogue AS
SELECT p.product_id, p.brand, p.price, p.cost, p.avg_rating, p.launch_date,
       sc.subcategory_name, cat.category_name
FROM core.products AS p
JOIN core.subcategories AS sc ON sc.subcategory_id = p.subcategory_id
JOIN core.categories AS cat ON cat.category_id = sc.category_id;

CREATE OR REPLACE VIEW reporting.vw_category_sales AS
SELECT cat.category_id, cat.category_name,
       count(DISTINCT oi.order_id) AS order_count,
       sum(oi.quantity) AS units_sold,
       sum(oi.line_total) AS gross_line_value
FROM core.order_items AS oi
JOIN core.products AS p ON p.product_id = oi.product_id
JOIN core.subcategories AS sc ON sc.subcategory_id = p.subcategory_id
JOIN core.categories AS cat ON cat.category_id = sc.category_id
GROUP BY cat.category_id, cat.category_name;

CREATE OR REPLACE VIEW reporting.vw_customer_order_summary AS
SELECT c.customer_id, c.region, c.segment,
       count(o.order_id) AS order_count,
       coalesce(sum(o.order_total), 0) AS historical_order_value,
       max(o.order_date) AS most_recent_order_date
FROM core.customers AS c
LEFT JOIN core.orders AS o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.region, c.segment;

CREATE OR REPLACE VIEW reporting.vw_return_summary AS
SELECT r.product_id, p.brand,
       count(*) AS return_record_count,
       sum(r.refund_amount) AS total_refund_amount
FROM core.returns AS r
JOIN core.products AS p ON p.product_id = r.product_id
GROUP BY r.product_id, p.brand;
