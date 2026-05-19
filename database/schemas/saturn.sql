USE saturn;

CREATE TABLE IF NOT EXISTS users (
    id CHAR(36) PRIMARY KEY,
    czedr_id VARCHAR(32) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    pin_hash VARCHAR(255) NULL,
    referred_by_user_id CHAR(36) NULL,
    status ENUM('active', 'suspended') NOT NULL DEFAULT 'active',
    role ENUM('member', 'staff') NOT NULL DEFAULT 'member',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_czedr (czedr_id),
    INDEX idx_users_referred_by (referred_by_user_id),
    CONSTRAINT fk_users_referred_by FOREIGN KEY (referred_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS auth_sessions (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    token_hash CHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_sessions (user_id, expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ledger_accounts (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL UNIQUE,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    balance_cents BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_balance_non_negative CHECK (balance_cents >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ledger_transactions (
    id CHAR(36) PRIMARY KEY,
    idempotency_key VARCHAR(64) NOT NULL UNIQUE,
    from_user_id CHAR(36) NOT NULL,
    to_user_id CHAR(36) NOT NULL,
    amount_cents BIGINT NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    status ENUM('pending', 'completed', 'failed', 'reversed') NOT NULL DEFAULT 'pending',
    memo VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id),
    INDEX idx_from_user (from_user_id, created_at),
    INDEX idx_to_user (to_user_id, created_at),
    CONSTRAINT chk_amount_positive CHECK (amount_cents > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ledger_entries (
    id CHAR(36) PRIMARY KEY,
    transaction_id CHAR(36) NOT NULL,
    account_id CHAR(36) NOT NULL,
    entry_type ENUM('debit', 'credit') NOT NULL,
    amount_cents BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transaction_id) REFERENCES ledger_transactions(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES ledger_accounts(id),
    INDEX idx_txn (transaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_events (
    id CHAR(36) PRIMARY KEY,
    actor_user_id CHAR(36) NULL,
    action VARCHAR(64) NOT NULL,
    resource_type VARCHAR(64) NOT NULL,
    resource_id VARCHAR(64) NULL,
    ip_address VARCHAR(45) NULL,
    user_agent VARCHAR(512) NULL,
    meta_json JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_actor (actor_user_id, created_at),
    INDEX idx_action (action, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS signup_challenges (
    id CHAR(36) PRIMARY KEY,
    image_url VARCHAR(512) NOT NULL,
    image_b64 MEDIUMTEXT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_signup_challenge_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    token_hash CHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_reset_user (user_id, expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS invoices (
    id CHAR(36) PRIMARY KEY,
    from_user_id CHAR(36) NOT NULL,
    to_user_id CHAR(36) NOT NULL,
    amount_cents BIGINT NOT NULL,
    description VARCHAR(255) NOT NULL DEFAULT '',
    status ENUM('pending', 'paid', 'cancelled', 'rejected') NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id),
    INDEX idx_to_pending (to_user_id, status, created_at),
    INDEX idx_from_pending (from_user_id, status, created_at),
    CONSTRAINT chk_invoice_amount_positive CHECK (amount_cents > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
