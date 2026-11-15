-- Enforce natural keys supported by source profiling.
-- Do not make (order_id, product_id) unique: repeated pairs exist in source data.
ALTER TABLE core.categories
    ADD CONSTRAINT uq_categories_category_name UNIQUE (category_name);
ALTER TABLE core.subcategories
    ADD CONSTRAINT uq_subcategories_category_name
    UNIQUE (category_id, subcategory_name);
