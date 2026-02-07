# 演習：VACUUMの効果と肥大化（Bloat）の確認

PostgreSQL特有の「不要領域（ゴミ）」がどのように発生し、VACUUMでどう処理されるかを理解する演習。

## シナリオ（VACCUM）

- **準備**: 大量のテストデータ（1万件程度）を持つテーブルを作成する。
  - `SELECT pg_relation_size('テーブル名');` で現在のサイズを確認する。
- **更新**: `UPDATE` 文ですべての行の値を書き換える。
  - PostgreSQLは「古い行に削除フラグを立て、新しい行を追加」するため、この時点でデータ量は約2倍に増えている。
- **確認（不要領域）**: `pg_stat_user_tables` ビューを参照し、`n_dead_tup`（死んだタプル数）が増えていることを確認する。
- **実行（通常VACUUM）**: `VACUUM ANALYZE テーブル名;` を実行する。
  - 再度サイズを確認します。**サイズ自体は小さくならない**（再利用可能になるだけ）ことに注目する。
- **実行（FULL）**: `VACUUM FULL テーブル名;` を実行する。
  - 再度サイズを確認します。OSに領域が返却され、ファイルサイズが劇的に小さくなるはず。

```sql
-- テーブルなどの作成
postgres=# create database study_db;
postgres=# create schema vaccum_schema;
postgres=# create table vaccum_schema.test_tbl (id varchar(8), name varchar(256));

-- データ挿入
postgres=# insert into vaccum_schema.test_tbl (id, name)
select left(md5(random()::text),8), left(md5(random()::text),128)
from generate_series(1, 100000);
INSERT 0 100000

-- ファイルサイズの確認
postgres=# select pg_relation_size('vaccum_schema.test_tbl');
 pg_relation_size 
------------------
          7659520

-- データの更新
postgres=# update vaccum_schema.test_tbl set name = left(md5(random()::text),200) where 1 = 1;
UPDATE 100000
postgres=# SELECT pg_relation_size('vaccum_schema.test_tbl');
 pg_relation_size 
------------------
         15319040
(1 row)

postgres=# SELECT n_live_tup, n_dead_tup 
FROM pg_stat_user_tables 
WHERE relname = 'test_tbl';
 n_live_tup | n_dead_tup 
------------+------------
     100000 |          0
(1 row)

-- 通常のVACCUMだと減らない(内部的に「空き家」としてマークされるのみ)
postgres=# VACUUM vaccum_schema.test_tbl;
VACUUM
postgres=# SELECT pg_relation_size('vaccum_schema.test_tbl');
 pg_relation_size 
------------------
         15319040
(1 row)

postgres=# SELECT n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'test_tbl';
 n_live_tup | n_dead_tup 
------------+------------
     100000 |          0
(1 row)

-- VACUUM FULL
postgres=# VACUUM FULL vaccum_schema.test_tbl;
VACUUM

postgres=# SELECT pg_relation_size('vaccum_schema.test_tbl');
 pg_relation_size 
------------------
          7659520
(1 row)

postgres=# SELECT n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'test_tbl';
 n_live_tup | n_dead_tup 
------------+------------
     100000 |          0
(1 row)
```
