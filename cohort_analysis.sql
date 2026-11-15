-- Monthly acquisition cohorts based on first observed order month.
-- Cohort age 0 is the first order month; subsequent ages are elapsed calendar months.

WITH first_order AS (
    SELECT customer_id, date_trunc('month', MIN(order_date))::date AS cohort_month
    FROM core.orders GROUP BY customer_id
), activity AS (
    SELECT DISTINCT o.customer_id,
           f.cohort_month,
           date_trunc('month', o.order_date)::date AS activity_month
    FROM core.orders o
    JOIN first_order f ON f.customer_id = o.customer_id
), cohort_counts AS (
    SELECT cohort_month,
           ((EXTRACT(YEAR FROM activity_month) - EXTRACT(YEAR FROM cohort_month)) * 12
             + EXTRACT(MONTH FROM activity_month) - EXTRACT(MONTH FROM cohort_month))::int AS cohort_age,
           COUNT(DISTINCT customer_id) AS active_customers
    FROM activity
    GROUP BY cohort_month, cohort_age
), cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_size
    FROM first_order GROUP BY cohort_month
)
SELECT cc.cohort_month, cc.cohort_age, cs.cohort_size, cc.active_customers,
       ROUND(100.0 * cc.active_customers / NULLIF(cs.cohort_size, 0), 2) AS retention_pct
FROM cohort_counts cc
JOIN cohort_sizes cs USING (cohort_month)
ORDER BY cc.cohort_month, cc.cohort_age;
