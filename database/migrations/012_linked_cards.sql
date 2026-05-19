USE saturn;

CREATE TABLE IF NOT EXISTS linked_cards (
    id CHAR(36) NOT NULL PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    display_name VARCHAR(128) NOT NULL,
    last_four CHAR(4) NOT NULL,
    exp_label VARCHAR(16) NULL,
    card_brand VARCHAR(32) NOT NULL DEFAULT 'visa',
    is_default TINYINT(1) NOT NULL DEFAULT 0,
    image_filename VARCHAR(128) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_linked_cards_user (user_id),
    CONSTRAINT fk_linked_cards_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
