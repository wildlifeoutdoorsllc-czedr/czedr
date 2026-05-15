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
