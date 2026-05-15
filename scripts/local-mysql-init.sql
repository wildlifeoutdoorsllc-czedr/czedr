-- Local Czedr MySQL setup (planet database names)
-- Run: mysql -u root -p < scripts/local-mysql-init.sql

CREATE DATABASE IF NOT EXISTS mercury CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS venus CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS earth CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS mars CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS jupiter CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS saturn CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

SHOW DATABASES;
