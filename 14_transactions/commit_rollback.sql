
/*
Demonstrates COMMIT and ROLLBACK.
Uses a temporary table to protect project data.
*/

CREATE TEMP TABLE transaction_demo_orders
(
    order_id BIGINT PRIMARY KEY,
    order_status TEXT NOT NULL
);

-- COMMIT example
BEGIN;

INSERT INTO transaction_demo_orders
VALUES (900001, 'Pending');

UPDATE transaction_demo_orders
SET order_status = 'Shipped'
WHERE order_id = 900001;

COMMIT;

SELECT *
FROM transaction_demo_orders;

-- ROLLBACK example
BEGIN;

UPDATE transaction_demo_orders
SET order_status = 'Cancelled'
WHERE order_id = 900001;

SELECT *
FROM transaction_demo_orders;

ROLLBACK;

-- Status returns to Shipped
SELECT *
FROM transaction_demo_orders;
