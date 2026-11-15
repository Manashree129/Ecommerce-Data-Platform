-- =============================================================================
-- 07_crud_operations/upsert.sql
-- Purpose: Demonstrate PostgreSQL INSERT ... ON CONFLICT (UPSERT).
-- Requires: The primary key on core.customers from Module 06.
-- Safety : Demo statement runs in a transaction and ends with ROLLBACK.
-- =============================================================================

BEGIN;

-- First call inserts the demonstration customer.
INSERT INTO core.customers (
    customer_id, signup_date, region, segment,
    lifetime_orders, lifetime_spend, email_domain
)
VALUES (
    'DEMO_CUST_UPSERT_001', DATE '2026-11-15', 'West', 'Standard',
    0, 0.00, 'example.test'
)
ON CONFLICT (customer_id)
DO UPDATE SET
    region = EXCLUDED.region,
    segment = EXCLUDED.segment,
    lifetime_orders = EXCLUDED.lifetime_orders,
    lifetime_spend = EXCLUDED.lifetime_spend,
    email_domain = EXCLUDED.email_domain
RETURNING *;

-- Run the same INSERT again with a changed region/segment to observe the UPDATE
-- path. This statement targets only the same synthetic demonstration key.
INSERT INTO core.customers (
    customer_id, signup_date, region, segment,
    lifetime_orders, lifetime_spend, email_domain
)
VALUES (
    'DEMO_CUST_UPSERT_001', DATE '2026-11-15', 'North', 'Premium',
    2, 1250.00, 'example.test'
)
ON CONFLICT (customer_id)
DO UPDATE SET
    region = EXCLUDED.region,
    segment = EXCLUDED.segment,
    lifetime_orders = EXCLUDED.lifetime_orders,
    lifetime_spend = EXCLUDED.lifetime_spend,
    email_domain = EXCLUDED.email_domain
RETURNING *;

ROLLBACK;
