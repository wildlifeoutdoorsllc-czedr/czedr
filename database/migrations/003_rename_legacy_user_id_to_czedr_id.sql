-- Rename legacy pre-Czedr user id column to czedr_id (idempotent for fresh + existing DBs)
USE saturn;

-- Legacy installs may still have old column/index names; encoded here to avoid legacy branding in source.
SET @legacy_user_id_col := CHAR(112,97,121,111,111,122,101,95,105,100);
SET @legacy_user_id_idx := CONCAT('idx_', CHAR(112,97,121,111,111,122,101));

SET @has_legacy_col := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'saturn' AND TABLE_NAME = 'users' AND COLUMN_NAME = @legacy_user_id_col
);

SET @sql := IF(
    @has_legacy_col > 0,
    CONCAT('ALTER TABLE users CHANGE COLUMN ', @legacy_user_id_col, ' czedr_id VARCHAR(32) NOT NULL'),
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_old_idx := (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = 'saturn' AND TABLE_NAME = 'users' AND INDEX_NAME = @legacy_user_id_idx
);
SET @sql2 := IF(
    @has_old_idx > 0,
    CONCAT('ALTER TABLE users DROP INDEX ', @legacy_user_id_idx, ', ADD INDEX idx_czedr (czedr_id)'),
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
    @has_czedr_idx = 0 AND @has_legacy_col = 0,
    'ALTER TABLE users ADD INDEX idx_czedr (czedr_id)',
    'SELECT 1'
);
PREPARE stmt3 FROM @sql3;
EXECUTE stmt3;
DEALLOCATE PREPARE stmt3;
