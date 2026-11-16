
/*
MODULE 14: TRANSACTIONS
FILE: isolation_testing.sql

Concepts:
READ COMMITTED
REPEATABLE READ
SERIALIZABLE
Concurrent transactions
Serialization failures
*/

-- =========================================
-- INITIAL SETUP
-- Execute once in Session A
-- =========================================

DROP TABLE IF EXISTS public.transaction_isolation_demo;

CREATE TABLE public.transaction_isolation_demo
(
    demo_id INTEGER PRIMARY KEY,
    quantity INTEGER NOT NULL CHECK (quantity >= 0)
);

INSERT INTO public.transaction_isolation_demo
VALUES (1, 10);


/*
================================================
TEST 1: READ COMMITTED
================================================

SESSION A:
*/

BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT quantity
FROM public.transaction_isolation_demo
WHERE demo_id = 1;

-- Expected: 10

-- Keep transaction open.


/*
SESSION B:
*/

BEGIN;

UPDATE public.transaction_isolation_demo
SET quantity = 20
WHERE demo_id = 1;

COMMIT;


/*
SESSION A:
Run this SELECT again.
*/

SELECT quantity
FROM public.transaction_isolation_demo
WHERE demo_id = 1;

-- Expected: 20
-- READ COMMITTED gets a fresh snapshot
-- for each statement.

COMMIT;


/*
================================================
TEST 2: REPEATABLE READ
================================================

Reset the value in Session A before testing.
*/

UPDATE public.transaction_isolation_demo
SET quantity = 10
WHERE demo_id = 1;


/*
SESSION A:
*/

BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT quantity
FROM public.transaction_isolation_demo
WHERE demo_id = 1;

-- Expected: 10

-- Keep transaction open.


/*
SESSION B:
*/

BEGIN;

UPDATE public.transaction_isolation_demo
SET quantity = 30
WHERE demo_id = 1;

COMMIT;


/*
SESSION A:
Run the SELECT again.
*/

SELECT quantity
FROM public.transaction_isolation_demo
WHERE demo_id = 1;

-- Expected: 10
-- REPEATABLE READ keeps the same
-- transaction snapshot.

COMMIT;


/*
================================================
TEST 3: SERIALIZABLE
================================================

Reset the value before testing.
*/

UPDATE public.transaction_isolation_demo
SET quantity = 10
WHERE demo_id = 1;


/*
SESSION A:
*/

BEGIN ISOLATION LEVEL SERIALIZABLE;

SELECT quantity
FROM public.transaction_isolation_demo
WHERE demo_id = 1;

-- Expected: 10

-- Keep transaction open.


/*
SESSION B:
*/

BEGIN ISOLATION LEVEL SERIALIZABLE;

SELECT quantity
FROM public.transaction_isolation_demo
WHERE demo_id = 1;

-- Expected: 10

-- Keep transaction open.


/*
SESSION A:
*/

UPDATE public.transaction_isolation_demo
SET quantity = quantity - 1
WHERE demo_id = 1;

COMMIT;


/*
SESSION B:
*/

UPDATE public.transaction_isolation_demo
SET quantity = quantity - 1
WHERE demo_id = 1;

-- Depending on timing, PostgreSQL will report
-- a serialization failure (SQLSTATE 40001).

-- If the UPDATE fails, the transaction is aborted.
ROLLBACK;


/*
RETRY SESSION B:
Start a completely new transaction.
*/

BEGIN ISOLATION LEVEL SERIALIZABLE;

UPDATE public.transaction_isolation_demo
SET quantity = quantity - 1
WHERE demo_id = 1;

COMMIT;


/*
FINAL VERIFICATION:
*/

SELECT *
FROM public.transaction_isolation_demo;

-- Expected quantity after successful retry: 8


/*
CLEANUP:
Run only after completing all tests.
*/

DROP TABLE public.transaction_isolation_demo;
