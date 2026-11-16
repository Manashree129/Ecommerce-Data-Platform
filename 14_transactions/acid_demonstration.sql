
/*
MODULE 14: TRANSACTIONS
FILE: acid_demonstration.sql

Concepts:
ACID properties
Atomicity
Consistency
Isolation
Durability
*/

CREATE TEMP TABLE acid_demo_accounts
(
    account_id INTEGER PRIMARY KEY,
    account_holder VARCHAR(50) NOT NULL,
    balance NUMERIC(12,2) NOT NULL
        CHECK (balance >= 0)
);

CREATE TEMP TABLE acid_demo_ledger
(
    entry_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id INTEGER NOT NULL
        REFERENCES acid_demo_accounts(account_id),
    amount NUMERIC(12,2) NOT NULL,
    transaction_type VARCHAR(10) NOT NULL
        CHECK (transaction_type IN ('DEBIT', 'CREDIT')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- Initial account balances
INSERT INTO acid_demo_accounts
VALUES
(1, 'Customer A', 1000.00),
(2, 'Customer B', 500.00);


-- =========================================
-- BANK TRANSFER: 100 FROM A TO B
-- =========================================

BEGIN;

-- Lock both accounts while the transfer is processed
SELECT account_id, balance
FROM acid_demo_accounts
WHERE account_id IN (1, 2)
ORDER BY account_id
FOR UPDATE;


-- Debit Customer A only if sufficient funds exist
UPDATE acid_demo_accounts
SET balance = balance - 100.00
WHERE account_id = 1
AND balance >= 100.00;


-- Credit Customer B only if the debit succeeded
-- The preceding update is expected to affect one row.
UPDATE acid_demo_accounts
SET balance = balance + 100.00
WHERE account_id = 2
AND EXISTS
(
    SELECT 1
    FROM acid_demo_accounts
    WHERE account_id = 1
    AND balance = 900.00
);


-- Record both sides of the transfer
INSERT INTO acid_demo_ledger
(account_id, amount, transaction_type)
VALUES
(1, -100.00, 'DEBIT'),
(2, 100.00, 'CREDIT');


COMMIT;


-- =========================================
-- VERIFY TRANSACTION
-- =========================================

SELECT *
FROM acid_demo_accounts
ORDER BY account_id;


-- Total balance should remain 1500
SELECT SUM(balance) AS total_account_balance
FROM acid_demo_accounts;


SELECT *
FROM acid_demo_ledger
ORDER BY entry_id;


/*
ACID EXPLANATION:

ATOMICITY:
The transaction is committed as one unit.

CONSISTENCY:
The CHECK constraint prevents negative balances.

ISOLATION:
FOR UPDATE locks the selected account rows
against conflicting modifications.

DURABILITY:
Committed changes persist beyond the transaction.
*/
