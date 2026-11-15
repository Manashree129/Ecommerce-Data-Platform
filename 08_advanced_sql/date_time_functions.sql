-- Date analysis (source date columns are DATE values)
SELECT extract(year FROM order_date)::int AS order_year,extract(month FROM order_date)::int AS order_month,count(*) AS order_count,sum(order_total) AS order_value FROM core.orders GROUP BY 1,2 ORDER BY 1,2;
SELECT date_trunc('month',order_date)::date AS order_month,count(*) AS order_count,sum(order_total) AS order_value FROM core.orders GROUP BY 1 ORDER BY 1;
WITH latest AS (SELECT max(order_date) AS max_date FROM core.orders) SELECT o.order_id,o.order_date,o.order_total FROM core.orders o CROSS JOIN latest l WHERE o.order_date>=l.max_date-29 ORDER BY o.order_date DESC LIMIT 100;
SELECT c.customer_id,c.signup_date,min(o.order_date) AS first_order_date,min(o.order_date)-c.signup_date AS days_to_first_order FROM core.customers c JOIN core.orders o USING(customer_id) GROUP BY c.customer_id,c.signup_date ORDER BY days_to_first_order LIMIT 100;
SELECT to_char(return_date,'Day') AS weekday,extract(isodow FROM return_date)::int AS weekday_number,count(*) AS return_count,sum(refund_amount) AS refund_value FROM core.returns GROUP BY 1,2 ORDER BY weekday_number;
