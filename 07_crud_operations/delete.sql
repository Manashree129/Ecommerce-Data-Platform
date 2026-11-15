-- =============================================================================
-- 07_crud_operations/delete.sql
-- Purpose: Demonstrate a targeted DELETE and RETURNING.
-- Safety : Demo row is synthetic; transaction ends with ROLLBACK.
-- Warning: The core schema does not define soft-delete columns.
-- =============================================================================

BEGIN;

-- Create a known test row so no imported source customer can be deleted.
INSERT INTO core.customers (
    customer_id, signup_date, region, segment,
    lifetime_orders, lifetime_spend, email_domain
)
VALUES (
    'DEMO_CUST_DELETE_001', DATE '2026-11-15', 'West', 'Standard',
    0, 0.00, 'example.test'
);

-- Delete by primary key and inspect the deleted row.
DELETE FROM core.customers
WHERE customer_id = 'DEMO_CUST_DELETE_001'
RETURNING customer_id, region, segment;

-- Undo the demonstration transaction. Use COMMIT only after review.
ROLLBACK;
