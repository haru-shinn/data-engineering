# パーティション

## リストパーティション

```sql
-- 親テーブルの作成
CREATE TABLE sales (id int, region text, amount int) PARTITION BY LIST (region);

-- 子テーブル（パーティションの作成）
CREATE TABLE sales_tokyo PARTITION OF sales FOR VALUES IN ('Tokyo');

-- データ挿入
INSERT INTO sales VALUES (1, 'Tokyo', 100); -- sales_tokyoに入る
INSERT INTO sales_tokyo VALUES (2, 'Tokyo', 200); -- sales_tokyoに入る
INSERT INTO sales_tokyo VALUES (2, 'XXX', 200); -- 失敗

/*
study_db=# INSERT INTO sales_tokyo VALUES (2, 'XXX', 200);
2026-03-07 02:38:33.591 UTC [29] ERROR:  new row for relation "sales_tokyo" violates partition constraint
2026-03-07 02:38:33.591 UTC [29] DETAIL:  Failing row contains (2, XXX, 200).
2026-03-07 02:38:33.591 UTC [29] STATEMENT:  INSERT INTO sales_tokyo VALUES (2, 'XXX', 200);
ERROR:  new row for relation "sales_tokyo" violates partition constraint
DETAIL:  Failing row contains (2, XXX, 200).
*/

-- 結果確認
SELECT * FROM sales;
/*
 id | region | amount 
----+--------+--------
  1 | Tokyo  |    100
  2 | Tokyo  |    200
(2 rows)
*/
SELECT * FROM sales_tokyo;
/*
 id | region | amount 
----+--------+--------
  1 | Tokyo  |    100
  2 | Tokyo  |    200
(2 rows)
*/
```

## レンジパーティション

### 基本

```sql
-- テーブル作成
create table measurement (
    city_id int not null
    , logdate date not null
    , peaktemp int
    , unitsales int
) partition by range (logdate);

CREATE TABLE measurement_y2006m02 PARTITION OF measurement
    FOR VALUES FROM ('2006-02-01') TO ('2006-03-01');

CREATE TABLE measurement_y2006m03 PARTITION OF measurement
    FOR VALUES FROM ('2006-03-01') TO ('2006-04-01');

CREATE TABLE measurement_y2007m11 PARTITION OF measurement
    FOR VALUES FROM ('2007-11-01') TO ('2007-12-01');

-- データ挿入
INSERT INTO measurement VALUES (1, '2006-02-02', 11, 22);
INSERT INTO measurement VALUES (1, '2006-03-01', 11, 22);
INSERT INTO measurement VALUES (1, '2005-05-05', 11, 22);
INSERT INTO measurement VALUES (1, '2010-10-02', 11, 22);

-- 挿入結果（パーティション作成していない範囲のデータはエラーとなる）
study_db=# INSERT INTO measurement VALUES (1, '2006-02-02', 11, 22);
INSERT INTO measurement VALUES (1, '2006-03-01', 11, 22);
INSERT INTO measurement VALUES (1, '2005-05-05', 11, 22);
INSERT INTO measurement VALUES (1, '2010-10-02', 11, 22);
INSERT 0 1
INSERT 0 1
2026-03-07 02:55:50.799 UTC [29] ERROR:  no partition of relation "measurement" found for row
2026-03-07 02:55:50.799 UTC [29] DETAIL:  Partition key of the failing row contains (logdate) = (2005-05-05).
2026-03-07 02:55:50.799 UTC [29] STATEMENT:  INSERT INTO measurement VALUES (1, '2005-05-05', 11, 22);
ERROR:  no partition of relation "measurement" found for row
DETAIL:  Partition key of the failing row contains (logdate) = (2005-05-05).
2026-03-07 02:55:50.800 UTC [29] ERROR:  no partition of relation "measurement" found for row
2026-03-07 02:55:50.800 UTC [29] DETAIL:  Partition key of the failing row contains (logdate) = (2010-10-02).
2026-03-07 02:55:50.800 UTC [29] STATEMENT:  INSERT INTO measurement VALUES (1, '2010-10-02', 11, 22);
ERROR:  no partition of relation "measurement" found for row
DETAIL:  Partition key of the failing row contains (logdate) = (2010-10-02).


-- 結果
study_db=# select * from measurement;
 city_id |  logdate   | peaktemp | unitsales 
---------+------------+----------+-----------
       1 | 2006-02-02 |       11 |        22
       1 | 2006-03-01 |       11 |        22
(2 rows)

study_db=# select * from measurement_y2006m02;
 city_id |  logdate   | peaktemp | unitsales 
---------+------------+----------+-----------
       1 | 2006-02-02 |       11 |        22
(1 row)

select * from measurement_y2006m03;
 city_id |  logdate   | peaktemp | unitsales 
---------+------------+----------+-----------
       1 | 2006-03-01 |       11 |        22
(1 row)

study_db=# select * from measurement_y2007m11;
 city_id | logdate | peaktemp | unitsales 
---------+---------+----------+-----------
(0 rows)
```

### インデックス

```bash
-- Index
study_db=# CREATE INDEX ON measurement (logdate);
CREATE INDEX


study_db=# SELECT tablename, indexname FROM pg_indexes WHERE tablename LIKE 'measurement%';
      tablename       |            indexname             
----------------------+----------------------------------
 measurement          | measurement_logdate_idx
 measurement_y2006m02 | measurement_y2006m02_logdate_idx
 measurement_y2006m03 | measurement_y2006m03_logdate_idx
 measurement_y2007m11 | measurement_y2007m11_logdate_idx
```

### パーティションの保守

```bash
study_db=# CREATE TABLE measurement_y2007m12 (
    city_id int not null
    , logdate date not null
    , peaktemp int
    , unitsales int
); 

study_db=# ALTER TABLE measurement ATTACH PARTITION measurement_y2007m12 FOR VALUES FROM ('2007-12-01') TO ('2008-01-01');
ALTER TABLE

study_db=# ALTER TABLE measurement DETACH PARTITION measurement_y2007m12;
ALTER TABLE

```
