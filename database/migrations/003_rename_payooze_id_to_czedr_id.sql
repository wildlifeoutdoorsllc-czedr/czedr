-- Rename legacy payooze_id column to czedr_id (idempotent for fresh + existing DBs)
USE saturn;

SET @has_payooze := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'saturn' AND TABLE_NAME = 'users' AND COLUMN_NAME = 'payooze_id'
);

SET @sql := IF(
    @has_payooze > 0,
    'ALTER TABLE users CHANGE COLUMN payooze_id czedr_id VARCHAR(32) NOT NULL',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_old_idx := (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = 'saturn' AND TABLE_NAME = 'users' AND INDEX_NAME = 'idx_payooze'
);
SET @sql2 := IF(
    @has_old_idx > 0,
    'ALTER TABLE users DROP INDEX idx_payooze, ADD INDEX idx_czedr (czedr_id)',
    'SELECT 1'
);
PREPARE stmt2 FROM @sql2;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

SET @has_czedr_idx := (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = 'saturn' AND TABLE_NAME = 'users' AND INDEX_NAME = 'idx_czedr'
);
SET @sql3 := IF(
    @has_czedr_idx = 0 AND @has_payooze = 0,
    'ALTER TABLE users ADD INDEX idx_czedr (czedr_id)',
    'SELECT 1'
);
PREPARE stmt3 FROM @sql3;
EXECUTE stmt3;
DEALLOCATE PREPARE stmt3;
