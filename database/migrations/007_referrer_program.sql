USE saturn;

-- Idempotent: skip if referred_by_user_id already exists (e.g. from saturn.sql or prior run).
SET @has_ref := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'saturn' AND TABLE_NAME = 'users' AND COLUMN_NAME = 'referred_by_user_id'
);
SET @sql := IF(
    @has_ref = 0,
    'ALTER TABLE users
        ADD COLUMN referred_by_user_id CHAR(36) NULL
            AFTER pin_hash,
        ADD CONSTRAINT fk_users_referred_by
            FOREIGN KEY (referred_by_user_id) REFERENCES users(id),
        ADD INDEX idx_users_referred_by (referred_by_user_id)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
