
/*
MODULE 16: SECURITY
FILE: create_users.sql

Purpose:
Create individual PostgreSQL login accounts.

Important:
Set strong passwords separately using a secure
credential-management process.

Never commit passwords to GitHub.
*/

-- 1. REPORTING USER
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'ecom_reporting_user'
    ) THEN
        CREATE ROLE ecom_reporting_user LOGIN;
    END IF;
END
$$;


-- 2. ANALYST USER
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'ecom_analyst_user'
    ) THEN
        CREATE ROLE ecom_analyst_user LOGIN;
    END IF;
END
$$;


-- 3. OPERATIONS USER
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'ecom_operations_user'
    ) THEN
        CREATE ROLE ecom_operations_user LOGIN;
    END IF;
END
$$;


-- Explicitly restrict elevated account privileges.
ALTER ROLE ecom_reporting_user
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;

ALTER ROLE ecom_analyst_user
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;

ALTER ROLE ecom_operations_user
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;


-- Verify login accounts
SELECT
    rolname,
    rolcanlogin,
    rolsuper,
    rolcreatedb,
    rolcreaterole
FROM pg_roles
WHERE rolname IN
(
    'ecom_reporting_user',
    'ecom_analyst_user',
    'ecom_operations_user'
)
ORDER BY rolname;


/*
PASSWORD CONFIGURATION

After creating the users, set passwords securely.

In psql, use:

\password ecom_reporting_user
\password ecom_analyst_user
\password ecom_operations_user

In pgAdmin, use the Login/Group Roles
properties to configure passwords.

Do not store actual passwords in this file.
*/
