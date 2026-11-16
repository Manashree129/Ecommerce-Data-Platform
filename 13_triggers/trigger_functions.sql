
/*
Project: Ecommerce-Database-Engineering
Module: 13 - Triggers
File: trigger_functions.sql

Purpose:
Create a reusable row-level audit function and audit log table.

Prerequisites:
- Module 02: schemas must exist.
- Module 03: core tables must exist.
- The audit schema must already exist.
*/

CREATE TABLE IF NOT EXISTS audit.row_change_log
(
    audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,

    operation TEXT NOT NULL
        CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),

    record_key TEXT,
    old_record JSONB,
    new_record JSONB,

    changed_at TIMESTAMPTZ
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    changed_by TEXT
        NOT NULL DEFAULT CURRENT_USER
);

COMMENT ON TABLE audit.row_change_log IS
'Row-level audit history for selected ecommerce operational tables.';

CREATE INDEX IF NOT EXISTS idx_row_change_log_table_time
ON audit.row_change_log
(schema_name, table_name, changed_at DESC);

CREATE INDEX IF NOT EXISTS idx_row_change_log_record
ON audit.row_change_log
(table_name, record_key);


CREATE OR REPLACE FUNCTION audit.log_row_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$

DECLARE
    v_record_key TEXT;
    v_old_record JSONB;
    v_new_record JSONB;

BEGIN

    IF TG_NARGS < 1 OR NULLIF(TG_ARGV[0], '') IS NULL THEN
        RAISE EXCEPTION
            'Primary-key column name must be passed as the first trigger argument';
    END IF;

    IF TG_OP = 'INSERT' THEN

        v_new_record := TO_JSONB(NEW);
        v_record_key := v_new_record ->> TG_ARGV[0];

    ELSIF TG_OP = 'UPDATE' THEN

        v_old_record := TO_JSONB(OLD);
        v_new_record := TO_JSONB(NEW);
        v_record_key := v_new_record ->> TG_ARGV[0];

    ELSIF TG_OP = 'DELETE' THEN

        v_old_record := TO_JSONB(OLD);
        v_record_key := v_old_record ->> TG_ARGV[0];

    ELSE

        RAISE EXCEPTION
            'Unsupported trigger operation: %', TG_OP;

    END IF;

    INSERT INTO audit.row_change_log
    (
        schema_name,
        table_name,
        operation,
        record_key,
        old_record,
        new_record
    )
    VALUES
    (
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        TG_OP,
        v_record_key,
        v_old_record,
        v_new_record
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;

END;
$$;

COMMENT ON FUNCTION audit.log_row_change() IS
'Generic row-level audit trigger function.';
