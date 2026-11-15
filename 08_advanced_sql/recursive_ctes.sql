-- Recursive CTE: walk category -> subcategory hierarchy (two levels in this dataset)
WITH RECURSIVE category_tree AS (SELECT category_id,category_name::text AS node_name,NULL::integer AS parent_id,1 AS depth,category_name::text AS path FROM core.categories UNION ALL SELECT ct.category_id,sc.subcategory_name,ct.category_id,2,(ct.path||' / '||sc.subcategory_name)::text FROM category_tree ct JOIN core.subcategories sc ON sc.category_id=ct.category_id WHERE ct.depth=1) SELECT category_id,node_name,parent_id,depth,path FROM category_tree ORDER BY category_id,depth,node_name;
-- Basic recursive sequence
WITH RECURSIVE nums(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM nums WHERE n<10) SELECT n FROM nums ORDER BY n;
