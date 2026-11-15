-- =============================================================================
-- 07_crud_operations/bulk_operations.sql
-- Purpose: Demonstrate set-based bulk INSERT and bulk UPDATE operations.
-- Safety : Uses synthetic demonstration customers and ends with ROLLBACK.
-- =============================================================================

BEGIN;

-- 1. Bulk insert multiple rows in one statement.
INSERT INTO core.customers (
    customer_id, signup_date, region, segment,
    lifetime_orders, lifetime_spend, email_domain
)
VALUES
    ('DEMO_BULK_001', DATE '2026-11-15', 'West',  'Standard', 0, 0.00, 'example.test'),
    ('DEMO_BULK_002', DATE '2026-11-15', 'North', 'Standard', 0, 0.00, 'example.test'),
    ('DEMO_BULK_003', DATE '2026-11-15', 'South', 'Standard', 0, 0.00, 'example.test')
RETURNING customer_id, region, segment;

-- 2. Bulk update several rows in one set-based statement.
UPDATE core.customers AS c
SET segment = v.new_segment,
    region = v.new_region
FROM (
    VALUES
        ('DEMO_BULK_001'::text, 'Premium'::text, 'West'::text),
        ('DEMO_BULK_002'::text, 'Business'::text, 'North'::text),
        ('DEMO_BULK_003'::text, 'Standard'::text, 'South'::text)
) AS v(customer_id, new_segment, new_region)
WHERE c.customer_id = v.customer_id
RETURNING c.customer_id, c.region, c.segment;

-- 3. Bulk delete only the three synthetic rows created above.
-- This demonstrates a multi-row DELETE; the enclosing transaction is rolled back.
DELETE FROM core.customers
WHERE customer_id IN ('DEMO_BULK_001', 'DEMO_BULK_002', 'DEMO_BULK_003')
RETURNING customer_id;

ROLLBACK;

-- Production-scale loading note:
-- For large CSV loads, use the staging + COPY/\copy pipeline in Module 04,
-- rather than issuing millions of individual INSERT statements.
