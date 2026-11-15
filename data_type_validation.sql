-- Compare actual PostgreSQL internal types with the intended core-table design.
WITH expected(table_name,column_name,expected_udt) AS (VALUES
 ('customers','customer_id','text'),('customers','signup_date','date'),('customers','region','text'),('customers','segment','text'),('customers','lifetime_orders','int4'),('customers','lifetime_spend','numeric'),('customers','email_domain','text'),
 ('categories','category_id','int4'),('categories','category_name','text'),
 ('subcategories','subcategory_id','int4'),('subcategories','category_id','int4'),('subcategories','subcategory_name','text'),
 ('products','product_id','text'),('products','subcategory_id','int4'),('products','price','numeric'),('products','cost','numeric'),('products','brand','text'),('products','launch_date','date'),('products','avg_rating','numeric'),
 ('sessions','session_id','text'),('sessions','customer_id','text'),('sessions','session_start','date'),('sessions','device','text'),('sessions','channel','text'),('sessions','pages_viewed','int2'),('sessions','converted','bool'),
 ('orders','order_id','text'),('orders','customer_id','text'),('orders','session_id','text'),('orders','order_date','date'),('orders','status','text'),('orders','item_count','int2'),('orders','order_total','numeric'),('orders','payment_method','text'),
 ('order_items','order_item_id','text'),('order_items','order_id','text'),('order_items','product_id','text'),('order_items','quantity','int2'),('order_items','unit_price','numeric'),('order_items','line_total','numeric'),
 ('returns','return_id','text'),('returns','order_id','text'),('returns','order_item_id','text'),('returns','product_id','text'),('returns','return_date','date'),('returns','reason','text'),('returns','refund_amount','numeric'),
 ('support_tickets','ticket_id','text'),('support_tickets','customer_id','text'),('support_tickets','order_id','text'),('support_tickets','created_date','date'),('support_tickets','category','text'),('support_tickets','priority','text'),('support_tickets','status','text'),('support_tickets','resolution_days','int2')
), actual AS (
 SELECT table_name,column_name,udt_name FROM information_schema.columns WHERE table_schema='core'
)
SELECT e.table_name,e.column_name,e.expected_udt,a.udt_name actual_udt,
 CASE WHEN a.udt_name=e.expected_udt THEN 'PASS' WHEN a.udt_name IS NULL THEN 'MISSING COLUMN' ELSE 'FAIL - TYPE MISMATCH' END AS status
FROM expected e LEFT JOIN actual a USING(table_name,column_name)
ORDER BY e.table_name,e.column_name;

-- Any rows returned here are extra columns not listed in the expected design.
WITH expected AS (SELECT * FROM (VALUES
 ('customers','customer_id'),('customers','signup_date'),('customers','region'),('customers','segment'),('customers','lifetime_orders'),('customers','lifetime_spend'),('customers','email_domain'),
 ('categories','category_id'),('categories','category_name'),('subcategories','subcategory_id'),('subcategories','category_id'),('subcategories','subcategory_name'),
 ('products','product_id'),('products','subcategory_id'),('products','price'),('products','cost'),('products','brand'),('products','launch_date'),('products','avg_rating'),
 ('sessions','session_id'),('sessions','customer_id'),('sessions','session_start'),('sessions','device'),('sessions','channel'),('sessions','pages_viewed'),('sessions','converted'),
 ('orders','order_id'),('orders','customer_id'),('orders','session_id'),('orders','order_date'),('orders','status'),('orders','item_count'),('orders','order_total'),('orders','payment_method'),
 ('order_items','order_item_id'),('order_items','order_id'),('order_items','product_id'),('order_items','quantity'),('order_items','unit_price'),('order_items','line_total'),
 ('returns','return_id'),('returns','order_id'),('returns','order_item_id'),('returns','product_id'),('returns','return_date'),('returns','reason'),('returns','refund_amount'),
 ('support_tickets','ticket_id'),('support_tickets','customer_id'),('support_tickets','order_id'),('support_tickets','created_date'),('support_tickets','category'),('support_tickets','priority'),('support_tickets','status'),('support_tickets','resolution_days')
 ) v(table_name,column_name))
SELECT c.table_name,c.column_name AS unexpected_column
FROM information_schema.columns c LEFT JOIN expected e USING(table_name,column_name)
WHERE c.table_schema='core' AND e.column_name IS NULL ORDER BY c.table_name,c.ordinal_position;
