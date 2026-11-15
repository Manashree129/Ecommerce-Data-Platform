-- Sales trend analysis using order-level metrics.

-- Daily order trend
SELECT order_date, COUNT(*) AS order_count, SUM(order_total) AS order_value
FROM core.orders GROUP BY order_date ORDER BY order_date;

-- Monthly trend
SELECT date_trunc('month', order_date)::date AS month_start,
       COUNT(*) AS order_count, SUM(order_total) AS order_value,
       AVG(order_total) AS average_order_value
FROM core.orders GROUP BY 1 ORDER BY 1;

-- Monthly trend by order status
SELECT date_trunc('month', order_date)::date AS month_start, status,
       COUNT(*) AS order_count, SUM(order_total) AS order_value
FROM core.orders GROUP BY 1, 2 ORDER BY 1, 2;
