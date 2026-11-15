-- Conservative numeric/domain checks; no undocumented status enums assumed.
ALTER TABLE core.customers
    ADD CONSTRAINT chk_customers_lifetime_orders_nonnegative CHECK (lifetime_orders >= 0),
    ADD CONSTRAINT chk_customers_lifetime_spend_nonnegative CHECK (lifetime_spend >= 0);
ALTER TABLE core.products
    ADD CONSTRAINT chk_products_price_nonnegative CHECK (price >= 0),
    ADD CONSTRAINT chk_products_cost_nonnegative CHECK (cost >= 0),
    ADD CONSTRAINT chk_products_avg_rating_range CHECK (avg_rating BETWEEN 0 AND 5);
ALTER TABLE core.sessions
    ADD CONSTRAINT chk_sessions_pages_viewed_nonnegative CHECK (pages_viewed >= 0);
ALTER TABLE core.orders
    ADD CONSTRAINT chk_orders_item_count_nonnegative CHECK (item_count >= 0),
    ADD CONSTRAINT chk_orders_order_total_nonnegative CHECK (order_total >= 0);
ALTER TABLE core.order_items
    ADD CONSTRAINT chk_order_items_quantity_positive CHECK (quantity > 0),
    ADD CONSTRAINT chk_order_items_unit_price_nonnegative CHECK (unit_price >= 0),
    ADD CONSTRAINT chk_order_items_line_total_nonnegative CHECK (line_total >= 0);
ALTER TABLE core.returns
    ADD CONSTRAINT chk_returns_refund_amount_nonnegative CHECK (refund_amount >= 0);
ALTER TABLE core.support_tickets
    ADD CONSTRAINT chk_support_tickets_resolution_days_nonnegative
    CHECK (resolution_days IS NULL OR resolution_days >= 0);
