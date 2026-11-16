-- 10_views/create_materialized_views.sql
-- Materialized views persist query results; refresh after relevant data loads.

CREATE MATERIALIZED VIEW reporting.mv_monthly_sales AS
SELECT date_trunc('month', o.order_date)::date AS sales_month,
       count(*) AS order_count,
       sum(o.order_total) AS order_value,
       avg(o.order_total) AS average_order_value
FROM core.orders AS o
GROUP BY date_trunc('month', o.order_date)::date
WITH DATA;

CREATE UNIQUE INDEX uq_mv_monthly_sales_month
    ON reporting.mv_monthly_sales (sales_month);

CREATE MATERIALIZED VIEW reporting.mv_category_performance AS
SELECT cat.category_id, cat.category_name,
       sum(oi.quantity) AS units_sold,
       sum(oi.line_total) AS gross_line_value,
       count(DISTINCT oi.order_id) AS order_count
FROM core.order_items AS oi
JOIN core.products AS p ON p.product_id = oi.product_id
JOIN core.subcategories AS sc ON sc.subcategory_id = p.subcategory_id
JOIN core.categories AS cat ON cat.category_id = sc.category_id
GROUP BY cat.category_id, cat.category_name
WITH DATA;

CREATE UNIQUE INDEX uq_mv_category_performance_category
    ON reporting.mv_category_performance (category_id);

-- Run manually after source tables change:
-- REFRESH MATERIALIZED VIEW reporting.mv_monthly_sales;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY reporting.mv_monthly_sales;
-- CONCURRENTLY requires a qualifying unique index and the view must already be populated.
