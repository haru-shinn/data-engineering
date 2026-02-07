# バックアップ方法の簡単な確認

## walの中身を見る

```bash
# WALファイルの中身を確認する
$ cd /var/lib/postgresql/16/main/pg_wal
$ /usr/lib/postgresql/16/bin/pg_waldump 000000010000000000000001
```

---

## バックアップ

論理バックアップのみ実施

```bash
# dumpファイルの作成
$ pg_dump study_db > study_db.dump

$ ls -la
-rw-r--r-- 1 postgres postgres     1292 Feb  7 00:43 study_db.dump


# リストア
$ createdb study_bk_db

$ psql -U postgres -d postgres -c "\l"
                                                    List of databases
    Name     |  Owner   | Encoding  | Locale Provider | Collate | Ctype | ICU Locale | ICU Rules |   Access privileges   
-------------+----------+-----------+-----------------+---------+-------+------------+-----------+-----------------------
 postgres    | postgres | SQL_ASCII | libc            | C       | C     |            |           | 
 study_bk_db | postgres | SQL_ASCII | libc            | C       | C     |            |           | 
 study_db    | postgres | SQL_ASCII | libc            | C       | C     |            |           | 

$ psql study_bk_db < study_db.dump

# 確認
postgres@642e764eae2f:~/16/main/pg_wal$ psql -U postgres -d study_bk_db -c "\dt"
Did not find any relations.
postgres@642e764eae2f:~/16/main/pg_wal$ psql -U postgres -d study_bk_db -c "\dt user_tmp.*"
           List of relations
  Schema  |   Name   | Type  |  Owner   
----------+----------+-------+----------
 user_tmp | test_tbl | table | postgres
(1 row)
postgres@642e764eae2f:~/16/main/pg_wal$ psql -U postgres -d study_bk_db -c "select * from user_tmp.test_tbl;"
  id  |  name  
------+--------
 ABCD | tanaka
 XYZZ | sato
(2 rows)
```
