-- Top-N analysis using ranking functions.

-- Top 10 products by item-line value
WITH product_sales AS (
    SELECT product_id, SUM(quantity) AS units_sold,
           SUM(line_total) AS item_line_value
    FROM core.order_items GROUP BY product_id
), ranked AS (
    SELECT *, DENSE_RANK() OVER (ORDER BY item_line_value DESC) AS sales_rank
    FROM product_sales
)
SELECT product_id, units_sold, item_line_value, sales_rank
FROM ranked WHERE sales_rank <= 10 ORDER BY sales_rank, product_id;

-- Top 5 customers by recorded order value in each region
WITH customer_region_sales AS (
    SELECT c.region, o.customer_id, SUM(o.order_total) AS order_value
    FROM core.orders o
    JOIN core.customers c ON c.customer_id = o.customer_id
    GROUP BY c.region, o.customer_id
), ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY region ORDER BY order_value DESC, customer_id) AS region_rank
    FROM customer_region_sales
)
SELECT region, customer_id, order_value, region_rank
FROM ranked WHERE region_rank <= 5 ORDER BY region, region_rank;

-- Top 3 categories by item-line value
WITH category_sales AS (
    SELECT cat.category_name, SUM(oi.line_total) AS item_line_value
    FROM core.order_items oi
    JOIN core.products p ON p.product_id = oi.product_id
    JOIN core.subcategories sc ON sc.subcategory_id = p.subcategory_id
    JOIN core.categories cat ON cat.category_id = sc.category_id
    GROUP BY cat.category_name
), ranked AS (
    SELECT *, DENSE_RANK() OVER (ORDER BY item_line_value DESC) AS category_rank
    FROM category_sales
)
SELECT category_name, item_line_value, category_rank
FROM ranked WHERE category_rank <= 3 ORDER BY category_rank;
