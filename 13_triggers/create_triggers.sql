
/*
Project: Ecommerce-Database-Engineering
Module: 13 - Triggers
File: create_triggers.sql

Run trigger_functions.sql before executing this file.

Captures INSERT, UPDATE and DELETE operations on:
orders, order_items, returns, products and support_tickets.
*/


-- 1. ORDERS

DROP TRIGGER IF EXISTS trg_orders_audit_changes
ON core.orders;

CREATE TRIGGER trg_orders_audit_changes
AFTER INSERT OR UPDATE OR DELETE
ON core.orders
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change('order_id');


-- 2. ORDER ITEMS

DROP TRIGGER IF EXISTS trg_order_items_audit_changes
ON core.order_items;

CREATE TRIGGER trg_order_items_audit_changes
AFTER INSERT OR UPDATE OR DELETE
ON core.order_items
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change('order_item_id');


-- 3. RETURNS

DROP TRIGGER IF EXISTS trg_returns_audit_changes
ON core.returns;

CREATE TRIGGER trg_returns_audit_changes
AFTER INSERT OR UPDATE OR DELETE
ON core.returns
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change('return_id');


-- 4. PRODUCTS

DROP TRIGGER IF EXISTS trg_products_audit_changes
ON core.products;

CREATE TRIGGER trg_products_audit_changes
AFTER INSERT OR UPDATE OR DELETE
ON core.products
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change('product_id');


-- 5. SUPPORT TICKETS

DROP TRIGGER IF EXISTS trg_support_tickets_audit_changes
ON core.support_tickets;

CREATE TRIGGER trg_support_tickets_audit_changes
AFTER INSERT OR UPDATE OR DELETE
ON core.support_tickets
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change('ticket_id');


-- VERIFY INSTALLED TRIGGERS

SELECT
    event_object_schema AS table_schema,
    event_object_table AS table_name,
    trigger_name,
    event_manipulation AS event,
    action_timing AS timing
FROM information_schema.triggers
WHERE event_object_schema = 'core'
AND event_object_table IN
(
    'orders',
    'order_items',
    'returns',
    'products',
    'support_tickets'
)
AND trigger_name LIKE 'trg_%_audit_changes'
ORDER BY
    event_object_table,
    trigger_name,
    event_manipulation;


-- VIEW RECENT AUDIT RECORDS

SELECT
    audit_id,
    schema_name,
    table_name,
    operation,
    record_key,
    changed_at,
    changed_by
FROM audit.row_change_log
ORDER BY audit_id DESC
LIMIT 50;
