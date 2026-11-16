
/*
Demonstrates ACID properties using a sample
account transfer transaction.
*/

CREATE TEMP TABLE acid_demo_accounts
(
    account_id INTEGER PRIMARY KEY,
    balance NUMERIC(12,2) NOT NULL
        CHECK (balance >= 0)
);

CREATE TEMP TABLE acid_demo_ledger
(
    entry_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id INTEGER NOT NULL
        REFERENCES acid_demo_accounts(account_id),
    amount NUMERIC(12,2) NOT NULL CHECK (amount <> 0),
    entry_type TEXT NOT NULL
        CHECK (entry_type IN ('DEBIT', 'CREDIT')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO acid_demo_accounts
VALUES
(1, 1000.00),
(2, 500.00);

-- Transfer 100 from account 1 to account 2
BEGIN;

UPDATE acid_demo_accounts
SET balance = balance - 100
WHERE account_id = 1
AND balance >= 100;

UPDATE acid_demo_accounts
SET balance = balance + 100
WHERE account_id = 2;

INSERT INTO acid_demo_ledger
(account_id, amount, entry_type)
VALUES
(1, -100, 'DEBIT'),
(2, 100, 'CREDIT');

COMMIT;

-- Verify balances
SELECT *
FROM acid_demo_accounts;

-- Total balance should remain 1500
SELECT SUM(balance) AS total_balance
FROM acid_demo_accounts;

SELECT *
FROM acid_demo_ledger;
