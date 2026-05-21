-- Micro-deposit bank verification (no Plaid / aggregator credentials).
-- Extends moov_bank_links; moov_bank_account_id optional until an external rail id exists.
USE saturn;

ALTER TABLE moov_bank_links
    MODIFY moov_bank_account_id VARCHAR(64) NULL,
    ADD COLUMN link_method VARCHAR(32) NOT NULL DEFAULT 'microdeposit' AFTER user_id,
    ADD COLUMN account_type VARCHAR(16) NOT NULL DEFAULT 'checking' AFTER link_method,
    ADD COLUMN account_holder_name VARCHAR(128) NULL AFTER account_type,
    ADD COLUMN routing_last4 CHAR(4) NULL AFTER account_holder_name,
    ADD COLUMN account_vault VARBINARY(512) NULL COMMENT 'AES-GCM ciphertext: routing+account JSON' AFTER routing_last4,
    ADD COLUMN micro_cents_a SMALLINT UNSIGNED NULL AFTER account_vault,
    ADD COLUMN micro_cents_b SMALLINT UNSIGNED NULL AFTER micro_cents_a,
    ADD COLUMN micro_sent_at TIMESTAMP NULL AFTER micro_cents_b,
    ADD COLUMN verified_at TIMESTAMP NULL AFTER micro_sent_at,
    ADD COLUMN confirm_attempts TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER verified_at;

CREATE TABLE IF NOT EXISTS ach_withdrawals (
    id CHAR(36) NOT NULL PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    bank_link_id CHAR(36) NOT NULL,
    amount_cents INT UNSIGNED NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    idempotency_key VARCHAR(64) NOT NULL,
    ledger_hold_txn_id CHAR(36) NULL,
    rail_transfer_id VARCHAR(64) NULL,
    failure_reason VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    UNIQUE KEY uk_ach_withdrawals_idempotency (idempotency_key),
    UNIQUE KEY uk_ach_withdrawals_rail_transfer (rail_transfer_id),
    INDEX idx_ach_withdrawals_user_status (user_id, status),
    CONSTRAINT fk_ach_withdrawals_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ach_withdrawals_bank FOREIGN KEY (bank_link_id) REFERENCES moov_bank_links(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
