# チューニングの学習（インデックス）

## 利用環境

```bash
# PostgreSQL と Ubuntu
psql (PostgreSQL) 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)
```

---

## 準備

```sql
-- スキーマの作成
create schema tuning;

-- テーブルの作成
-- 利用者
CREATE TABLE IF NOT EXISTS tuning.user (
 user_id integer
 , user_name varchar(16)
 , address varchar(128)
 , phone_number varchar(16)
 , PRIMARY KEY(user_id)
);

-- 予約
CREATE TABLE IF NOT EXISTS tuning.reservation (
 reservation_id integer
 , user_id integer
 , num_people integer
 , chekin_date date
 , chekout_date date
 , PRIMARY KEY(reservation_id)
);

-- データの挿入
-- userテーブルに10万件
INSERT INTO tuning."user"
SELECT 
    i
    , 'User_' || i
    , CASE 
        WHEN i % 2 = 0 THEN '東京都'
        ELSE '大阪府'
      END || i
    , '090-0000-' || LPAD(i::text, 4, '0')
FROM generate_series(1, 100000) s(i);

-- reservationテーブルに100万件
INSERT INTO tuning.reservation
SELECT
    i
    , (random() * 99999 + 1)::int
    , (random() * 5 + 1)::int
    , CURRENT_DATE + (random() * 365)::int * INTERVAL '1 day'
    , CURRENT_DATE + (random() * 365 + 1)::int * INTERVAL '1 day'
FROM generate_series(1, 1000000) s(i);
```

---

## 改善したいクエリ

予約データからとある月に宿泊予定者の一覧を抽出するクエリ

```sql
SELECT 
    u.user_name
    , r.chekin_date
    , r.num_people
FROM 
    tuning.reservation r
JOIN 
    tuning."user" u ON r.user_id = u.user_id
WHERE 
    u.address LIKE '東京都%' 
    AND r.chekin_date BETWEEN '2026-01-01' AND '2026-01-31';
```

---

### インデックス無し

- ボトルネックの特定
  - 観点: `actual time` の最大値と各ノードの実行時間の差分
  - 分析: 実行計画全体の中で「どこで一番時間を食っているか」の確認
    - `Execution Time` （合計の実行時間）が73mm
    - `Parallel Seq Scan on reservation r` が 33.228mm
  - 判断:
    - `reservation` テーブルの読み込みを早くできないか？
- 無駄な作業（スキャン効率）を探す
  - 観点: 時間はかかるが必要な作業か否かの確認（`Rows Removed by Filter`）
  - 分析:
    - `reservation` テーブル: `Rows Removed by Filter: 308,179`
    - `user` テーブル: `Rows Removed by Filter: 50,000`
  - 判断: `reservation` テーブルで、読み込んだが30万件以上のデータを不必要なため捨てている → 無駄なデータを読み込んでいるため非効率。
  - 改善案: フィルタ条件である、`chekin_date` や `address` にインデックスを貼って改善できないかを検討する。
- 推定件数と実測件数の「ズレ」の確認
  - 観点: データベースの「予想（推定）」が外れると、間違った実行計画を立てるため、非効率な計画を立てていないか確認
  - 分析:
    - `Parallel Seq Scan` の推定（rows=2256） vs 実際（rows=25154） → 約10倍のズレ
    - `Seq Scan on "user"` の推定（rows=93） vs 実際（rows=50000） → 約500倍のズレ
  - 判断: データベースが「東京都の人は100人くらいだろう」と過小評価しています。そのせいで、本来はもっと重い処理なのに、軽い処理向けのプラン（小さなハッシュ作成など）を選んでいる可能性がある。
  - 改善案: `ANALYZE` コマンドを叩いて統計情報を最新 or 統計情報の収集設定を見直す必要
- ジョイン戦略の評価
  - 分析: `Hash Join` を利用しており、`user` テーブルをメモリ上に「ハッシュ」として保持している。
  - 判断: `user` テーブルから 50,000件抽出してハッシュ化しているが、インデックスを利用して数件までに絞り込める場合は`Nested Loop` のほうが速い可能性がある。
  - 改善案: `user.address` にもインデックスを貼り件数が減少する場合は、ジョインアルゴリズムの変化を期待できる。

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    u.user_name
    , r.chekin_date
    , r.num_people
FROM 
    tuning.reservation r
JOIN 
    tuning."user" u ON r.user_id = u.user_id
WHERE 
    u.address LIKE '東京都%' 
    AND r.chekin_date BETWEEN '2026-01-01' AND '2026-01-31';
```

```txt
Gather  (cost=2168.66..15315.41 rows=27 width=58) (actual time=14.345..72.458 rows=37734 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=9364
  ->  Hash Join  (cost=1168.66..14312.71 rows=11 width=58) (actual time=17.788..59.009 rows=12578 loops=3)
        Hash Cond: (r.user_id = u.user_id)
        Buffers: shared hit=9364
        ->  Parallel Seq Scan on reservation r  (cost=0.00..13138.12 rows=2256 width=12) (actual time=0.019..33.228 rows=25154 loops=3)
              Filter: ((chekin_date >= '2026-01-01'::date) AND (chekin_date <= '2026-01-31'::date))
              Rows Removed by Filter: 308179
              Buffers: shared hit=6370
        ->  Hash  (cost=1167.50..1167.50 rows=93 width=54) (actual time=17.634..17.634 rows=50000 loops=3)
              Buckets: 65536 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 2856kB
              Buffers: shared hit=2802
              ->  Seq Scan on "user" u  (cost=0.00..1167.50 rows=93 width=54) (actual time=0.018..9.884 rows=50000 loops=3)
                    Filter: ((address)::text ~~ '東京都%'::text)
                    Rows Removed by Filter: 50000
                    Buffers: shared hit=2802
Planning:
  Buffers: shared hit=7
Planning Time: 0.130 ms
Execution Time: 73.522 ms
```

### 抽出条件にインデックスを付与

- 予約テーブルの日付はインデックスの効果あり
  - `Parallel Seq Scan on reservation r` → `Bitmap Index Scan on idx_reservation_checkin`
- ユーザテーブルの住所の効果はなし
  - `Seq Scan on "user" u` が変わらず利用されている。
  - データの分布（選択性）の問題
    - 全体の20%〜30%以上のデータを取得する場合（今回だと50%）、インデックスをバラバラに読みに行く手間（ランダムアクセス）よりも、塊でドサッと読み込む `Seq Scan（シーケンシャルアクセス）` の方が効率的だと判断され、インデックスが無視されている。
  - ロケール（Locale）の設定問題（PostgreSQL特有の罠）
    - 標準のB-treeインデックスで LIKE '東京都%'（前方一致）を高速化するには、データベースの文字並び順（LC_COLLATE）が C（または POSIX）である必要がある。

```sql
-- インデックスの作成（データ量の多いreservationテーブルのみに付与）
-- 予約日の絞り込み用
CREATE INDEX idx_reservation_checkin ON tuning.reservation(chekin_date);
-- 住所の絞り込み用
CREATE INDEX idx_user_address ON tuning.user(address);

-- 結果確認
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    u.user_name
    , r.chekin_date
    , r.num_people
FROM 
    tuning.reservation r
JOIN 
    tuning."user" u ON r.user_id = u.user_id
WHERE 
    u.address LIKE '東京都%' 
    AND r.chekin_date BETWEEN '2026-01-01' AND '2026-01-31';
```

```txt
Hash Join  (cost=3804.18..11455.36 rows=35978 width=18) (actual time=18.604..44.274 rows=37734 loops=1)
  Hash Cond: (r.user_id = u.user_id)
  Buffers: shared hit=7306 read=64
  ->  Bitmap Heap Scan on reservation r  (cost=1001.50..8461.85 rows=72690 width=12) (actual time=4.698..17.512 rows=75462 loops=1)
        Recheck Cond: ((chekin_date >= '2026-01-01'::date) AND (chekin_date <= '2026-01-31'::date))
        Heap Blocks: exact=6369
        Buffers: shared hit=6372 read=64
        ->  Bitmap Index Scan on idx_reservation_checkin  (cost=0.00..983.32 rows=72690 width=0) (actual time=4.106..4.107 rows=75462 loops=1)
              Index Cond: ((chekin_date >= '2026-01-01'::date) AND (chekin_date <= '2026-01-31'::date))
              Buffers: shared hit=3 read=64
  ->  Hash  (cost=2184.00..2184.00 rows=49495 width=14) (actual time=13.781..13.783 rows=50000 loops=1)
        Buckets: 65536  Batches: 1  Memory Usage: 2856kB
        Buffers: shared hit=934
        ->  Seq Scan on "user" u  (cost=0.00..2184.00 rows=49495 width=14) (actual time=0.038..7.791 rows=50000 loops=1)
              Filter: ((address)::text ~~ '東京都%'::text)
              Rows Removed by Filter: 50000
              Buffers: shared hit=934
Planning:
  Buffers: shared hit=38 read=5
Planning Time: 2.200 ms
Execution Time: 45.345 ms
```

### インデックスの変更（住所に対して演算子クラスを指定）

- お試し
  - ロケール（Locale）の設定問題（PostgreSQL特有の罠）を解消
  - 文字並び順を更新
- 結果
  - 引き続き `Seq Scan on "user" u` が変わらず利用されているため、意味なしであった。
  - ユーザテーブルの住所カラムは、全体の半分が東京都であるため、インデックスを辿るより全件スキャンの方が効率的と判断されている。

```sql
-- 一旦削除
DROP INDEX tuning.idx_user_address;

-- 演算子クラスを指定して再作成
CREATE INDEX idx_user_address ON tuning.user(address text_pattern_ops);

-- 結果確認
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    u.user_name
    , r.chekin_date
    , r.num_people
FROM 
    tuning.reservation r
JOIN 
    tuning."user" u ON r.user_id = u.user_id
WHERE 
    u.address LIKE '東京都%' 
    AND r.chekin_date BETWEEN '2026-01-01' AND '2026-01-31';
```

```txt
Hash Join  (cost=3804.18..11455.36 rows=35978 width=18) (actual time=15.598..41.513 rows=37734 loops=1)
  Hash Cond: (r.user_id = u.user_id)
  Buffers: shared hit=7370
  ->  Bitmap Heap Scan on reservation r  (cost=1001.50..8461.85 rows=72690 width=12) (actual time=2.746..16.577 rows=75462 loops=1)
        Recheck Cond: ((chekin_date >= '2026-01-01'::date) AND (chekin_date <= '2026-01-31'::date))
        Heap Blocks: exact=6369
        Buffers: shared hit=6436
        ->  Bitmap Index Scan on idx_reservation_checkin  (cost=0.00..983.32 rows=72690 width=0) (actual time=2.147..2.148 rows=75462 loops=1)
              Index Cond: ((chekin_date >= '2026-01-01'::date) AND (chekin_date <= '2026-01-31'::date))
              Buffers: shared hit=67
  ->  Hash  (cost=2184.00..2184.00 rows=49495 width=14) (actual time=12.823..12.824 rows=50000 loops=1)
        Buckets: 65536  Batches: 1  Memory Usage: 2856kB
        Buffers: shared hit=934
        ->  Seq Scan on "user" u  (cost=0.00..2184.00 rows=49495 width=14) (actual time=0.007..7.002 rows=50000 loops=1)
              Filter: ((address)::text ~~ '東京都%'::text)
              Rows Removed by Filter: 50000
              Buffers: shared hit=934
Planning:
  Buffers: shared hit=49 read=2 dirtied=3
Planning Time: 3.446 ms
Execution Time: 42.400 ms
```

### カバリングインデックスのお試し

- お試し
  - インデックスを使うと「インデックスを探す」＋「テーブル本体（Heap）にデータを取りに行く」という2ステップが必要。
  - カバリングインデックス（INCLUDE句、または複合インデックス）を作成すると、必要なデータがすべてインデックス内に存在する状態になり、テーブル本体を見に行く手間がゼロになります（これを Index Only Scan と呼びます）
  - 今回のクエリでは、`user` テーブルの内、`address` （検索用）と `user_id` （結合用）の二つに対してインデックスを作成する。
- 結果
  - 引き続き `Seq Scan on "user" u` が変わらず利用されているため、意味なしであった。
  - 「カバリングインデックス」の成立条件: **「SELECT句や結合条件で使っているすべてのカラムが、インデックス内に揃っていること」**　が絶対条件

```sql
-- 既存のインデックスを削除
DROP INDEX IF EXISTS tuning.idx_user_address;

-- カバリングインデックスの作成
-- addressを検索キーにし、user_idをデータとして持たせる
CREATE INDEX idx_user_address_covering 
ON tuning.user(address text_pattern_ops) 
INCLUDE (user_id);

-- 結果確認
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    u.user_name
    , r.chekin_date
    , r.num_people
FROM 
    tuning.reservation r
JOIN 
    tuning."user" u ON r.user_id = u.user_id
WHERE 
    u.address LIKE '東京都%' 
    AND r.chekin_date BETWEEN '2026-01-01' AND '2026-01-31';
```

```txt
Hash Join  (cost=3804.18..11455.36 rows=35978 width=18) (actual time=15.643..42.462 rows=37734 loops=1)
  Hash Cond: (r.user_id = u.user_id)
  Buffers: shared hit=7370
  ->  Bitmap Heap Scan on reservation r  (cost=1001.50..8461.85 rows=72690 width=12) (actual time=2.899..17.181 rows=75462 loops=1)
        Recheck Cond: ((chekin_date >= '2026-01-01'::date) AND (chekin_date <= '2026-01-31'::date))
        Heap Blocks: exact=6369
        Buffers: shared hit=6436
        ->  Bitmap Index Scan on idx_reservation_checkin  (cost=0.00..983.32 rows=72690 width=0) (actual time=2.294..2.295 rows=75462 loops=1)
              Index Cond: ((chekin_date >= '2026-01-01'::date) AND (chekin_date <= '2026-01-31'::date))
              Buffers: shared hit=67
  ->  Hash  (cost=2184.00..2184.00 rows=49495 width=14) (actual time=12.714..12.715 rows=50000 loops=1)
        Buckets: 65536  Batches: 1  Memory Usage: 2856kB
        Buffers: shared hit=934
        ->  Seq Scan on "user" u  (cost=0.00..2184.00 rows=49495 width=14) (actual time=0.011..6.877 rows=50000 loops=1)
              Filter: ((address)::text ~~ '東京都%'::text)
              Rows Removed by Filter: 50000
              Buffers: shared hit=934
Planning:
  Buffers: shared hit=29 read=1
Planning Time: 0.272 ms
Execution Time: 43.380 ms
```

### カバリングインデックスを効きに活かせる

```sql
-- 既存のインデックスの削除
DROP INDEX IF EXISTS tuning.idx_user_address_covering;
DROP INDEX IF EXISTS tuning.idx_reservation_checkin;

-- すべての項目を保持したインデックスの作成
DROP INDEX IF EXISTS tuning.idx_user_address_full_covering;
CREATE INDEX idx_user_address_full_covering 
ON tuning.user(address text_pattern_ops) 
INCLUDE (user_id, user_name);

DROP INDEX IF EXISTS tuning.idx_reservation_full_covering;
CREATE INDEX idx_reservation_full_covering
ON tuning.reservation(chekin_date)
INCLUDE (user_id, num_people);

-- 結果確認
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    u.user_name
    , r.chekin_date
    , r.num_people
FROM 
    tuning.reservation r
JOIN 
    tuning."user" u ON r.user_id = u.user_id
WHERE 
    u.address LIKE '東京都%' 
    AND r.chekin_date BETWEEN '2026-01-01' AND '2026-01-31';

-- 最新情報に更新
VACUUM ANALYZE tuning.user;
VACUUM ANALYZE tuning.reservation;
```

```txt
# VACCUM実行前
Hash Join  (cost=2803.11..5571.73 rows=35978 width=18) (actual time=14.309..29.870 rows=37734 loops=1)
  Hash Cond: (r.user_id = u.user_id)
  Buffers: shared hit=1227
  ->  Index Only Scan using idx_reservation_full_covering on reservation r  (cost=0.42..2578.23 rows=72690 width=12) (actual time=0.019..5.518 rows=75462 loops=1)
        Index Cond: ((chekin_date >= '2026-01-01'::date) AND (chekin_date <= '2026-01-31'::date))
        Heap Fetches: 0
        Buffers: shared hit=293
  ->  Hash  (cost=2184.00..2184.00 rows=49495 width=14) (actual time=14.238..14.240 rows=50000 loops=1)
        Buckets: 65536  Batches: 1  Memory Usage: 2856kB
        Buffers: shared hit=934
        ->  Seq Scan on "user" u  (cost=0.00..2184.00 rows=49495 width=14) (actual time=0.046..7.535 rows=50000 loops=1)
              Filter: ((address)::text ~~ '東京都%'::text)
              Rows Removed by Filter: 50000
              Buffers: shared hit=934
Planning:
  Buffers: shared hit=10
Planning Time: 0.332 ms
Execution Time: 30.741 ms

# VACCUM実行後
Hash Join  (cost=2815.74..5628.87 rows=37348 width=18) (actual time=14.747..29.086 rows=37734 loops=1)
  Hash Cond: (r.user_id = u.user_id)
  Buffers: shared hit=1227
  ->  Index Only Scan using idx_reservation_full_covering on reservation r  (cost=0.42..2619.43 rows=73950 width=12) (actual time=0.010..5.227 rows=75462 loops=1)
        Index Cond: ((chekin_date >= '2026-01-01'::date) AND (chekin_date <= '2026-01-31'::date))
        Heap Fetches: 0
        Buffers: shared hit=293
  ->  Hash  (cost=2184.00..2184.00 rows=50505 width=14) (actual time=14.711..14.713 rows=50000 loops=1)
        Buckets: 65536  Batches: 1  Memory Usage: 2856kB
        Buffers: shared hit=934
        ->  Seq Scan on "user" u  (cost=0.00..2184.00 rows=50505 width=14) (actual time=0.006..8.086 rows=50000 loops=1)
              Filter: ((address)::text ~~ '東京都%'::text)
              Rows Removed by Filter: 50000
              Buffers: shared hit=934
Planning:
  Buffers: shared hit=30
Planning Time: 0.199 ms
Execution Time: 29.930 ms
```

## INDEXの負の効果（Update）

- 結果の比較
  - インデックスなし
    - 更新時間: 55.484 ms
  - インデックスあり
    - 更新時間: 56.013 ms
    - HOT(Heap Only Tuples, インデックスを更新せずに新しいレコードを追内jデータブロック内に配置することで、I/O負荷を軽減する)更新が働いたため。
  - カバリングインデックスあり
    - 更新時間: 88.118 ms
    - インデックスのキーである `address` 自体も書き換えているため、インデックス側も物理的にページを書き換える作業が発生し、HOT更新が働いていないため。
- HOT更新の成功率（n_tup_hot_upd）
  - インデックス無し/addressのみ時
    - HOT更新が可能な余地あり
  - カバリングインデックス
    - HOT更新が1件も成功していない。
    - 「テーブル本体」に加えて、「インデックス本体」も書き換える必要がある。

```sql
work_db=# \timing
Timing is on.

-- インデックスなし
work_db=# update tuning.user set address = '東京都新宿区' where user_id between 1 and 10000;
UPDATE 10000
Time: 55.484 ms
work_db=# SELECT n_tup_upd, n_tup_hot_upd
FROM pg_stat_user_tables
WHERE relname = 'user';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
     20000 |            50
(1 row)

Time: 1.041 ms

-- address絞り込みようのインデックスあり
work_db=# update tuning.user set address = '東京都新宿区' where user_id between 1 and 10000;
UPDATE 10000
Time: 56.013 ms
work_db=# SELECT n_tup_upd, n_tup_hot_upd
FROM pg_stat_user_tables
WHERE relname = 'user';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
     30000 |           103
(1 row)

Time: 1.002 ms

-- カバリングインデックス
work_db=# update tuning.user set address = '東京都新宿区' where user_id between 1 and 10000;
UPDATE 10000
Time: 88.118 ms
work_db=# SELECT n_tup_upd, n_tup_hot_upd
FROM pg_stat_user_tables
WHERE relname = 'user';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
     10000 |             0
(1 row)

Time: 27.566 ms
```

---

## まとめ（検索 vs 更新）

- 結果の比較
  - 検索のメリット: 73ms → 30ms （約40msの短縮）
  - 更新のデメリット: 55ms → 88ms （約33msの増加）
- 判断の基準
  - 参照が多い場合: 一回の検索で40ms得をする、更新では33ms損する。 → カバリングインデックスを採用。
  - 更新が多い場合: ユーザーの情報を更新し続ける場合は、シンプルなインデックスを採用。

---

## クラウドデータウエアハウスとの違い

- 一般的な特徴

|特徴|PostgreSQL (OLTP)|Snowflake (DWH)|
|--|--|--|
|データの持ち方|行（Row）ごと。横に並べる。|列（Column）ごと。縦に並べる。|
|高速化の主役|インデックス|マイクロパーティション / プルーニング|
|更新の重さ|行を1件書き換えるのは軽い。|データを1件書き換えても、背後の大きなファイルを書き直すため重い。|

- チューニング

|概念|PostgreSQLでの呼び名|Snowflakeでの呼び名|
|--|--|--|
|データの読み込み|Seq Scan / Index Scan|Table Scan|
|結合|Hash Join / Nested Loop|Join (主にHash Join)|
|絞り込み|Filter|Filter|
|並び替え|Sort|Sort|
|集計|Aggregate / HashAggregate|Aggregate|

- PostgreSQL: インデックスによる「点」の探索
  - インデックスを参照して、必要な行の場所の特定。
  - NGパターン: インデックスが利用されない。
- Snowflake: プルーニングによる「面」の削減
  - データを「マイクロパーティション」という小さなファイル群に分けて保存する。
  - 各ファイルが持つ「最小値・最大値」のメタデータを見て、不要なファイルを読み飛ばす。
  - 見るべき点: クエリプロファイルの `Partitions scanned` と `Partitions total`
  - NGパターン: 全ファイル（1000/1000）をスキャン。

**Snowflake特有の指標**

- Remote Disk I/O (Spilling)
  - メモリ上での処理が足りない場合、クラウドストレージにデータを書き出す。
  - `Spilling to local/remote storage` が発生していると、劇的に遅くなる。
- Metadata Based Results
  - メタデータ（テーブルの総件数）などはテーブル自体を参照せずに結果を返す。
- Network Transfer
  - サーバー間でのデータのやり取りが発生
  - 大量のデータをジョインする際にデータがネットワークを飛び交う `Data shuffle` が発生しているかを確認する。

**チェックポイント**

- Table Scan: `Partitons scanned` が `Partitions total` より小さいか（プルーニングが効いているか）？
- 結合のビルド側: 「重いテーブル」と「軽いテーブル」の扱い方
- ディスク漏れ（Spilling）: メモリ不足がないか
