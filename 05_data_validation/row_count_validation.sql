-- Compare loaded core counts with verified source CSV row counts. Run after module 04.
WITH expected(table_name, expected_rows) AS (
 VALUES ('customers',1000000::bigint),('products',50000::bigint),
 ('sessions',7455296::bigint),('orders',1075683::bigint),
 ('order_items',4280732::bigint),('returns',400293::bigint),
 ('support_tickets',66938::bigint)
), actual AS (
 SELECT 'customers' table_name,count(*)::bigint actual_rows FROM core.customers
 UNION ALL SELECT 'products',count(*) FROM core.products
 UNION ALL SELECT 'sessions',count(*) FROM core.sessions
 UNION ALL SELECT 'orders',count(*) FROM core.orders
 UNION ALL SELECT 'order_items',count(*) FROM core.order_items
 UNION ALL SELECT 'returns',count(*) FROM core.returns
 UNION ALL SELECT 'support_tickets',count(*) FROM core.support_tickets
)
SELECT e.table_name,e.expected_rows,a.actual_rows,
       a.actual_rows-e.expected_rows AS difference,
       CASE WHEN a.actual_rows=e.expected_rows THEN 'PASS' ELSE 'FAIL' END AS status
FROM expected e JOIN actual a USING(table_name) ORDER BY e.table_name;

-- Dataset profiling found exactly 6 categories and 27 subcategories.
SELECT (SELECT count(*) FROM core.categories) AS actual_categories,
       6 AS expected_categories,
       (SELECT count(*) FROM core.subcategories) AS actual_subcategories,
       27 AS expected_subcategories;
