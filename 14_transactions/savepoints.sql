
/*
MODULE 14: TRANSACTIONS
FILE: savepoints.sql

Concepts:
SAVEPOINT
ROLLBACK TO SAVEPOINT
RELEASE SAVEPOINT
*/

CREATE TEMP TABLE transaction_demo_order_items
(
    order_item_id BIGINT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price > 0)
);


BEGIN;

-- First operation
INSERT INTO transaction_demo_order_items
VALUES (910001, 501, 2, 500.00);


-- Create a savepoint
SAVEPOINT item_insert_checkpoint;


-- Second operation
INSERT INTO transaction_demo_order_items
VALUES (910002, 502, 3, 750.00);


-- Third operation
INSERT INTO transaction_demo_order_items
VALUES (910003, 503, 1, 1200.00);


-- Inspect all inserted records
SELECT *
FROM transaction_demo_order_items;


-- Roll back operations after the savepoint
ROLLBACK TO SAVEPOINT item_insert_checkpoint;


-- Only the first record remains
SELECT *
FROM transaction_demo_order_items;


-- Release the savepoint
RELEASE SAVEPOINT item_insert_checkpoint;


-- Commit the remaining operation
COMMIT;


-- Final verification
SELECT *
FROM transaction_demo_order_items;
