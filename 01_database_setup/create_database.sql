-- =============================================================================
-- File     : sql/01_database_setup/create_database.sql
-- Project  : FreeEcommerceTwin14M (PostgreSQL)
-- Purpose  : Create the project database (idempotent) and switch into it.
--
-- Run as   : psql -U <role with CREATEDB> -d postgres -f create_database.sql
-- Requires : psql client (uses \set, \gexec, \connect). These are psql
--            meta-commands and will NOT work in pgAdmin / DBeaver query tabs.
-- Rerun    : Safe. The database is only created if it does not exist.
-- Note     : CREATE DATABASE cannot run inside a transaction block or a DO
--            block, so the statement is built with format() and executed with
--            \gexec only when the database is missing.
-- Status   : Not executed against PostgreSQL by the author of this script.
-- =============================================================================

\set ON_ERROR_STOP on
\set dbname 'free_ecommerce_twin_14m'

-- 1. Create the database only if it does not already exist.
--    No ENCODING/LOCALE is forced so the statement works on any cluster; the
--    verification query below shows what the cluster actually assigned.
SELECT format('CREATE DATABASE %I', :'dbname')
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_database AS d
    WHERE d.datname = :'dbname'
)
\gexec

-- 2. Document the database and pin its session time zone to UTC so that any
--    timestamptz values written by audit logging are consistent for all users.
SELECT format('COMMENT ON DATABASE %I IS %L', :'dbname',
              'FreeEcommerceTwin14M: staging/core/reporting/audit e-commerce analytics database')
\gexec

SELECT format('ALTER DATABASE %I SET timezone TO %L', :'dbname', 'UTC')
\gexec

-- 3. Verify the result (encoding and owner as assigned by the cluster).
SELECT d.datname                          AS database_name,
       pg_encoding_to_char(d.encoding)    AS encoding,
       pg_get_userbyid(d.datdba)          AS owner
FROM pg_database AS d
WHERE d.datname = :'dbname';

-- 4. Switch the session to the new database so later scripts run inside it.
\connect :dbname
SELECT current_database() AS connected_to, version() AS server_version;
