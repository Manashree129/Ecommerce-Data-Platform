-- UNION removes duplicates; UNION ALL preserves them
SELECT customer_id FROM core.orders UNION SELECT customer_id FROM core.support_tickets;
SELECT customer_id,'order' AS activity_type FROM core.orders UNION ALL SELECT customer_id,'support_ticket' FROM core.support_tickets LIMIT 200;
SELECT customer_id FROM core.orders INTERSECT SELECT customer_id FROM core.support_tickets;
SELECT customer_id FROM core.orders EXCEPT SELECT customer_id FROM core.support_tickets;
