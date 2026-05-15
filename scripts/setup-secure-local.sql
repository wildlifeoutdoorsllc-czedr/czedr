-- Secure local setup: schemas + least-privilege planet users
-- Run: mysql -u root < scripts/setup-secure-local.sql

SOURCE scripts/local-mysql-init.sql;

SOURCE database/schemas/saturn.sql;

USE mercury;
SOURCE database/schemas/planet_vault.sql;

USE venus;
SOURCE database/schemas/planet_vault.sql;

USE earth;
SOURCE database/schemas/planet_vault.sql;

USE mars;
SOURCE database/schemas/planet_vault.sql;

USE jupiter;
SOURCE database/schemas/planet_vault.sql;

-- Planet vault users (local dev passwords — change in production)
CREATE USER IF NOT EXISTS 'vault_mercury'@'localhost' IDENTIFIED BY 'LocalVault_Mercury_2026!';
CREATE USER IF NOT EXISTS 'vault_venus'@'localhost' IDENTIFIED BY 'LocalVault_Venus_2026!';
CREATE USER IF NOT EXISTS 'vault_earth'@'localhost' IDENTIFIED BY 'LocalVault_Earth_2026!';
CREATE USER IF NOT EXISTS 'vault_mars'@'localhost' IDENTIFIED BY 'LocalVault_Mars_2026!';
CREATE USER IF NOT EXISTS 'vault_jupiter'@'localhost' IDENTIFIED BY 'LocalVault_Jupiter_2026!';
CREATE USER IF NOT EXISTS 'app_saturn'@'localhost' IDENTIFIED BY 'LocalApp_Saturn_2026!';

GRANT SELECT, INSERT, UPDATE, DELETE ON mercury.* TO 'vault_mercury'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON venus.* TO 'vault_venus'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON earth.* TO 'vault_earth'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON mars.* TO 'vault_mars'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON jupiter.* TO 'vault_jupiter'@'localhost';
GRANT ALL PRIVILEGES ON saturn.* TO 'app_saturn'@'localhost';

FLUSH PRIVILEGES;

SELECT 'Czedr secure local setup complete' AS status;
