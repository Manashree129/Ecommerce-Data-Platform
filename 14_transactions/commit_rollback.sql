
/*
MODULE 14: TRANSACTIONS
FILE: commit_rollback.sql

Concepts:
BEGIN, COMMIT, ROLLBACK
*/

-- Temporary table keeps the demonstration isolated
-- from the actual ecommerce project data.

CREATE TEMP TABLE transaction_demo_orders
(
    order_id BIGINT PRIMARY KEY,
    order_status VARCHAR(30) NOT NULL,
    order_amount NUMERIC(12,2) NOT NULL
);

-- Insert sample records
INSERT INTO transaction_demo_orders
VALUES
(900001, 'Pending', 2500.00),
(900002, 'Pending', 3500.00);


-- =========================================
-- EXAMPLE 1: COMMIT
-- =========================================

BEGIN;

UPDATE transaction_demo_orders
SET order_status = 'Shipped'
WHERE order_id = 900001;

-- Verify before committing
SELECT *
FROM transaction_demo_orders
WHERE order_id = 900001;

COMMIT;

-- Change is retained in the temporary table
SELECT *
FROM transaction_demo_orders;


-- =========================================
-- EXAMPLE 2: ROLLBACK
-- =========================================

BEGIN;

UPDATE transaction_demo_orders
SET order_status = 'Cancelled'
WHERE order_id = 900002;

-- Check the uncommitted change
SELECT *
FROM transaction_demo_orders
WHERE order_id = 900002;

ROLLBACK;

-- Original status is restored
SELECT *
FROM transaction_demo_orders
WHERE order_id = 900002;


-- =========================================
-- EXAMPLE 3: MULTIPLE OPERATIONS
-- =========================================

BEGIN;

UPDATE transaction_demo_orders
SET order_amount = 3000.00
WHERE order_id = 900001;

UPDATE transaction_demo_orders
SET order_status = 'Delivered'
WHERE order_id = 900001;

-- Both operations are committed together
COMMIT;

SELECT *
FROM transaction_demo_orders;
