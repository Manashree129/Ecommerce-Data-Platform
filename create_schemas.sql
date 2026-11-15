-- =============================================================================
-- File     : sql/02_schema_creation/create_schemas.sql
-- Purpose  : Create the four project schemas.
-- Depends  : 01_database_setup/create_database.sql
-- Run as   : psql -d free_ecommerce_twin_14m -f create_schemas.sql
-- Rerun    : Safe (CREATE SCHEMA IF NOT EXISTS; nothing is dropped).
-- Status   : Not executed against PostgreSQL by the author of this script.
--
-- Schema responsibilities
--   staging   : raw, all-text copies of the seven CSV files, exactly as loaded.
--   core      : typed, cleaned, constrained tables (system of record).
--   reporting : views and materialized views for analysis.
--   audit     : load logs and row-change logs written by scripts/triggers.
-- =============================================================================

\set ON_ERROR_STOP on

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS reporting;
CREATE SCHEMA IF NOT EXISTS audit;

COMMENT ON SCHEMA staging   IS 'Raw landing zone: one all-text table per CSV file. No constraints, no cleaning. Reloadable from the CSVs.';
COMMENT ON SCHEMA core      IS 'Typed and constrained tables loaded from staging. System of record for all analysis.';
COMMENT ON SCHEMA reporting IS 'Views and materialized views built on core for analytics.';
COMMENT ON SCHEMA audit     IS 'Load logs and change-tracking tables.';

-- Verify
SELECT n.nspname AS schema_name,
       pg_get_userbyid(n.nspowner) AS owner,
       obj_description(n.oid, 'pg_namespace') AS description
FROM pg_namespace AS n
WHERE n.nspname IN ('staging', 'core', 'reporting', 'audit')
ORDER BY n.nspname;
