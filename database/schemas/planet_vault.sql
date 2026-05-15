-- Run once per planet database (mercury, venus, earth, mars, jupiter)
CREATE TABLE IF NOT EXISTS vault_fields (
    vault_token CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    ciphertext VARBINARY(8192) NOT NULL,
    iv VARBINARY(12) NOT NULL,
    tag VARBINARY(16) NOT NULL,
    key_version SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vault_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
