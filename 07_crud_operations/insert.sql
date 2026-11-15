-- =============================================================================
-- 07_crud_operations/insert.sql
-- Purpose: Demonstrate single-row INSERT statements against core tables.
-- Safety : The demo runs inside a transaction and ends with ROLLBACK.
--          Replace demo values with approved values before using in production.
-- =============================================================================

BEGIN;

-- Insert a demonstration customer. All required columns are supplied explicitly.
INSERT INTO core.customers (
    customer_id, signup_date, region, segment,
    lifetime_orders, lifetime_spend, email_domain
)
VALUES (
    'DEMO_CUST_INSERT_001', DATE '2026-11-15', 'West', 'Standard',
    0, 0.00, 'example.test'
)
RETURNING *;

-- Example of inserting a product is intentionally not included here because
-- core.products requires a valid subcategory_id already present in core.subcategories.
-- Use a verified subcategory_id and a unique product_id when inserting products.

-- Undo the demonstration row. Change to COMMIT only after reviewing the values.
ROLLBACK;
