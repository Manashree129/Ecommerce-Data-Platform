-- No new business-column defaults are added here.
-- CSV imports supply business values; arbitrary defaults could fabricate data.
-- category_id and subcategory_id are identity columns in the core table DDL.
-- This query documents defaults and identity generation already configured.
SELECT table_name, column_name, data_type, column_default,
       is_identity, identity_generation
FROM information_schema.columns
WHERE table_schema = 'core'
  AND (column_default IS NOT NULL OR is_identity = 'YES')
ORDER BY table_name, ordinal_position;
