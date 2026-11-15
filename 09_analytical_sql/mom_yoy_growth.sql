-- Month-over-month and year-over-year growth. Growth is NULL when prior period is zero/missing.

WITH monthly AS (
    SELECT date_trunc('month', order_date)::date AS month_start,
           SUM(order_total) AS order_value
    FROM core.orders GROUP BY 1
), compared AS (
    SELECT month_start, order_value,
           LAG(order_value) OVER (ORDER BY month_start) AS previous_month_value,
           LAG(order_value, 12) OVER (ORDER BY month_start) AS previous_year_month_value
    FROM monthly
)
SELECT month_start, order_value, previous_month_value,
       ROUND(100.0 * (order_value - previous_month_value) / NULLIF(previous_month_value, 0), 2) AS mom_growth_pct,
       previous_year_month_value,
       ROUND(100.0 * (order_value - previous_year_month_value) / NULLIF(previous_year_month_value, 0), 2) AS yoy_growth_pct
FROM compared ORDER BY month_start;

-- Annual order value and year-over-year growth
WITH yearly AS (
    SELECT EXTRACT(YEAR FROM order_date)::int AS order_year,
           SUM(order_total) AS order_value
    FROM core.orders GROUP BY 1
), prior AS (
    SELECT order_year, order_value,
           LAG(order_value) OVER (ORDER BY order_year) AS prior_year_value
    FROM yearly
)
SELECT order_year, order_value, prior_year_value,
       ROUND(100.0 * (order_value - prior_year_value) / NULLIF(prior_year_value, 0), 2) AS yoy_growth_pct
FROM prior ORDER BY order_year;
