-- Customer segmentation using available customer attributes and order behavior.

-- Segment and region profile
SELECT segment, region, COUNT(*) AS customer_count,
       AVG(lifetime_orders) AS avg_lifetime_orders,
       AVG(lifetime_spend) AS avg_lifetime_spend
FROM core.customers
GROUP BY segment, region ORDER BY customer_count DESC;

-- Behavioral segments derived from recorded order count
WITH customer_activity AS (
    SELECT c.customer_id, c.region, c.segment,
           COUNT(o.order_id) AS observed_orders,
           COALESCE(SUM(o.order_total), 0) AS observed_order_value
    FROM core.customers c
    LEFT JOIN core.orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.region, c.segment
)
SELECT customer_id, region, segment, observed_orders, observed_order_value,
       CASE WHEN observed_orders = 0 THEN 'No Recorded Orders'
            WHEN observed_orders = 1 THEN 'One-time Customer'
            WHEN observed_orders BETWEEN 2 AND 5 THEN 'Repeat Customer'
            ELSE 'Frequent Customer' END AS behavior_segment
FROM customer_activity
ORDER BY observed_order_value DESC
LIMIT 500;
