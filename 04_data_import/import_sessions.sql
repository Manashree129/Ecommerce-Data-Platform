-- =============================================================================
-- File     : sql/04_data_import/import_sessions.sql
-- Project  : FreeEcommerceTwin14M (PostgreSQL)
-- Purpose  : Load sessions into staging.sessions and typed core.sessions
-- Source   : sessions(1).csv (uploaded dataset filename)
-- Expected : 7,455,296 data rows (header excluded)
-- Depends  : 03_table_creation/staging_tables.sql, core_tables.sql
-- Run as   : Start psql from the directory containing the seven CSV files,
--            then execute this script with psql -d free_ecommerce_twin_14m -f
--            <path>/import_sessions.sql.
-- Requires : psql client; this script uses the psql \copy meta-command.
-- Rerun    : Reloads the staging table. Core load is skipped only when the
--            target core table already has the complete expected row count;
--            partial core loads raise an exception instead of being ignored.
-- Status   : Generated from the supplied CSVs; not yet executed in PostgreSQL.
-- Cleaning: strip the verified injected suffix from 24 session_id values.
-- The raw values remain unchanged in staging.sessions.
-- =============================================================================

\set ON_ERROR_STOP on
\timing on

BEGIN;

-- 1. Reload raw source rows. The staging table preserves the source values.
TRUNCATE TABLE staging.sessions;
\copy staging.sessions (session_id, customer_id, session_start, device, channel, pages_viewed, converted) FROM 'sessions(1).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- 2. Validate the raw load before transforming it.
DO $$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows FROM staging.sessions;
    IF v_rows <> 7455296 THEN
        RAISE EXCEPTION 'staging.sessions: expected 7455296 rows, found %', v_rows;
    END IF;
    IF EXISTS (
        SELECT 1 FROM staging.sessions
        WHERE session_id IS NULL OR btrim(session_id) = ''
    ) THEN
        RAISE EXCEPTION 'staging.sessions: blank or NULL key value found in session_id';
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'staging', 'sessions', count(*), 7455296, 'sessions(1).csv; raw staging reload'
FROM staging.sessions;

-- 3. Validate normalized identifiers and parent-table dependencies.
DO $$
BEGIN
    IF (SELECT count(*) FROM staging.sessions WHERE right(session_id, length('_zdl26nr51f60aaa959f')) = '_zdl26nr51f60aaa959f') <> 24 THEN
        RAISE EXCEPTION 'sessions.csv: expected 24 session_id values with the injected suffix';
    END IF;
    IF EXISTS (
        SELECT regexp_replace(session_id, '_zdl26nr51f60aaa959f$', '')
        FROM staging.sessions
        GROUP BY regexp_replace(session_id, '_zdl26nr51f60aaa959f$', '')
        HAVING count(*) > 1
    ) THEN RAISE EXCEPTION 'sessions.csv: duplicate session_id after suffix normalization'; END IF;
    IF EXISTS (SELECT 1 FROM staging.sessions s LEFT JOIN core.customers c ON c.customer_id=s.customer_id WHERE c.customer_id IS NULL) THEN
        RAISE EXCEPTION 'sessions.csv: customer_id does not resolve to core.customers; import customers first';
    END IF;
END $$;

-- Refuse partial or duplicate core loads. An empty table is loaded;
-- a complete table is retained; any partial state requires investigation.
DO $$
DECLARE
    v_core_rows bigint;
BEGIN
    SELECT count(*) INTO v_core_rows FROM core.sessions;
    IF v_core_rows NOT IN (0, 7455296) THEN
        RAISE EXCEPTION 'core.sessions: expected either 0 or 7455296 rows before import, found %', v_core_rows;
    END IF;
    IF EXISTS (SELECT session_id FROM staging.sessions GROUP BY session_id HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'staging.sessions: duplicate key values found';
    END IF;
END $$;

-- 4. Transform and insert into the typed core table.
INSERT INTO core.sessions (session_id, customer_id, session_start, device, channel, pages_viewed, converted)
SELECT regexp_replace(session_id, '_zdl26nr51f60aaa959f$', ''),
       customer_id, session_start::date, device, channel,
       pages_viewed::smallint, converted::boolean
FROM staging.sessions
WHERE NOT EXISTS (SELECT 1 FROM core.sessions);

DO $$
DECLARE
    v_rows bigint;
    v_distinct bigint;
BEGIN
    SELECT count(*), count(DISTINCT session_id)
      INTO v_rows, v_distinct
      FROM core.sessions;
    IF v_rows <> 7455296 OR v_distinct <> 7455296 THEN
        RAISE EXCEPTION 'core.sessions: expected 7455296 rows and unique session_id; found rows %, distinct keys %', v_rows, v_distinct;
    END IF;
END $$;

INSERT INTO audit.load_log (stage, table_name, rows_loaded, rows_expected, note)
SELECT 'core', 'sessions', count(*), 7455296, 'core row count after import or verified rerun'
FROM core.sessions;

COMMIT;

SELECT 'sessions' AS table_name,
       (SELECT count(*) FROM staging.sessions) AS staging_rows,
       (SELECT count(*) FROM core.sessions) AS core_rows,
       7455296::bigint AS expected_rows;
