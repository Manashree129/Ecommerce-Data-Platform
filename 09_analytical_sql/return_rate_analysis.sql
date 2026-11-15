-- Return metrics. A return row references an item line; use distinct returned item IDs
-- when comparing with distinct sold item IDs, and clearly label the chosen denominator.

-- Return records and refunds by reason
SELECT reason, COUNT(*) AS return_records,
       SUM(refund_amount) AS refund_amount
FROM core.returns
GROUP BY reason ORDER BY return_records DESC;

-- Return-record count by product category
SELECT cat.category_name, COUNT(*) AS return_records,
       SUM(r.refund_amount) AS refund_amount
FROM core.returns r
JOIN core.products p ON p.product_id = r.product_id
JOIN core.subcategories sc ON sc.subcategory_id = p.subcategory_id
JOIN core.categories cat ON cat.category_id = sc.category_id
GROUP BY cat.category_name ORDER BY return_records DESC;

-- Item-line return rate by category (distinct returned order-item IDs / distinct sold order-item IDs)
WITH sold AS (
    SELECT p.product_id, sc.category_id,
           COUNT(DISTINCT oi.order_item_id) AS sold_item_lines
    FROM core.order_items oi
    JOIN core.products p ON p.product_id = oi.product_id
    JOIN core.subcategories sc ON sc.subcategory_id = p.subcategory_id
    GROUP BY p.product_id, sc.category_id
), returned AS (
    SELECT DISTINCT r.order_item_id, r.product_id
    FROM core.returns r
), returned_by_category AS (
    SELECT sc.category_id, COUNT(DISTINCT r.order_item_id) AS returned_item_lines
    FROM returned r
    JOIN core.products p ON p.product_id = r.product_id
    JOIN core.subcategories sc ON sc.subcategory_id = p.subcategory_id
    GROUP BY sc.category_id
), sold_by_category AS (
    SELECT category_id, SUM(sold_item_lines) AS sold_item_lines
    FROM sold GROUP BY category_id
)
SELECT cat.category_name, s.sold_item_lines,
       COALESCE(r.returned_item_lines, 0) AS returned_item_lines,
       ROUND(100.0 * COALESCE(r.returned_item_lines, 0) / NULLIF(s.sold_item_lines, 0), 2) AS item_line_return_rate_pct
FROM sold_by_category s
JOIN core.categories cat ON cat.category_id = s.category_id
LEFT JOIN returned_by_category r ON r.category_id = s.category_id
ORDER BY item_line_return_rate_pct DESC;
