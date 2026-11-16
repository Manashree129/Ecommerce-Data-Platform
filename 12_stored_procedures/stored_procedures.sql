-- 12_stored_procedures/stored_procedures.sql
-- Stored procedures for controlled maintenance of reporting objects.
-- These procedures do not modify source/core business records.

CREATE OR REPLACE PROCEDURE reporting.sp_refresh_monthly_sales()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW reporting.mv_monthly_sales;
END;
$$;

CREATE OR REPLACE PROCEDURE reporting.sp_refresh_category_performance()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW reporting.mv_category_performance;
END;
$$;

CREATE OR REPLACE PROCEDURE reporting.sp_refresh_all_analytics()
LANGUAGE plpgsql
AS $$
BEGIN
    CALL reporting.sp_refresh_monthly_sales();
    CALL reporting.sp_refresh_category_performance();
END;
$$;

-- Execute after creating the materialized views:
-- CALL reporting.sp_refresh_all_analytics();
