-- CLV proxy from available historical data; this is observed cumulative order value,
-- not a predictive or forward-looking lifetime value model.

WITH customer_value AS (
    SELECT c.customer_id, c.region, c.segment,
           COUNT(o.order_id) AS observed_order_count,
           COALESCE(SUM(o.order_total), 0) AS observed_order_value,
           MIN(o.order_date) AS first_order_date,
           MAX(o.order_date) AS latest_order_date
    FROM core.customers c
    LEFT JOIN core.orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.region, c.segment
)
SELECT *,
       ROUND(observed_order_value / NULLIF(observed_order_count, 0), 2) AS observed_avg_order_value
FROM customer_value
ORDER BY observed_order_value DESC
LIMIT 500;

-- Compare customer table lifetime_spend with sum of order_total (data reconciliation)
SELECT c.customer_id, c.lifetime_spend,
       COALESCE(SUM(o.order_total), 0) AS summed_order_total,
       c.lifetime_spend - COALESCE(SUM(o.order_total), 0) AS spend_difference
FROM core.customers c
LEFT JOIN core.orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.lifetime_spend
ORDER BY ABS(c.lifetime_spend - COALESCE(SUM(o.order_total), 0)) DESC
LIMIT 100;
