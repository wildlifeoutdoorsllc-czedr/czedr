-- Least-privilege local user for the Saturn DB only (ledger-only API).
-- Run: mysql -u root < scripts/setup-secure-local.sql

SOURCE scripts/local-mysql-init.sql;

SOURCE database/schemas/saturn.sql;

CREATE USER IF NOT EXISTS 'app_saturn'@'localhost' IDENTIFIED BY 'LocalApp_Saturn_2026!';
GRANT ALL PRIVILEGES ON saturn.* TO 'app_saturn'@'localhost';

FLUSH PRIVILEGES;

SELECT 'Czedr secure local setup complete (saturn only)' AS status;
