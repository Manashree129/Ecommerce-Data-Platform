-- NULL predicates, COALESCE and NULLIF
SELECT ticket_id,status,resolution_days FROM core.support_tickets WHERE resolution_days IS NULL LIMIT 100;
SELECT ticket_id,status,coalesce(resolution_days::text,'Unresolved') AS resolution_display FROM core.support_tickets LIMIT 100;
SELECT product_id,price,cost,round(((price-cost)/nullif(price,0))*100,2) AS margin_pct FROM core.products ORDER BY margin_pct DESC NULLS LAST LIMIT 100;
SELECT count(*) AS total_tickets,count(resolution_days) AS with_resolution_days,count(*) FILTER(WHERE resolution_days IS NULL) AS without_resolution_days FROM core.support_tickets;
