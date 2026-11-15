-- Add primary keys after importing data and passing duplicate/null validation.
ALTER TABLE core.customers ADD CONSTRAINT pk_customers PRIMARY KEY (customer_id);
ALTER TABLE core.categories ADD CONSTRAINT pk_categories PRIMARY KEY (category_id);
ALTER TABLE core.subcategories ADD CONSTRAINT pk_subcategories PRIMARY KEY (subcategory_id);
ALTER TABLE core.products ADD CONSTRAINT pk_products PRIMARY KEY (product_id);
ALTER TABLE core.sessions ADD CONSTRAINT pk_sessions PRIMARY KEY (session_id);
ALTER TABLE core.orders ADD CONSTRAINT pk_orders PRIMARY KEY (order_id);
ALTER TABLE core.order_items ADD CONSTRAINT pk_order_items PRIMARY KEY (order_item_id);
ALTER TABLE core.returns ADD CONSTRAINT pk_returns PRIMARY KEY (return_id);
ALTER TABLE core.support_tickets ADD CONSTRAINT pk_support_tickets PRIMARY KEY (ticket_id);
