-- Ledger-only product: remove unused bank / ACH metadata (fresh installs skip these via saturn.sql).
USE saturn;

DROP TABLE IF EXISTS ach_export_batches;
DROP TABLE IF EXISTS bank_account_refs;
