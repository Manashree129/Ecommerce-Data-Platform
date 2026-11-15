-- Repeat-purchase retention proxy based on distinct order activity.
-- This is not subscription retention; it measures customers ordering in multiple periods.

WITH customer_months AS (
    SELECT DISTINCT customer_id, date_trunc('month', order_date)::date AS order_month
    FROM core.orders
), customer_month_counts AS (
    SELECT customer_id, COUNT(*) AS active_months,
           MIN(order_month) AS first_active_month,
           MAX(order_month) AS last_active_month
    FROM customer_months GROUP BY customer_id
)
SELECT active_months, COUNT(*) AS customer_count
FROM customer_month_counts
GROUP BY active_months ORDER BY active_months;

-- Customers active in consecutive calendar months
WITH monthly_customers AS (
    SELECT DISTINCT customer_id, date_trunc('month', order_date)::date AS month_start
    FROM core.orders
)
SELECT current_month.month_start,
       COUNT(*) AS customers_active_this_and_previous_month
FROM monthly_customers current_month
JOIN monthly_customers previous_month
  ON previous_month.customer_id = current_month.customer_id
 AND previous_month.month_start = current_month.month_start - INTERVAL '1 month'
GROUP BY current_month.month_start
ORDER BY current_month.month_start;
