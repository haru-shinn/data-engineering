BEGIN;
SELECT balance FROM sample_tbl WHERE id = 'c4ca4238_000001';
-- (ここでアプリ側が計算して1001円にするイメージ)
UPDATE sample_tbl SET balance = balance + 1 WHERE id = 'c4ca4238_000001';
COMMIT;