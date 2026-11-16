
/*
MODULE 15: PERFORMANCE OPTIMIZATION
FILE: partial_indexes.sql

Purpose:
Create indexes for selected subsets of data.

Dataset-specific business rule:
Unresolved tickets have resolution_days = NULL
in the core schema.
*/

-- Index only unresolved support tickets.
CREATE INDEX IF NOT EXISTS idx_unresolved_tickets_customer
ON core.support_tickets (customer_id)
WHERE resolution_days IS NULL;


-- Example query that can benefit from this index.
SELECT
    ticket_id,
    customer_id,
    resolution_days
FROM core.support_tickets
WHERE resolution_days IS NULL;


-- Verify partial index definition
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'core'
AND indexname = 'idx_unresolved_tickets_customer';


ANALYZE core.support_tickets;
