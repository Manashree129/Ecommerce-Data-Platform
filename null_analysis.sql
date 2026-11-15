-- Count NULLs in every core column. All columns are expected non-NULL except
-- core.support_tickets.resolution_days: source -1 is converted to NULL for
-- unresolved tickets during import.
WITH null_counts AS (
 SELECT 'customers' table_name,'customer_id' column_name,count(*) FILTER(WHERE customer_id IS NULL) null_rows FROM core.customers
 UNION ALL SELECT 'customers','signup_date',count(*) FILTER(WHERE signup_date IS NULL) FROM core.customers
 UNION ALL SELECT 'customers','region',count(*) FILTER(WHERE region IS NULL) FROM core.customers
 UNION ALL SELECT 'customers','segment',count(*) FILTER(WHERE segment IS NULL) FROM core.customers
 UNION ALL SELECT 'customers','lifetime_orders',count(*) FILTER(WHERE lifetime_orders IS NULL) FROM core.customers
 UNION ALL SELECT 'customers','lifetime_spend',count(*) FILTER(WHERE lifetime_spend IS NULL) FROM core.customers
 UNION ALL SELECT 'customers','email_domain',count(*) FILTER(WHERE email_domain IS NULL) FROM core.customers
 UNION ALL SELECT 'products','product_id',count(*) FILTER(WHERE product_id IS NULL) FROM core.products
 UNION ALL SELECT 'products','subcategory_id',count(*) FILTER(WHERE subcategory_id IS NULL) FROM core.products
 UNION ALL SELECT 'products','price',count(*) FILTER(WHERE price IS NULL) FROM core.products
 UNION ALL SELECT 'products','cost',count(*) FILTER(WHERE cost IS NULL) FROM core.products
 UNION ALL SELECT 'products','brand',count(*) FILTER(WHERE brand IS NULL) FROM core.products
 UNION ALL SELECT 'products','launch_date',count(*) FILTER(WHERE launch_date IS NULL) FROM core.products
 UNION ALL SELECT 'products','avg_rating',count(*) FILTER(WHERE avg_rating IS NULL) FROM core.products
 UNION ALL SELECT 'sessions','session_id',count(*) FILTER(WHERE session_id IS NULL) FROM core.sessions
 UNION ALL SELECT 'sessions','customer_id',count(*) FILTER(WHERE customer_id IS NULL) FROM core.sessions
 UNION ALL SELECT 'sessions','session_start',count(*) FILTER(WHERE session_start IS NULL) FROM core.sessions
 UNION ALL SELECT 'sessions','device',count(*) FILTER(WHERE device IS NULL) FROM core.sessions
 UNION ALL SELECT 'sessions','channel',count(*) FILTER(WHERE channel IS NULL) FROM core.sessions
 UNION ALL SELECT 'sessions','pages_viewed',count(*) FILTER(WHERE pages_viewed IS NULL) FROM core.sessions
 UNION ALL SELECT 'sessions','converted',count(*) FILTER(WHERE converted IS NULL) FROM core.sessions
 UNION ALL SELECT 'orders','order_id',count(*) FILTER(WHERE order_id IS NULL) FROM core.orders
 UNION ALL SELECT 'orders','customer_id',count(*) FILTER(WHERE customer_id IS NULL) FROM core.orders
 UNION ALL SELECT 'orders','session_id',count(*) FILTER(WHERE session_id IS NULL) FROM core.orders
 UNION ALL SELECT 'orders','order_date',count(*) FILTER(WHERE order_date IS NULL) FROM core.orders
 UNION ALL SELECT 'orders','status',count(*) FILTER(WHERE status IS NULL) FROM core.orders
 UNION ALL SELECT 'orders','item_count',count(*) FILTER(WHERE item_count IS NULL) FROM core.orders
 UNION ALL SELECT 'orders','order_total',count(*) FILTER(WHERE order_total IS NULL) FROM core.orders
 UNION ALL SELECT 'orders','payment_method',count(*) FILTER(WHERE payment_method IS NULL) FROM core.orders
 UNION ALL SELECT 'order_items','order_item_id',count(*) FILTER(WHERE order_item_id IS NULL) FROM core.order_items
 UNION ALL SELECT 'order_items','order_id',count(*) FILTER(WHERE order_id IS NULL) FROM core.order_items
 UNION ALL SELECT 'order_items','product_id',count(*) FILTER(WHERE product_id IS NULL) FROM core.order_items
 UNION ALL SELECT 'order_items','quantity',count(*) FILTER(WHERE quantity IS NULL) FROM core.order_items
 UNION ALL SELECT 'order_items','unit_price',count(*) FILTER(WHERE unit_price IS NULL) FROM core.order_items
 UNION ALL SELECT 'order_items','line_total',count(*) FILTER(WHERE line_total IS NULL) FROM core.order_items
 UNION ALL SELECT 'returns','return_id',count(*) FILTER(WHERE return_id IS NULL) FROM core.returns
 UNION ALL SELECT 'returns','order_id',count(*) FILTER(WHERE order_id IS NULL) FROM core.returns
 UNION ALL SELECT 'returns','order_item_id',count(*) FILTER(WHERE order_item_id IS NULL) FROM core.returns
 UNION ALL SELECT 'returns','product_id',count(*) FILTER(WHERE product_id IS NULL) FROM core.returns
 UNION ALL SELECT 'returns','return_date',count(*) FILTER(WHERE return_date IS NULL) FROM core.returns
 UNION ALL SELECT 'returns','reason',count(*) FILTER(WHERE reason IS NULL) FROM core.returns
 UNION ALL SELECT 'returns','refund_amount',count(*) FILTER(WHERE refund_amount IS NULL) FROM core.returns
 UNION ALL SELECT 'support_tickets','ticket_id',count(*) FILTER(WHERE ticket_id IS NULL) FROM core.support_tickets
 UNION ALL SELECT 'support_tickets','customer_id',count(*) FILTER(WHERE customer_id IS NULL) FROM core.support_tickets
 UNION ALL SELECT 'support_tickets','order_id',count(*) FILTER(WHERE order_id IS NULL) FROM core.support_tickets
 UNION ALL SELECT 'support_tickets','created_date',count(*) FILTER(WHERE created_date IS NULL) FROM core.support_tickets
 UNION ALL SELECT 'support_tickets','category',count(*) FILTER(WHERE category IS NULL) FROM core.support_tickets
 UNION ALL SELECT 'support_tickets','priority',count(*) FILTER(WHERE priority IS NULL) FROM core.support_tickets
 UNION ALL SELECT 'support_tickets','status',count(*) FILTER(WHERE status IS NULL) FROM core.support_tickets
 UNION ALL SELECT 'support_tickets','resolution_days',count(*) FILTER(WHERE resolution_days IS NULL) FROM core.support_tickets
)
SELECT table_name,column_name,null_rows,
 CASE WHEN table_name='support_tickets' AND column_name='resolution_days' THEN 'ALLOWED - UNRESOLVED TICKETS'
      WHEN null_rows=0 THEN 'PASS' ELSE 'FAIL - UNEXPECTED NULLS' END AS validation_status
FROM null_counts ORDER BY table_name,column_name;

-- Profiled sentinel conversion check: unresolved tickets should have NULL duration.
SELECT status,count(*) AS unresolved_ticket_rows
FROM core.support_tickets WHERE resolution_days IS NULL GROUP BY status ORDER BY status;
