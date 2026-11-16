-- 11_functions/user_defined_functions.sql
-- PostgreSQL user-defined functions for reusable calculations.

CREATE OR REPLACE FUNCTION reporting.fn_customer_order_count(p_customer_id text)
RETURNS bigint
LANGUAGE sql
STABLE
AS $$
    SELECT count(*)
    FROM core.orders
    WHERE customer_id = p_customer_id;
$$;

CREATE OR REPLACE FUNCTION reporting.fn_customer_historical_order_value(p_customer_id text)
RETURNS numeric
LANGUAGE sql
STABLE
AS $$
    SELECT coalesce(sum(order_total), 0)::numeric
    FROM core.orders
    WHERE customer_id = p_customer_id;
$$;

CREATE OR REPLACE FUNCTION reporting.fn_product_gross_margin_pct(p_product_id text)
RETURNS numeric
LANGUAGE sql
STABLE
AS $$
    SELECT round(((price - cost) / nullif(price, 0)) * 100, 2)
    FROM core.products
    WHERE product_id = p_product_id;
$$;

-- Examples:
-- SELECT reporting.fn_customer_order_count('C00000001');
-- SELECT reporting.fn_customer_historical_order_value('C00000001');
-- SELECT reporting.fn_product_gross_margin_pct('P00001');
