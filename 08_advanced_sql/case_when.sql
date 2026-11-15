-- CASE expressions and conditional aggregation
SELECT order_id,order_total,CASE WHEN order_total>=10000 THEN 'High Value' WHEN order_total>=5000 THEN 'Medium Value' ELSE 'Low Value' END AS value_band FROM core.orders ORDER BY order_total DESC LIMIT 100;
SELECT ticket_id,status,resolution_days,CASE WHEN resolution_days IS NULL THEN 'Unresolved / Not Recorded' WHEN resolution_days<=2 THEN 'Resolved Quickly' WHEN resolution_days<=7 THEN 'Resolved Within a Week' ELSE 'Long Resolution' END AS resolution_band FROM core.support_tickets LIMIT 100;
SELECT count(*) AS total_orders,count(*) FILTER(WHERE status='cancelled') AS cancelled_orders,count(*) FILTER(WHERE status='shipped') AS shipped_orders,sum(CASE WHEN status='cancelled' THEN order_total ELSE 0 END) AS cancelled_value FROM core.orders;
