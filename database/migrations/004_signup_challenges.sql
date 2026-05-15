USE saturn;

CREATE TABLE IF NOT EXISTS signup_challenges (
    id CHAR(36) PRIMARY KEY,
    image_url VARCHAR(512) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_signup_challenge_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
