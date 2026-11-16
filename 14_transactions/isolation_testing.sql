
/*
Demonstrates READ COMMITTED and REPEATABLE READ.

First execute this setup once.
*/

DROP TABLE IF EXISTS public.transaction_isolation_demo;

CREATE TABLE public.transaction_isolation_demo
(
    demo_id INTEGER PRIMARY KEY,
    quantity INTEGER NOT NULL CHECK (quantity >= 0)
);

INSERT INTO public.transaction_isolation_demo
VALUES (1, 10);


/*
TEST 1: READ COMMITTED

SESSION A:
*/

BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT quantity
FROM public.transaction_isolation_demo
WHERE demo_id = 1;

-- Keep Session A open.

/*
SESSION B:
*/

BEGIN;

UPDATE public.transaction_isolation_demo
SET quantity = 20
WHERE demo_id = 1;

COMMIT;

/*
BACK TO SESSION A:
*/

SELECT quantity
FROM public.transaction_isolation_demo
WHERE demo_id = 1;

-- Expected: 20
COMMIT;


/*
TEST 2: REPEATABLE READ

Reset the value first.
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

-- Keep Session A open.

/*
SESSION B:
*/

BEGIN;

UPDATE public.transaction_isolation_demo
SET quantity = 30
WHERE demo_id = 1;

COMMIT;

/*
BACK TO SESSION A:
*/

SELECT quantity
FROM public.transaction_isolation_demo
WHERE demo_id = 1;

-- Expected: 10
COMMIT;


/*
Cleanup after completing both tests.
*/

DROP TABLE public.transaction_isolation_demo;
