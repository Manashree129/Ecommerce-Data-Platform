
/*
MODULE 16: SECURITY
FILE: permissions.sql

Purpose:
Implement role-based access control (RBAC).

Permission design:

REPORTING USER:
- Read-only access to core and reporting schemas.

ANALYST USER:
- Inherits read-only access to core and reporting.

OPERATIONS USER:
- SELECT, INSERT, UPDATE and DELETE on core tables.
- Sequence permissions for identity/serial columns.

Security principle:
Least privilege.
*/

-- =========================================
-- 1. ASSIGN GROUP ROLES TO USERS
-- =========================================

-- Analyst inherits the read-only permissions.
GRANT ecommerce_readonly
TO ecommerce_analyst;

-- Assign individual users to their group roles.
GRANT ecommerce_readonly
TO ecom_reporting_user;

GRANT ecommerce_analyst
TO ecom_analyst_user;

GRANT ecommerce_operations
TO ecom_operations_user;


-- =========================================
-- 2. DATABASE CONNECTION PERMISSIONS
-- =========================================

-- Grant CONNECT on the database currently selected.
DO $$
DECLARE
    v_database_name TEXT := CURRENT_DATABASE();
BEGIN
    EXECUTE FORMAT(
        'GRANT CONNECT ON DATABASE %I TO ecommerce_readonly',
        v_database_name
    );

    EXECUTE FORMAT(
        'GRANT CONNECT ON DATABASE %I TO ecommerce_analyst',
        v_database_name
    );

    EXECUTE FORMAT(
        'GRANT CONNECT ON DATABASE %I TO ecommerce_operations',
        v_database_name
    );
END
$$;


-- =========================================
-- 3. SCHEMA ACCESS
-- =========================================

-- Reporting and analyst roles can access
-- core and reporting schemas.
GRANT USAGE ON SCHEMA core, reporting
TO ecommerce_readonly;

-- Operations can access the core schema.
GRANT USAGE ON SCHEMA core
TO ecommerce_operations;


-- =========================================
-- 4. READ-ONLY PERMISSIONS
-- =========================================

-- Existing tables in core and reporting.
GRANT SELECT
ON ALL TABLES IN SCHEMA core, reporting
TO ecommerce_readonly;


-- =========================================
-- 5. OPERATIONS PERMISSIONS
-- =========================================

-- CRUD access to existing core tables.
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA core
TO ecommerce_operations;


-- Sequence access required for identity/serial
-- values when inserting records.
GRANT USAGE, SELECT, UPDATE
ON ALL SEQUENCES IN SCHEMA core
TO ecommerce_operations;


-- =========================================
-- 6. DEFAULT PRIVILEGES
-- =========================================

/*
These defaults apply to objects created in future
by the role executing this script.

If multiple owners create project tables, configure
default privileges separately for each owner.
*/

-- Future core tables: read-only access.
ALTER DEFAULT PRIVILEGES IN SCHEMA core
GRANT SELECT ON TABLES TO ecommerce_readonly;

-- Future reporting tables: read-only access.
ALTER DEFAULT PRIVILEGES IN SCHEMA reporting
GRANT SELECT ON TABLES TO ecommerce_readonly;

-- Future core tables: CRUD access.
ALTER DEFAULT PRIVILEGES IN SCHEMA core
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLES TO ecommerce_operations;

-- Future core sequences.
ALTER DEFAULT PRIVILEGES IN SCHEMA core
GRANT USAGE, SELECT, UPDATE
ON SEQUENCES TO ecommerce_operations;


-- =========================================
-- 7. VERIFY ROLE MEMBERSHIPS
-- =========================================

SELECT
    member_role.rolname AS user_or_role,
    granted_role.rolname AS assigned_role
FROM pg_auth_members AS membership
JOIN pg_roles AS granted_role
    ON membership.roleid = granted_role.oid
JOIN pg_roles AS member_role
    ON membership.member = member_role.oid
WHERE member_role.rolname IN
(
    'ecom_reporting_user',
    'ecom_analyst_user',
    'ecom_operations_user',
    'ecommerce_analyst'
)
ORDER BY member_role.rolname, granted_role.rolname;


-- =========================================
-- 8. VERIFY TABLE PRIVILEGES
-- =========================================

SELECT
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN
(
    'ecommerce_readonly',
    'ecommerce_analyst',
    'ecommerce_operations'
)
AND table_schema IN ('core', 'reporting')
ORDER BY
    grantee,
    table_schema,
    table_name,
    privilege_type;


-- =========================================
-- 9. VERIFY SEQUENCE PRIVILEGES
-- =========================================

SELECT
    grantee,
    object_schema,
    object_name,
    privilege_type
FROM information_schema.usage_privileges
WHERE grantee = 'ecommerce_operations'
AND object_schema = 'core'
ORDER BY object_name;
