USE saturn;

CREATE TABLE IF NOT EXISTS moov_accounts (
    user_id CHAR(36) NOT NULL PRIMARY KEY,
    moov_account_id VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_moov_accounts_moov_id (moov_account_id),
    CONSTRAINT fk_moov_accounts_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS moov_bank_links (
    id CHAR(36) NOT NULL PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    moov_bank_account_id VARCHAR(64) NOT NULL,
    bank_name VARCHAR(128) NULL,
    last_four CHAR(4) NULL,
    is_default TINYINT(1) NOT NULL DEFAULT 0,
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_moov_bank_user (user_id),
    UNIQUE KEY uk_moov_bank_moov_id (moov_bank_account_id),
    CONSTRAINT fk_moov_bank_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ach_deposits (
    id CHAR(36) NOT NULL PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    moov_bank_link_id CHAR(36) NULL,
    amount_cents INT UNSIGNED NOT NULL,
    moov_transfer_id VARCHAR(64) NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    idempotency_key VARCHAR(64) NOT NULL,
    ledger_txn_id CHAR(36) NULL,
    failure_reason VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    UNIQUE KEY uk_ach_deposits_idempotency (idempotency_key),
    UNIQUE KEY uk_ach_deposits_moov_transfer (moov_transfer_id),
    INDEX idx_ach_deposits_user_status (user_id, status),
    CONSTRAINT fk_ach_deposits_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ach_deposits_bank FOREIGN KEY (moov_bank_link_id) REFERENCES moov_bank_links(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
