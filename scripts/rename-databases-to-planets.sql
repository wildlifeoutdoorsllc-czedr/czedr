-- Rename Czedr databases to planet names (MySQL / AWS RDS)
-- Run as a privileged user (e.g. master) after backup.
-- Update PHP/app config to use new database names after this script succeeds.
--
-- Mapping:
--   admin_de23      → mercury   (creditcard_name)
--   admin_yuy78     → venus     (creditcard_type)
--   admin_aqw2      → earth     (creditcard_number)
--   admin_lop90     → mars      (creditcard_expired)
--   admin_kjui89u   → jupiter   (creditcard_cvv_number)
--   admin_3ds3cur3  → saturn    (main application)

-- MySQL has no RENAME DATABASE; create new DB and move tables.

-- 1. Mercury (creditcard_name)
CREATE DATABASE IF NOT EXISTS mercury CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- Move each table (repeat per table in source DB):
-- RENAME TABLE admin_de23.`your_table` TO mercury.`your_table`;

-- 2. Venus (creditcard_type)
CREATE DATABASE IF NOT EXISTS venus CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- RENAME TABLE admin_yuy78.`your_table` TO venus.`your_table`;

-- 3. Earth (creditcard_number)
CREATE DATABASE IF NOT EXISTS earth CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- RENAME TABLE admin_aqw2.`your_table` TO earth.`your_table`;

-- 4. Mars (creditcard_expired)
CREATE DATABASE IF NOT EXISTS mars CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- RENAME TABLE admin_lop90.`your_table` TO mars.`your_table`;

-- 5. Jupiter (creditcard_cvv_number)
CREATE DATABASE IF NOT EXISTS jupiter CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- RENAME TABLE admin_kjui89u.`your_table` TO jupiter.`your_table`;

-- 6. Saturn (main application)
CREATE DATABASE IF NOT EXISTS saturn CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- RENAME TABLE admin_3ds3cur3.`your_table` TO saturn.`your_table`;

-- Re-grant privileges for existing users (adjust if usernames change):
GRANT ALL PRIVILEGES ON mercury.* TO 'admin_er4'@'%';
GRANT ALL PRIVILEGES ON venus.* TO 'admin_iu789i'@'%';
GRANT ALL PRIVILEGES ON earth.* TO 'admin_w34e'@'%';
GRANT ALL PRIVILEGES ON mars.* TO 'admin_lk980'@'%';
GRANT ALL PRIVILEGES ON jupiter.* TO 'admin_ju789u'@'%';
GRANT ALL PRIVILEGES ON saturn.* TO 'admin_3ds3cur3'@'%';
FLUSH PRIVILEGES;

-- After verifying apps work against new names, drop legacy databases:
-- DROP DATABASE admin_de23;
-- DROP DATABASE admin_yuy78;
-- DROP DATABASE admin_aqw2;
-- DROP DATABASE admin_lop90;
-- DROP DATABASE admin_kjui89u;
-- DROP DATABASE admin_3ds3cur3;
