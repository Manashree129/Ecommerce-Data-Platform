-- =============================================================================
-- 07_crud_operations/update.sql
-- Purpose: Demonstrate a targeted UPDATE and RETURNING.
-- Safety : Demo row is synthetic; transaction ends with ROLLBACK.
-- =============================================================================

BEGIN;

-- Create a known test row so this update never changes a source customer.
INSERT INTO core.customers (
    customer_id, signup_date, region, segment,
    lifetime_orders, lifetime_spend, email_domain
)
VALUES (
    'DEMO_CUST_UPDATE_001', DATE '2026-11-15', 'West', 'Standard',
    0, 0.00, 'example.test'
);

-- Update only the row identified by its primary key.
UPDATE core.customers
SET region = 'South',
    segment = 'Premium'
WHERE customer_id = 'DEMO_CUST_UPDATE_001'
RETURNING customer_id, region, segment;

-- Undo both the test insert and update. Use COMMIT only after review.
ROLLBACK;
