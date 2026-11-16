
/*
MODULE 16: SECURITY
FILE: create_roles.sql

Purpose:
Create reusable PostgreSQL group roles.

Prerequisites:
- Database and schemas must already exist.
- Execute using a database administrator account.

Roles:
1. ecommerce_readonly
2. ecommerce_analyst
3. ecommerce_operations
*/

-- 1. READ-ONLY ROLE
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'ecommerce_readonly'
    ) THEN
        CREATE ROLE ecommerce_readonly NOLOGIN;
    END IF;
END
$$;


-- 2. DATA ANALYST ROLE
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'ecommerce_analyst'
    ) THEN
        CREATE ROLE ecommerce_analyst NOLOGIN;
    END IF;
END
$$;


-- 3. OPERATIONS ROLE
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'ecommerce_operations'
    ) THEN
        CREATE ROLE ecommerce_operations NOLOGIN;
    END IF;
END
$$;


-- Role attributes: explicitly restrict elevated capabilities.
ALTER ROLE ecommerce_readonly
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;

ALTER ROLE ecommerce_analyst
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;

ALTER ROLE ecommerce_operations
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;


-- Verify created roles
SELECT
    rolname,
    rolsuper,
    rolcreatedb,
    rolcreaterole,
    rolcanlogin
FROM pg_roles
WHERE rolname IN
(
    'ecommerce_readonly',
    'ecommerce_analyst',
    'ecommerce_operations'
)
ORDER BY rolname;
