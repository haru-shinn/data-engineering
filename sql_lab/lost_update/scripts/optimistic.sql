BEGIN;
-- 1. 現在の残高とバージョンを読み取る
-- (実際はアプリの変数に balance=7102, version=1 と保存される)
SELECT balance, version FROM sample_tbl_2 WHERE id = 'c4ca4238_100001';

-- 2. 更新を試みる。ただし、「自分が読み取った時のversion」であることを条件にする。
-- 同時にversionを +1 する。
UPDATE sample_tbl_2 
SET balance = balance + 1, version = version + 1 
WHERE id = 'c4ca4238_100001' AND version = 1;
COMMIT;