
/*
Demonstrates SAVEPOINT, ROLLBACK TO SAVEPOINT
and RELEASE SAVEPOINT.
*/

CREATE TEMP TABLE transaction_demo_order_items
(
    order_item_id BIGINT PRIMARY KEY,
    quantity INTEGER NOT NULL CHECK (quantity > 0)
);

BEGIN;

INSERT INTO transaction_demo_order_items
VALUES (910001, 1);

SAVEPOINT before_second_item;

INSERT INTO transaction_demo_order_items
VALUES (910002, 2);

-- Undo only the second insert
ROLLBACK TO SAVEPOINT before_second_item;

RELEASE SAVEPOINT before_second_item;

-- Only the first record remains
SELECT *
FROM transaction_demo_order_items;

COMMIT;

SELECT COUNT(*) AS committed_demo_rows
FROM transaction_demo_order_items;
