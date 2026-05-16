USE saturn;

-- Idempotent: safe when schema_migrations is first populated on an DB that already has `role`.
SET @has_role := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'saturn' AND TABLE_NAME = 'users' AND COLUMN_NAME = 'role'
);
SET @sql := IF(
    @has_role = 0,
    'ALTER TABLE users
        ADD COLUMN role ENUM(\'member\', \'staff\') NOT NULL DEFAULT \'member\'
            AFTER status',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
