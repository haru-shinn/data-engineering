---------------------------------------------------------------
-- SQL演習
-- ミック(2026).『ミックの楽しいSQLパズル』.株式会社インプレス.

-- 演習目的 : SQLの技術向上（複数の解き方を学ぶことで効率の良い書き方を身につける）

-- （注意）
-- 書籍の問題や回答および提供クエリを参照しているが、
-- 単に問題を解くだけでなく検証も行うため、テーブル名などが提供クエリと違う場合がある。
---------------------------------------------------------------


---------------------------------------------------------------
-- 第１章　宣言的言語としてのSQL
---------------------------------------------------------------

/* 主キーとランダムな値 */

-- シーケンス
drop sequence fruits_seq;
create sequence fruits_seq start 1;
drop table if exists fruits;
create table fruits (id integer, name varchar(8));
insert into fruits values (nextval('fruits_seq'), 'abc');
insert into fruits values (nextval('fruits_seq'), 'apple');
insert into fruits values (nextval('fruits_seq'), 'banana');
select * from fruits;

-- UUID
drop table if exists test_tbl;
create table test_tbl (id varchar(255), uuid_name varchar(255));
insert into test_tbl select (i, gen_random_uuid()), gen_random_uuid() from generate_series(1, 10) as s(i);
select * from test_tbl;
delete from test_tbl;


/* 外部キーの設定 */

-- 外部キー
drop table if exists departments;
create table departments (department_name varchar(16) primary key);
insert into departments values ('sales'), ('pr');

drop table if exists personnel cascade;
create table personnel (name varchar(64), department_name varchar(32) references departments(department_name));
insert into personnel values (gen_random_uuid(), 'sales');
insert into personnel values (gen_random_uuid(), 'abc'); -- 失敗する

select * from departments;
select * from personnel;


/* 自己参照整合性制約 */

drop table if exists personnel cascade;
create table personnel (name varchar(64) primary key, boss varchar(64) references personnel(name));
insert into personnel values ('boss_xyz', null);
insert into personnel values ('uuid_abc', 'boss_xyz');
insert into personnel values ('uuid_oie', 'boss_xyz');
insert into personnel values ('uuid_wee', 'boss_poi'); -- 失敗する

select * from personnel;


/* 検査制約 */

-- アルファベットを含むかの確認
drop table if exists sometbl;
create table sometbl (some_alpha char(6) check (upper(some_alpha) <> lower(some_alpha)));
insert into sometbl values ('123456'); -- 失敗する
insert into sometbl values ('abcdef');
insert into sometbl values ('aaa');
insert into sometbl values ('123abc');
insert into sometbl values (''); -- 失敗する
insert into sometbl values (null);
select *, length(some_alpha) from sometbl;

-- アルファベットを含まないかの確認
drop table if exists sometbl;
create table sometbl (some_alpha char(6) check (upper(some_alpha) = lower(some_alpha)));
insert into sometbl values ('123456');
insert into sometbl values ('abcdef'); -- 失敗する
insert into sometbl values ('123abc'); -- 失敗する
insert into sometbl values ('');
insert into sometbl values (null);
select *, length(some_alpha) from sometbl;

-- すべてアルファベットかの確認
drop table if exists sometbl;
create table sometbl (some_alpha char(6) check (some_alpha ~ '^[a-z|A-Z]+$'));
insert into sometbl values ('123456'); -- 失敗する
insert into sometbl values ('abcdef');
insert into sometbl values ('123abc'); -- 失敗する
insert into sometbl values ('ABCdef');
insert into sometbl values (''); -- 失敗する
insert into sometbl values (null);
select *, length(some_alpha) from sometbl;


/* 条件法 */

-- 20歳未満は登録不可
drop table if exists smokers;
create table smokers (
  name char(16) not null,
  age integer not null,
  smoker char(1) not null,
  check ((age >= 20) or (age < 20 AND  smoker = 'N'))
);
insert into smokers values ('hilbelt', 20, 'Y');
insert into smokers values ('dede', 35, 'Y');
insert into smokers values ('cab', 16, 'Y'); -- 失敗する
insert into smokers values ('bear', 19, 'N'); 
insert into smokers values ('twel', 20, 'Y');
insert into smokers values ('cosy', 30, 'N');

drop table if exists smokers;
create table smokers (
  name char(16) not null,
  age integer not null,
  smoker char(1) not null,
  check (
    (case when age < 20 then case when smoker = 'Y' then 1 else 0 end else 0 end) = 0
    )
);


-- 文字列操作
drop table if exists prefectures;
create table prefectures (pref_name varchar(48) not null);
insert into prefectures values ('01:北海道');
insert into prefectures values ('02:青森県');

select pref_name, substring(pref_name, strpos(pref_name, ':') + 1) from prefectures;
select pref_name, right(pref_name, length(pref_name) - position(':' in pref_name)) from prefectures;
---------------------------------------------------------------
-- 第２章　SQLの論理
---------------------------------------------------------------

/* 全称量化 */
drop table if exists projects;
create table projects (
  project_id char(5) not null,
  work_nbr integer not null,
  work_status char(1) not null
);
insert into projects values ('P001', 0, 'C');
insert into projects values ('P001', 1, 'W');
insert into projects values ('P001', 2, 'W');
insert into projects values ('P002', 0, 'W');
insert into projects values ('P002', 1, 'W');
insert into projects values ('P002', 2, 'W');
insert into projects values ('P003', 1, 'C');
insert into projects values ('P003', 2, 'C');
insert into projects values ('P004', 0, 'C');
insert into projects values ('P004', 1, 'W');
insert into projects values ('P005', 0, 'C');
insert into projects values ('P005', 1, 'C');
insert into projects values ('P005', 2, 'W');

-- HAVING句
/* 補足
  ハッシュテーブルを作成し集約を行う（フルスキャンの過程で集計を行うため、I/O負荷が最小限）
  ソート処理なしのためメモリ効率よい
*/
select project_id from projects
group by project_id
having
  -- min(work_status) <> max(work_status)
  -- and sum(case when work_status = 'C' then 1 else 0 end) = 1
  sum(case 
    when work_nbr = 0 and work_status = 'C' then 1
    when work_nbr <> 0 and work_status = 'W' then 1
    else 0
  end) = count(*)
;

-- Window関数
/* 補足
  メモリ内ソートから溢れ、ディスクを使用した非常に遅い処理に転落するリスクあり
  全行を保持したまま計算するため、中間データの肥大化（Group Byだと集約されるのでレコードが少なくなる）
*/
with tmp as (
  select 
    *
    , sum(case 
            when work_nbr = 0 and work_status = 'C' then 1
            when work_nbr <> 0 and work_status = 'W' then 1
            else 0
          end) over(partition by project_id) as nbr
    , count(*) over(partition by project_id) as cnt
  from projects
)
select distinct project_id from tmp where nbr = cnt
;

-- all演算子
/* 補足
  SubPlan が Seq Scan on projects p1 の各行に対して実行される形
  「N+1問題」 をデータベース内部で引き起こしている
*/
select project_id
from projects as p1
where 
  work_nbr = 0
  and work_status = 'C'
  and 'W' = all (select work_status from projects as p2
                  where work_nbr <> 0
                  and p1.project_id = p2.project_id)
;

-- お試し データ量増加
-- テーブルの初期化
TRUNCATE TABLE projects;

-- 1万プロジェクト分（各3行、計3万行）生成
-- explain analyze select ... を実行する
INSERT INTO projects (project_id, work_nbr, work_status)
SELECT 
    LPAD(p_id::text, 5, '0'), -- '00001', '00002'...
    w_nbr,
    CASE 
        WHEN w_nbr = 0 THEN 'C'
        ELSE 'W' 
    END
FROM generate_series(1, 10000) AS p_id
CROSS JOIN (SELECT 0 AS w_nbr UNION ALL SELECT 1 UNION ALL SELECT 2) AS w;

CREATE INDEX idx_id ON projects(project_id);


/*
-- GROUP BY
HashAggregate  (cost=988.00..1113.00 rows=50 width=6) (actual time=8.368..9.679 rows=10000 loops=1)
  Group Key: project_id
  Filter: (sum(CASE WHEN ((work_nbr = 0) AND (work_status = 'C'::bpchar)) THEN 1 WHEN ((work_nbr <> 0) AND (work_status = 'W'::bpchar)) THEN 1 ELSE 0 END) = count(*))
  Batches: 1  Memory Usage: 1425kB
  ->  Seq Scan on projects  (cost=0.00..463.00 rows=30000 width=12) (actual time=0.004..1.508 rows=30000 loops=1)
Planning Time: 0.131 ms
Execution Time: 10.121 ms

-- WINDOW関数
Unique  (cost=2693.90..3969.28 rows=149 width=6) (actual time=3.836..18.705 rows=10000 loops=1)
  ->  Subquery Scan on tmp  (cost=2693.90..3968.90 rows=150 width=6) (actual time=3.834..16.782 rows=30000 loops=1)
        Filter: (tmp.nbr = tmp.cnt)
        ->  WindowAgg  (cost=2693.90..3593.90 rows=30000 width=34) (actual time=3.832..15.011 rows=30000 loops=1)
              ->  Sort  (cost=2693.90..2768.90 rows=30000 width=12) (actual time=3.777..4.823 rows=30000 loops=1)
                    Sort Key: projects.project_id
                    Sort Method: quicksort  Memory: 1940kB
                    ->  Seq Scan on projects  (cost=0.00..463.00 rows=30000 width=12) (actual time=0.003..1.198 rows=30000 loops=1)
Planning Time: 0.151 ms
Execution Time: 19.029 ms

-- ALL演算子（インデックスなし）
Seq Scan on projects p1  (cost=0.00..9195763.00 rows=1667 width=6) (actual time=189.820..8842.411 rows=10000 loops=1)
  Filter: ((work_nbr = 0) AND (work_status = 'C'::bpchar) AND (SubPlan 1))
  Rows Removed by Filter: 20000
  SubPlan 1
    ->  Seq Scan on projects p2  (cost=0.00..613.00 rows=2 width=2) (actual time=0.438..0.864 rows=2 loops=10000)
          Filter: ((work_nbr <> 0) AND (p1.project_id = project_id))
          Rows Removed by Filter: 29998
Planning Time: 0.129 ms
JIT:
  Functions: 11
  Options: Inlining true, Optimization true, Expressions true, Deforming true
  Timing: Generation 1.002 ms, Inlining 99.099 ms, Optimization 48.840 ms, Emission 40.928 ms, Total 189.869 ms
Execution Time: 9048.781 ms

-- ALL演算子（インデックスあり）
Seq Scan on projects p1  (cost=0.00..130288.00 rows=1667 width=6) (actual time=19.341..36.296 rows=10000 loops=1)
  Filter: ((work_nbr = 0) AND (work_status = 'C'::bpchar) AND (SubPlan 1))
  Rows Removed by Filter: 20000
  SubPlan 1
    ->  Index Scan using idx_id on projects p2  (cost=0.29..8.35 rows=2 width=2) (actual time=0.001..0.001 rows=2 loops=10000)
          Index Cond: (project_id = p1.project_id)
          Filter: (work_nbr <> 0)
          Rows Removed by Filter: 1
Planning Time: 0.268 ms
JIT:
  Functions: 14
  Options: Inlining false, Optimization false, Expressions true, Deforming true
  Timing: Generation 0.692 ms, Inlining 0.000 ms, Optimization 0.316 ms, Emission 18.972 ms, Total 19.979 ms
Execution Time: 37.380 ms

*/

/* 再帰と構成 */

select i from generate_series(1, 5) as t(i);

-- 再帰共通表式
with recursive number_generate(num) as (
  select 1 as num
  union all
  select num + 1 as num
  from number_generate
  where num < 10
)
select * from number_generate;

-- クロス結合
create table digits (digit integer);
insert into digits values (0);
insert into digits values (1);
insert into digits values (2);
insert into digits values (3);
insert into digits values (4);
insert into digits values (5);
insert into digits values (6);
insert into digits values (7);
insert into digits values (8);
insert into digits values (9);

select d1.digit + (d2.digit * 10) as seq
from digits as d1 cross join digits as d2
order by seq;


/* 連番をふる */
drop table if exists alphabet;
create table alphabet (letter char(1));
insert into alphabet values ('a');
insert into alphabet values ('b');
insert into alphabet values ('c');
insert into alphabet values ('d');
insert into alphabet values ('e');
select row_number() over(order by letter) from alphabet;


/* CASE式(ピボット) */

drop table if exists customer_count;
create table customer_count (
  record_date date
  , dow char(3)
  , customers integer
);
insert into customer_count (record_date, dow, customers) values ('2024/11/12', 'Mon', 212);
insert into customer_count (record_date, dow, customers) values ('2024-11-13', 'Tue', 540);
insert into customer_count (record_date, dow, customers) values ('2024-11-14', 'Wed', 145);
insert into customer_count (record_date, dow, customers) values ('2024-11-15', 'Thr', 321);
insert into customer_count (record_date, dow, customers) values ('2024-11-16', 'Fri', 670);
insert into customer_count (record_date, dow, customers) values ('2024-11-17', 'Sat', 518);
insert into customer_count (record_date, dow, customers) values ('2024-11-18', 'Sun', 420);
insert into customer_count (record_date, dow, customers) values ('2024-11-19', 'Mon', 376);
insert into customer_count (record_date, dow, customers) values ('2024-11-20', 'Tue', 222);
insert into customer_count (record_date, dow, customers) values ('2024-11-21', 'Wed', 518);
insert into customer_count (record_date, dow, customers) values ('2024-11-22', 'Thr', 842);
insert into customer_count (record_date, dow, customers) values ('2024-11-23', 'Fri', 632);
insert into customer_count (record_date, dow, customers) values ('2024-11-24', 'Sat', 190);
insert into customer_count (record_date, dow, customers) values ('2024-11-25', 'Sun', 341);

select
  sum(case when dow = 'Mon' then customers else 0 end) as mon
  , sum(case when dow = 'Tue' then customers else 0 end) as tue
  , sum(case when dow = 'Wed' then customers else 0 end) as wed
  , sum(case when dow = 'Thr' then customers else 0 end) as thr
  , sum(case when dow = 'Fri' then customers else 0 end) as fri
  , sum(case when dow = 'Sat' then customers else 0 end) as sat
  , sum(case when dow = 'Sun' then customers else 0 end) as sun
from
  customer_count
;

create table service_schedule (
  order_nbr char(10) not null
  , sch_seq integer not null check(sch_seq in (1, 2, 3))
  , sch_date date
);

insert into service_schedule values('4155526710', 1, '2025-07-16' );
insert into service_schedule values('4155526710', 2, '2025-07-30' ); 
insert into service_schedule values('4155526710', 3, '2025-10-01' );
insert into service_schedule values('4155526711', 1, '2025-07-16' ); 
insert into service_schedule values('4155526711', 2, '2025-07-30' ); 
insert into service_schedule values('4155526711', 3, NULL); 

select
  order_nbr
  , max(case when sch_seq = 1 then sch_date end) as processed
  , max(case when sch_seq = 2 then sch_date end) as completed
  , max(case when sch_seq = 3 then sch_date end) as confirmed
from
  service_schedule
group by
  order_nbr
;

/* 3値論理とNULL */

create table class_a (name varchar(32), birthday date);
create table class_b (name varchar(32), birthday date);

insert into class_a values ('aihara', '2011-11-13');
insert into class_a values ('ashida', '2012-10-24');
insert into class_a values ('henmi', '2010-04-11');
insert into class_a values ('koga', '2012-06-22');
insert into class_a values ('miura', '2011-09-30');

insert into class_b values ('kelly', '2011-11-13');
insert into class_b values ('mark', '2010-07-05');
insert into class_b values ('john', '2012-06-18');
insert into class_b values ('robert', null);
insert into class_b values ('elizabes', '2011-09-30');

select * from class_a
union
select * from class_b
;

select * from class_a as a where exists (select 1 from class_b as b where a.birthday = b.birthday);
select * from class_a where birthday in (select birthday from class_b);

select * from class_a as a where not exists (select 1 from class_b as b where a.birthday = b.birthday);
select * from class_a where birthday not in (select birthday from class_b);

/* 更新による分岐 */

drop table if exists badges;
create table badges (badge_nbr char(1), emp_id char(1), issued_date date, badge_status char(1));
insert into badges values ('1', '1', '2024/11/14', 'A');
insert into badges values ('2', '1', '2024/10/14', 'I');
insert into badges values ('3', '1', '2024/09/14', 'A');
insert into badges values ('4', '2', '2024/12/07', 'A');
insert into badges values ('5', '2', '2024/12/08', 'I');
insert into badges values ('6', '2', '2024/05/20', 'I');
insert into badges values ('7', '3', '2024/04/07', 'I');
insert into badges values ('8', '3', '2024/05/19', 'I');
insert into badges values ('9', '3', '2024/06/01', 'I');

select * from badges where emp_id in (
  select emp_id
  from badges 
  where badge_status = 'A' 
  group by emp_id having count(*) > 1
)
and badge_status = 'A'
;
update badges 
set badge_status = 
  case when issued_date = 
          (select max(issued_date) 
            from badges b1 
            where badges.emp_id = b1.emp_id) 
          then 'A' else 'I' end;
select * from badges order by emp_id, issued_date;


/* レコードの順序 */

create table receipts (
  customer_id char(4)
  , seq integer
  , price integer
);

insert into receipts values ('A', 1, 500);
insert into receipts values ('A', 2, 1000);
insert into receipts values ('A', 3, 700);
insert into receipts values ('B', 5, 100);
insert into receipts values ('B', 6, 5000);
insert into receipts values ('B', 7, 300);
insert into receipts values ('B', 9, 200);
insert into receipts values ('B', 12, 1000);
insert into receipts values ('C', 10, 600);
insert into receipts values ('C', 20, 100);
insert into receipts values ('C', 45, 200);
insert into receipts values ('C', 70, 60);
insert into receipts values ('D', 3, 2000);


select *
from (
  select
    *
    , row_number() over(partition by customer_id order by seq) as rn
  from receipts
)
where rn = 1;

select *
from (
  select
    *
    , nth_value(seq, 3) over(partition by customer_id order by seq) as nv
  from receipts
)
where seq = nv
;
/* 補足
実行計画 の比較
特徴,row_number(),nth_value()
効率,高い（途中で計算を止められる）,低い（全行スキャンが必要）
実行計画,Run Condition による最適化あり,フィルタリングまで全行保持
用途,特定順位のレコードを抽出するとき,集計・分析で行を消さずに値を参照するとき

row_number
Subquery Scan on unnamed_subquery  (cost=100.64..147.76 rows=7 width=36) (actual time=0.025..0.030 rows=4 loops=1)
  Filter: (unnamed_subquery.rn = 1)
  ->  WindowAgg  (cost=100.64..129.64 rows=1450 width=36) (actual time=0.024..0.028 rows=4 loops=1)
        Run Condition: (row_number() OVER (?) <= 1)
        ->  Sort  (cost=100.64..104.26 rows=1450 width=28) (actual time=0.017..0.018 rows=13 loops=1)
              Sort Key: receipts.customer_id, receipts.seq
              Sort Method: quicksort  Memory: 25kB
              ->  Seq Scan on receipts  (cost=0.00..24.50 rows=1450 width=28) (actual time=0.007..0.008 rows=13 loops=1)
Planning Time: 0.088 ms
Execution Time: 0.059 ms

nth_value
Subquery Scan on unnamed_subquery  (cost=100.64..147.76 rows=7 width=32) (actual time=0.042..0.058 rows=3 loops=1)
  Filter: (unnamed_subquery.seq = unnamed_subquery.nv)
  Rows Removed by Filter: 10
  ->  WindowAgg  (cost=100.64..129.64 rows=1450 width=32) (actual time=0.039..0.056 rows=13 loops=1)
        ->  Sort  (cost=100.64..104.26 rows=1450 width=28) (actual time=0.021..0.022 rows=13 loops=1)
              Sort Key: receipts.customer_id, receipts.seq
              Sort Method: quicksort  Memory: 25kB
              ->  Seq Scan on receipts  (cost=0.00..24.50 rows=1450 width=28) (actual time=0.011..0.012 rows=13 loops=1)
Planning Time: 0.078 ms
Execution Time: 0.079 ms
*/


/* 列方向の最小最大 */

create table variables (
  key_col char(1)
  , x integer
  , y integer
  , z integer
);

insert into variables values ('A', 1, 2, 3);
insert into variables values ('B', 30, 20, 10);
insert into variables values ('C', NULL, 15, 30);
insert into variables values ('D', 10, NULL, 45);
insert into variables values ('E', NULL, NULL, 50);
insert into variables values ('F', NULL, NULL, NULL);
insert into variables values ('G', NULL, 100, NULL);

select key_col, greatest(x, y) as result from variables;
select key_col, greatest(coalesce(x, y), coalesce(y, x)) as result from variables;


---------------------------------------------------------------
-- 第３章　SQLの高度な応用
---------------------------------------------------------------

/* 再帰とポインタチェイン */
create table postalhistory (
  name char(1)
  , pcode char(7)
  , new_pcode char(7)
);
insert into postalhistory values ('A', '4130001', '4130002');
insert into postalhistory values ('A', '4130002', '4130003');
insert into postalhistory values ('A', '4130003', null);
insert into postalhistory values ('B', '4130041', null);
insert into postalhistory values ('C', '4103213', '4380824');
insert into postalhistory values ('C', '4380824', null);


with recursive tmp(name, pcode, new_pcode, rn) as (
  select name, pcode, new_pcode, 1 as rn
  from postalhistory
  where new_pcode is null
  union all
  select p.name, p.pcode, p.new_pcode, t.rn + 1
  from postalhistory as p
    inner join tmp as t on p.new_pcode = t.pcode
), tmp2 as (
  select 
    name
    , pcode
    , min(pcode) over(partition by name) as min_pcode
    , max(pcode) over(partition by name) as max_pcode
  from tmp
)
select distinct name, min_pcode, max_pcode from tmp2;


/* 組み合わせの作成 */

create table date_ranges (
  start_date date
  , end_date date
);

insert into date_ranges values ('2026-01-01', '2026-01-03');
insert into date_ranges values ('2026-01-02', '2026-01-04');
insert into date_ranges values ('2026-01-04', '2026-01-05');
insert into date_ranges values ('2026-01-06', '2026-01-09');

select
  d1.start_date
  , d2.end_date
from
  date_ranges as d1
    inner join date_ranges as d2
    on d1.start_date < d2.end_date
order by
  d1.start_date
  , d2.end_date
;


/* 重なる機関の結合 (特性関数) */

create table timesheets (
  job_id char(4)
  , start_date date
  , end_date date
);

insert into timesheets values ('J1', '2026-01-01', '2026-01-03');
insert into timesheets values ('J2', '2026-01-02', '2026-01-04');
insert into timesheets values ('J3', '2026-01-04', '2026-01-05');
insert into timesheets values ('J4', '2026-01-06', '2026-01-09');
insert into timesheets values ('J5', '2026-01-09', '2026-01-09');
insert into timesheets values ('J6', '2026-01-09', '2026-01-09');
insert into timesheets values ('J7', '2026-01-12', '2026-01-15');
insert into timesheets values ('J8', '2026-01-13', '2026-01-14');
insert into timesheets values ('J9', '2026-01-14', '2026-01-14');
insert into timesheets values ('J10', '2026-01-17', '2026-01-17');

select
  start_date
  , min(end_date) as min_date
from (
  select
    t1.start_date as start_date
    , t2.end_date as end_date
  from
    timesheets as t1, timesheets as t2, timesheets as t3
  where
    t1.start_date <= t2.start_date
  group by
    t1.start_date, t2.end_date
  having
    count(case when (t1.start_date > t3.start_date and t1.start_date <= t3.end_date) 
                  or (t2.end_date >= t3.start_date and t2.end_date < t3.end_date) 
                then 1 end) = 0
    ) as tmp
group by
  start_date
;


/* 境界値 */
drop table if exists reservations;
create table reservations (
  user_id char(4)
  , start_date date
  , end_date date
);

insert into reservations values ('R1', '2026-01-01', '2026-01-03');
insert into reservations values ('R3', '2026-01-04', '2026-01-05');
insert into reservations values ('R4', '2026-01-06', '2026-01-09');
insert into reservations values ('R7', '2026-01-12', '2026-01-12');

select * from reservations
where ('2026-01-01', '2026-01-12') overlaps(start_date, end_date);

select * from reservations
where ('2026-01-07' between start_date and end_date)
  or ('2026-01-08' between start_date and end_date)
  or ('2026-01-07' <= start_date and '2026-01-08' >= end_date)
;

/* 差集合 */

create table icecream (
  sale_date date
  , flavor char(32)
  , sale_amt integer
);
insert into icecream values ('2026-01-01', 'candy', 12000);
insert into icecream values ('2026-01-01', 'teaole', 8000);
insert into icecream values ('2026-01-01', 'match', 32000);
insert into icecream values ('2026-01-01', 'ramlezn', 45000);
insert into icecream values ('2026-01-01', 'mint', 17000);
insert into icecream values ('2026-01-02', 'teaole', 20000);
insert into icecream values ('2026-01-02', 'mellon', 3000);
insert into icecream values ('2026-01-02', 'matcha', 8000);
insert into icecream values ('2026-01-02', 'mint', 29000);
insert into icecream values ('2026-01-02', 'orange', 45000);
insert into icecream values ('2026-01-03', 'matcha', 21000);
insert into icecream values ('2026-01-03', 'candy', 9000);
insert into icecream values ('2026-01-03', 'ramlezn', 8900);
insert into icecream values ('2026-01-04', 'mint', 7600);
insert into icecream values ('2026-01-04', 'orange', 7600);
insert into icecream values ('2026-01-04', 'ramlezn', 50000);

select i1.sale_date, i2.flavor
from icecream as i1 cross join icecream as i2
except
select sale_date, flavor from icecream
order by sale_date; 

select i1.sale_date, i2.flavor
from icecream as i1 cross join icecream as i2
where not exists (
  select sale_date, flavor
  from icecream as i3
  where i3.sale_date = i1.sale_date
    and i3.flavor = i2.flavor
)
order by sale_date; 

/* テーブルの比較 */
drop table if exists tbl_1;
drop table if exists tbl_2;

create table tbl_1 (
  keycol char(1)
  , c1 integer
  , c2 integer
  , c3 integer
);
create table tbl_2 (
  keycol char(1)
  , c1 integer
  , c2 integer
  , c3 integer
);
insert into tbl_1 values ('A', 1 ,2, 3);
insert into tbl_1 values ('B', 4, 5, 6);
insert into tbl_1 values ('C', 7, 8, 9);
insert into tbl_2 values ('A', 1, 2, 3);
insert into tbl_2 values ('B', 4, 5, 6);
insert into tbl_2 values ('C', 7, 8, 0);

select * from tbl_1
union
select * from tbl_2
;

select keycol, count(*)
from (select * from tbl_1
      union
      select * from tbl_2)
group by keycol
having count(*) >= 2;

select * from tbl_1
intersect
select * from tbl_2
;


/* 完全外部結合 */
drop table if exists class_a;
create table class_a (
  id char(1)
  , name varchar(16)
);

drop table if exists class_b;
create table class_b (
  id char(1)
  , name varchar(16)
);

insert into class_a values (1, '田中');
insert into class_a values (2, '鈴木');
insert into class_a values (3, '伊集院');
insert into class_b values (1, '田中');
insert into class_b values (2, '鈴木');
insert into class_b values (4, '西園寺');

select 
  coalesce(a.id, b.id) as id
  , coalesce(a.name, b.name) as name
from
  class_a as a full outer join class_b as b
  on a.id = b.id
;

select
  coalesce(a.id, b.id) as id
  , coalesce(a.name, b.name) as name
from
  class_a as a full outer join class_b as b
  on a.id = b.id
where
  a.name is null
  or b.name is null
;

/* 再帰共通表式（最短経路） */

drop table if exists routes;
create table routes (
  source_city varchar(32)
  , destination_city varchar(32)
  , distance integer not null
);
insert into routes values ('chicago', 'boston', 985);
insert into routes values ('boston', 'chicago', 985);
insert into routes values ('boston', 'new york', 215);
insert into routes values ('new york', 'boston', 215);
insert into routes values ('new york', 'philadelphia', 95);
insert into routes values ('philadelphia', 'new york', 95);
insert into routes values ('philadelphia', 'washington', 140);
insert into routes values ('new york', 'philadelphia', 140);
insert into routes values ('washington', 'atlanta', 640);
insert into routes values ('atlanta', 'washington', 640);
insert into routes values ('atlanta', 'miami', 660);
insert into routes values ('miami', 'atlanta', 660);

with recursive shortestpaths as (
  select 
    'New York' as source_city
    , destination_city
    , distance
    , array['New York', destination_city] as path
  from routes
  where source_city = 'new york'
  union all
  select
    sp.source_city
    , r.destination_city
    , sp.distance + r.distance
    , sp.path || r.destination_city
  from
    shortestpaths sp inner join routes r
    on sp.destination_city = r.source_city
  where
    r.destination_city <> all(sp.path) 
),
bestpaths as (
  select
    source_city
    , destination_city
    , min(distance) as min_distance
  from
    shortestpaths
  group by
    source_city, destination_city
)
select
  destination_city
  , min_distance
from
  bestpaths
where
  destination_city <> 'new york'
order by
  min_distance;

/* intersect */

create table relation (
  followee integer
  , follower integer
);

insert into relation values (1, 2);
insert into relation values (1, 3);
insert into relation values (1, 4);
insert into relation values (2, 1);
insert into relation values (2, 3);
insert into relation values (2, 6);
insert into relation values (3, 1);
insert into relation values (4, 2);
insert into relation values (4, 5);
insert into relation values (5, 2);
insert into relation values (5, 3);

select followee, follower from relation
intersect
select follower, followee from relation
;

---------------------------------------------------------------
-- 第４章　SQLで数学パズルを解く
---------------------------------------------------------------
drop table if exists items;
CREATE TABLE Items
(i INTEGER NOT NULL PRIMARY KEY);

INSERT INTO Items VALUES (1);
INSERT INTO Items VALUES (2);
INSERT INTO Items VALUES (3);
INSERT INTO Items VALUES (4);
INSERT INTO Items VALUES (5);

select i1.i, i2.i
from items as i1 inner join items as i2
on i1.i <> i2.i
order by i1.i, i2.i
;

select i1.i, i2.i, i3.i
from items as i1
  inner join items as i2 on i1.i <> i2.i
  inner join items as i3 on (i2.i <> i3.i and i3.i <> i1.i)
order by i1.i, i2.i, i3.i
;

select i1.i, i2.i, i3.i, i4.i
from items as i1, items as i2, items as i3, items as i4
where i2.i not in (i1.i)
  and i3.i not in (i1.i, i2.i)
  and i4.i not in (i1.i, i2.i, i3.i)
;


/* 組み合わせ */

select 
  i1.i, i2.i
from
  items as i1 inner join items as i2
  on i1.i <> i2.i
where
  i1.i < i2.i
;

select
  i1.i, i2.i, i3.i
from
  items as i1 
  inner join items as i2 on i1.i <> i2.i
  inner join items as i3 on i2.i < i3.i
where
  i1.i < i2.i
;


/* 完全数 */

drop table if exists digits;
CREATE TABLE Digits
 (digit INTEGER PRIMARY KEY); 

INSERT INTO Digits VALUES (0);
INSERT INTO Digits VALUES (1);
INSERT INTO Digits VALUES (2);
INSERT INTO Digits VALUES (3);
INSERT INTO Digits VALUES (4);
INSERT INTO Digits VALUES (5);
INSERT INTO Digits VALUES (6);
INSERT INTO Digits VALUES (7);
INSERT INTO Digits VALUES (8);
INSERT INTO Digits VALUES (9);

create table numbers (num) as
select
  d1.digit * 10 + d2.digit as num
from 
  digits as d1 cross join digits as d2
where
  d1.digit * 10 + d2.digit between 1 and 99
;

select dividend.num as perfect
from numbers as dividend inner join numbers divisor
on divisor.num <= dividend.num / 2
and mod(dividend.num, divisor.num) = 0
group by dividend.num
having dividend.num = sum(divisor.num)
order by perfect;

/* 部分集合の組み合わせ（横持データの場合） */
drop table if exists elements;
create table elements (e integer);
insert into elements values (1);
insert into elements values (2);
insert into elements values (3);
insert into elements values (4);
insert into elements values (5);

-- 非等値結合
select e1.e from elements as e1 where e1.e = 7;

select e1.e as e_1, e2.e as e_2 
from elements as e1 inner join elements as e2 
  on e1.e < e2.e 
where e1.e + e2.e = 7;

-- ビットフラグ
create table booltbl (bit_flg integer);
insert into booltbl values (1);
insert into booltbl values (0);
select a.bit_flg as a_bit, b.bit_flg as b_bit, c.bit_flg as c_bit, d.bit_flg as d_bit, e.bit_flg as e_bit
from booltbl as a, booltbl as b, booltbl as c, booltbl as d, booltbl as e;

-- スカラサブクエリ
select e1.e as e_1, e2.e as e_2, e3.e as e_3, e4.e as e_4, e5.e as e_5
from (
  select a.bit_flg as a_bit, b.bit_flg as b_bit, c.bit_flg as c_bit, d.bit_flg as d_bit, e.bit_flg as e_bit
  from booltbl as a, booltbl as b, booltbl as c, booltbl as d, booltbl as e 
) as flg
  left join (select e from elements where e = 1) as e1 on a_bit = 1
  left join (select e from elements where e = 2) as e2 on b_bit = 1
  left join (select e from elements where e = 3) as e3 on c_bit = 1
  left join (select e from elements where e = 4) as e4 on d_bit = 1
  left join (select e from elements where e = 5) as e5 on e_bit = 1
where coalesce(e1.e, 0) + coalesce(e2.e, 0) + coalesce(e3.e, 0) + coalesce(e4.e, 0) + coalesce(e5.e, 0) = 7;


select a_bit * e1 as e_1, b_bit * e2 as e_2, c_bit * e3 as e_3, d_bit * e4 as e_4, e_bit * e5 as e_5
from (
  select
    a_bit, b_bit, c_bit, d_bit, e_bit
    , (select e from elements where e = 1) as e1
    , (select e from elements where e = 2) as e2
    , (select e from elements where e = 3) as e3
    , (select e from elements where e = 4) as e4
    , (select e from elements where e = 5) as e5
  from
    (select a.bit_flg as a_bit, b.bit_flg as b_bit, c.bit_flg as c_bit, d.bit_flg as d_bit, e.bit_flg as e_bit
     from booltbl as a, booltbl as b, booltbl as c, booltbl as d, booltbl as e) as flg
) as tmp
where
  a_bit * e1 + b_bit * e2 + c_bit * e3 + d_bit * e4 + e_bit * e5 = 7
;


/* 部分集合の全組み合わせ（横持データの場合） */

create table elementcols (
  e1 integer, e2 integer, e3 integer, e4 integer, e5 integer
);
insert into elementcols values (1, 2, 3, 4, 5);

select e1, e2, e3, e4, e5
from elementcols
group by cube(e1, e2, e3, e4, e5)
having coalesce(e1, 0) + coalesce(e2, 0) + coalesce(e3, 0) + coalesce(e4, 0) + coalesce(e5, 0) = 7
;

/* 素数 全称量化 */
select * from numbers;

-- NOT EXISTS
select num as prime 
from numbers as dividend
where 
  num > 1
  and not exists (
    select * from numbers as divisor
    where
      divisor.num <= sqrt(dividend.num)
      and divisor.num <> 1
      and mod(dividend.num, divisor.num) = 0
  )
order by prime;

-- HAVING
select
  dividend.num as prime
from
  numbers as dividend
  inner join numbers as divisor
    on divisor.num <= sqrt(dividend.num)
where dividend.num > 1
group by dividend.num
having 1 = sum(case when mod(dividend.num, divisor.num) = 0 then 1 else 0 end)
order by prime;


-- ウインドウ関数
select distinct prime
from (
  select
    dividend.num as prime
    , sum(case when mod(dividend.num, divisor.num) = 0 then 1 else 0 end) over(partition by dividend.num) as flg
  from
    numbers as dividend inner join numbers as divisor
    on divisor.num <= sqrt(dividend.num)
  where
    dividend.num > 1
)
where flg = 1
order by prime;

/* 連番は抜け */
create table gaps (num integer);
insert into gaps values (1);
insert into gaps values (2);
insert into gaps values (3);
insert into gaps values (5);
insert into gaps values (6);

select '歯抜けあり' as result
from gaps
having count(*) <> max(num)
;

select
  num
  , case 
      when num + 1 <> lead(num, 1) over(order by num) then '歯抜けあり' 
      else '歯抜けなし' 
    end result
from gaps;

select num
from numbers
where num between 1 and (select max(num) from gaps)
except
select num from gaps;


/* 連番（連続と断絶） */

create table line (num integer);
insert into line values (1);
insert into line values (2);
insert into line values (5);
insert into line values (6);
insert into line values (7);
insert into line values (8);
insert into line values (11);
insert into line values (12);
insert into line values (13);
insert into line values (15);
insert into line values (16);
insert into line values (17);

select 
  min(tmp.data_val) as start_num
  , min(tmp.data_val) + count(*) -1 as end_num
  , count(*) as length
from (
  select
    num as data_val
    , row_number() over(order by num) as data_seq
    , num - row_number() over(order by num) as absent_data_grp
  from
    line
) as tmp
group by
  tmp.absent_data_grp
;

select
  l1.num as start_date
  , min(l2.num) as end_date
  , min(l2.num) - l1.num + 1 as length
from
  line as l1, line as l2
where
  l1.num <= l2.num
  and not exists (
    select *
    from line as l3
    where l3.num not between l1.num and l2.num
      and (l3.num = l1.num - 1
        or l3.num = l2.num + 1)
  )
group by
  l1.num
order by
  l1.num
;

select
  num, '~', num + (3 - 1) as end_seq
from (
  select
    num
    , max(num) over(order by num rows between (3 - 1) following and (3 - 1) following) as end_num
  from
    line
) as tmp
where
  end_num - num = (3 - 1)


---------------------------------------------------------------
-- 第５章　ウインドウ関数 SQLで魔法をかける
---------------------------------------------------------------

/* 移動平均 */
CREATE TABLE StockPrice
(deal_date   DATE,
 ticker_symbol CHAR(4),
 stock_price INTEGER,
   CONSTRAINT pk_StockPrice PRIMARY KEY (deal_date, ticker_symbol));

INSERT INTO StockPrice (deal_date, ticker_symbol, stock_price) VALUES ('2025-04-01', 'AAAA', 120);
INSERT INTO StockPrice (deal_date, ticker_symbol, stock_price) VALUES ('2025-04-02', 'AAAA', 125);
INSERT INTO StockPrice (deal_date, ticker_symbol, stock_price) VALUES ('2025-04-03', 'AAAA', 150);
INSERT INTO StockPrice (deal_date, ticker_symbol, stock_price) VALUES ('2025-04-04', 'AAAA', 90);
INSERT INTO StockPrice (deal_date, ticker_symbol, stock_price) VALUES ('2025-04-05', 'AAAA', 104);
INSERT INTO StockPrice (deal_date, ticker_symbol, stock_price) VALUES ('2025-04-06', 'AAAA', 190);
INSERT INTO StockPrice (deal_date, ticker_symbol, stock_price) VALUES ('2025-04-01', 'BBBB', 300);
INSERT INTO StockPrice (deal_date, ticker_symbol, stock_price) VALUES ('2025-04-05', 'BBBB', 200);
INSERT INTO StockPrice (deal_date, ticker_symbol, stock_price) VALUES ('2025-04-07', 'BBBB', 150);
INSERT INTO StockPrice (deal_date, ticker_symbol, stock_price) VALUES ('2025-04-09', 'BBBB', 212);
INSERT INTO StockPrice (deal_date, ticker_symbol, stock_price) VALUES ('2025-04-12', 'BBBB', 350);
INSERT INTO StockPrice (deal_date, ticker_symbol, stock_price) VALUES ('2025-04-13', 'BBBB', 800);

select
  deal_date
  , ticker_symbol
  , avg(stock_price) over(partition by ticker_symbol order by deal_date rows between 2 preceding and current row) as mvg_avg
from stockprice;

/* トレンド分析 */
select
  deal_date
  , ticker_symbol
  , stock_price
  , case 
      when stock_price - lag(stock_price) over(partition by ticker_symbol order by deal_date) = 0 then '-'
      when stock_price - lag(stock_price) over(partition by ticker_symbol order by deal_date) > 0 then 'up'
      when stock_price - lag(stock_price) over(partition by ticker_symbol order by deal_date) < 0 then 'down'
      else null
    end as diff
from
  stockprice
order by
  ticker_symbol, deal_date;
  
/* レスポンスタイム */
CREATE TABLE ResponseTimes
(time_id INTEGER,
 response_time INTEGER,
   CONSTRAINT pk_ResponseTimes PRIMARY KEY (time_id));

INSERT INTO ResponseTimes(time_id, response_time) VALUES (   1, 3);  
INSERT INTO ResponseTimes(time_id, response_time) VALUES (   2, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (   3, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (   4, 4);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (   5, 5);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (   6, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (   7, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (   8, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (   9, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  10, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  11, 4);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  12, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  13, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  14, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  15, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  16, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  17, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  18, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  19, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  20, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  21, 6);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  22, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  23, 8);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  24, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  25, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  26, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  27, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  28, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  29, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  30, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  31, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  32, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  33, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  34, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  35, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  36, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  37, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  38, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  39, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  40, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  41, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  42, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  43, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  44, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  45, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  46, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  47, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  48, 9);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  49, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  50, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  51, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  52, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  53, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  54, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  55, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  56, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  57, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  58, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  59, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  60, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  61, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  62, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  63, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  64, 5);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  65, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  66, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  67, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  68, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  69, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  70, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  71, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  72, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  73, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  74, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  75, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  76, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  77, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  78, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  79, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  80, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  81, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  82, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  83, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  84, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  85, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  86, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  87, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  88, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  89, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  90, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  91, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  92, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  93, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  94, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  95, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  96, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  97, 1);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  98, 3);
INSERT INTO ResponseTimes(time_id, response_time) VALUES (  99, 2);
INSERT INTO ResponseTimes(time_id, response_time) VALUES ( 100, 1);

select
  time_id
  , response_time
  , row_number() over(order by response_time)
  , percentile_cont(0.9) within group (order by response_time)
from
  ResponseTimes
group by
  time_id
;

/* 四分位(NTILE関数) */
select
  time_id
  , response_time
  , ntile(4) over(partition by response_time) as tile
from
  ResponseTimes
order by
  tile
;

/* 剰余類 */
select
  time_id
  , response_time
  , mod(time_id, 4) as modulo
from
  ResponseTimes
order by
  time_id
;

/* 中央値 */
Drop TABLE IF EXISTS Weights;
CREATE TABLE Weights
(student_id	CHAR(4) PRIMARY KEY,
 weight     INTEGER);

●レコード数が奇数
INSERT INTO Weights VALUES('A100',	50);
INSERT INTO Weights VALUES('A101',	55);
INSERT INTO Weights VALUES('A124',	55);
INSERT INTO Weights VALUES('B343',	60);
INSERT INTO Weights VALUES('B346',	72);
INSERT INTO Weights VALUES('C563',	72);
INSERT INTO Weights VALUES('C345',	72);

●レコード数が偶数
INSERT INTO Weights VALUES('A100',	50);
INSERT INTO Weights VALUES('A101',	55);
INSERT INTO Weights VALUES('A124',	55);
INSERT INTO Weights VALUES('B343',	60);
INSERT INTO Weights VALUES('B346',	72);
INSERT INTO Weights VALUES('C563',	72);

select
  avg(weight) as avg_weight
from (
  select
    weight
    , row_number() over(order by weight asc, student_id asc) as hi
    , row_number() over(order by weight desc, student_id desc) as lo
  from weights
)
where hi in (lo, lo+1, lo-1)
;  

select avg(weight)
from (select weight, 2 + row_number() over(order by weight) - count(*) over() as diff from weights) as tmp
where diff between 0 and 2;

/* 累積 */

CREATE TABLE SalesIcecream
(shop_id   CHAR(4) NOT NULL,
 sale_date DATE NOT NULL,
 sales_amt INTEGER NOT NULL,
   CONSTRAINT pk_SalesIcecream PRIMARY KEY(shop_id, sale_date) );

INSERT INTO SalesIcecream VALUES('A', '2024-06-01', 67800);
INSERT INTO SalesIcecream VALUES('A', '2024-06-02', 87000);
INSERT INTO SalesIcecream VALUES('A', '2024-06-05', 11300);
INSERT INTO SalesIcecream VALUES('A', '2024-06-10', 9800);
INSERT INTO SalesIcecream VALUES('A', '2024-06-15', 9800);
INSERT INTO SalesIcecream VALUES('B', '2024-06-02', 178000);
INSERT INTO SalesIcecream VALUES('B', '2024-06-15', 18800);
INSERT INTO SalesIcecream VALUES('B', '2024-06-17', 19850);
INSERT INTO SalesIcecream VALUES('B', '2024-06-20', 23800);
INSERT INTO SalesIcecream VALUES('B', '2024-06-21', 18800);
INSERT INTO SalesIcecream VALUES('C', '2024-06-01', 12500);

select
  shop_id
  , sale_date
  , sales_amt
  , sum(sales_amt) over(partition by shop_id order by sale_date rows between unbounded preceding and current row)
from
  SalesIcecream
;

/* データと件数の取得 */
select
  shop_id
  , sale_date
  , sales_amt
  , sum(sales_amt) over(partition by shop_id order by sale_date) as cumlative_amt
  , count(*) over() as cnt
from
  SalesIcecream
;


/* 最頻値（HAVING句） */

CREATE TABLE Graduates
(name   VARCHAR(16) PRIMARY KEY,
 income INTEGER NOT NULL);

INSERT INTO Graduates VALUES('サンプソン', 400000);
INSERT INTO Graduates VALUES('マイク',     30000);
INSERT INTO Graduates VALUES('ホワイト',   20000);
INSERT INTO Graduates VALUES('アーノルド', 20000);
INSERT INTO Graduates VALUES('スミス',     20000);
INSERT INTO Graduates VALUES('ロレンス',   15000);
INSERT INTO Graduates VALUES('ハドソン',   15000);
INSERT INTO Graduates VALUES('ケント',     10000);
INSERT INTO Graduates VALUES('ベッカー',   10000);
INSERT INTO Graduates VALUES('スコット',   10000);

select
  income, cnt
from(
  select
    income
    , count(*) as cnt
    , max(count(*)) over() as max_cnt
  from
    Graduates
  group by
    income
) as tmp
where cnt = max_cnt;
;

/* ignore nulls */
DROP TABLE IF EXISTS Elements;
CREATE TABLE Elements
(lvl INTEGER NOT NULL,
 color VARCHAR(10),
 length INTEGER,
 width INTEGER,
 hgt INTEGER,
   CONSTRAINT pk_Elements PRIMARY KEY(lvl) );

INSERT INTO Elements (lvl, color, length, width, hgt) VALUES(1, 'RED',	8,	10,	12);
INSERT INTO Elements (lvl, color, length, width, hgt) VALUES(2, NULL,  NULL, NULL,	20);
INSERT INTO Elements (lvl, color, length, width, hgt) VALUES(3, NULL,	9,	82,	 25);
INSERT INTO Elements (lvl, color, length, width, hgt) VALUES(4, 'BLUE',		NULL, 67, NULL);
INSERT INTO Elements (lvl, color, length, width, hgt) VALUES(5, 'GRAY',		NULL, NULL, NULL);

SELECT 
  (SELECT color FROM Elements WHERE lvl = M.lc) AS max_color
  , (SELECT length FROM Elements WHERE lvl = M.ll) AS max_length
  , (SELECT width FROM Elements WHERE lvl = M.lw) AS max_width
  , (SELECT hgt   FROM Elements WHERE lvl = M.lh) AS max_hgt
 FROM (SELECT
        MAX(CASE WHEN color IS NOT NULL THEN lvl END) AS lc,
          MAX(CASE WHEN length IS NOT NULL THEN lvl END) AS ll,
          MAX(CASE WHEN width IS NOT NULL THEN lvl END) AS lw,
          MAX(CASE WHEN hgt IS NOT NULL THEN lvl END) AS lh
       FROM Elements) as M;



---------------------------------------------------------------
-- 第６章　SQLで木構造を扱う
---------------------------------------------------------------

/* 隣接モデル（階層の深さ） */
CREATE TABLE OrgChartAdj
 (emp  VARCHAR(32) PRIMARY KEY,
  boss VARCHAR(32),
  role VARCHAR(32) NOT NULL,
    CONSTRAINT fk_OrgChartAdj FOREIGN KEY (boss) REFERENCES OrgChartAdj(emp) ); 

INSERT INTO OrgChartAdj VALUES ('高橋', NULL,  '社長');
INSERT INTO OrgChartAdj VALUES ('鈴木', '高橋', '部長');
INSERT INTO OrgChartAdj VALUES ('藤井', '高橋', '部長');
INSERT INTO OrgChartAdj VALUES ('吉村', '藤井', '課長');
INSERT INTO OrgChartAdj VALUES ('香川', '藤井', '課長');
INSERT INTO OrgChartAdj VALUES ('高田', '藤井', '課長');
INSERT INTO OrgChartAdj VALUES ('木曽', '吉村', 'ヒラ');

with recursive emp_tmp(emp, boss, depth) as (
  select 
    a1.emp
    , a1.boss
    , 1 as depth
  from orgchartadj as a1
  where boss is null
  union all
  select
    a2.emp
    , a2.boss
    , tmp.depth + 1
  from
    orgchartadj as a2 inner join emp_tmp as tmp
    on a2.boss = tmp.emp
)
select emp, boss, depth from emp_tmp;

/* 隣接モデル（ルートノード） */
with recursive emp_tmp(emp, boss, depth) as (
  select 
    a1.emp
    , a1.boss
    , 1 as depth
  from orgchartadj as a1
  where a1.emp = '香川'
  union all
  select
    a2.emp
    , a2.boss
    , tmp.depth + 1
  from
    orgchartadj as a2 inner join emp_tmp as tmp
    on tmp.boss = a2.emp
)
select emp, boss, depth from emp_tmp;


/* 隣接モデル（リーフノード）*/
select
  o1.emp
from
  orgchartadj as o1
where
  not exists (
    select 1 from orgchartadj as o2
    where o1.emp = o2.boss
  );

/* 入れ子集合モデル（階層の深さ） */

CREATE TABLE OrgChartNestedSets
 (emp VARCHAR(32) PRIMARY KEY,
  lft INTEGER NOT NULL,
  rgt INTEGER NOT NULL,
    CHECK (lft < rgt)); 

INSERT INTO OrgChartNestedSets VALUES ('高橋',  1, 14);
INSERT INTO OrgChartNestedSets VALUES ('鈴木',  2,  3);
INSERT INTO OrgChartNestedSets VALUES ('藤井',  4, 13);
INSERT INTO OrgChartNestedSets VALUES ('吉村',  5,  8);
INSERT INTO OrgChartNestedSets VALUES ('木曽',  6,  7);
INSERT INTO OrgChartNestedSets VALUES ('香川',  9,  10);
INSERT INTO OrgChartNestedSets VALUES ('高田', 11,  12);

select
  o2.emp
  , count(o1.emp) as cnt
from
  OrgChartNestedSets as o1, OrgChartNestedSets as o2
where
  o2.lft between o1.lft and o1.rgt
group by
  o2.emp
order by cnt;

/* 入れ子集合モデル（上司の抽出） */
select
  o1.emp as boss
from
  OrgChartNestedSets as o1, OrgChartNestedSets as o2
where
  o2.emp = '香川'
  and o2.lft between o1.lft and o1.rgt
;

/* 入れ子集合モデル（リーフノード） */
select *
from OrgChartNestedSets as o1
where not exists (
  select 1 from OrgChartNestedSets as o2
  where o2.lft > o1.lft
    and o2.lft < o1.rgt
);


/* 入れ子集合モデル（ルートノード） */
select *
from OrgChartNestedSets as o1
where not exists (
  select 1 from OrgChartNestedSets as o2
  where o1.lft > o2.lft
    and o1.lft < o2.rgt
);


/* 経路列挙モデル（基本） */

CREATE TABLE OrgChartPath
 (emp  VARCHAR(32) PRIMARY KEY
    CHECK (REPLACE(emp, '/', '') = emp),
  path VARCHAR(256) NOT NULL,
    UNIQUE (path)); 

INSERT INTO OrgChartPath VALUES ('高橋',  '/高橋/');
INSERT INTO OrgChartPath VALUES ('鈴木',  '/高橋/鈴木/');
INSERT INTO OrgChartPath VALUES ('藤井',  '/高橋/藤井/');
INSERT INTO OrgChartPath VALUES ('吉村',  '/高橋/藤井/吉村/');
INSERT INTO OrgChartPath VALUES ('木曽',  '/高橋/藤井/吉村/木曽/' );
INSERT INTO OrgChartPath VALUES ('香川',  '/高橋/藤井/香川/' );
INSERT INTO OrgChartPath VALUES ('高田',  '/高橋/藤井/高田/' );

select emp, length(path) - length(replace(path, '/', '')) - 1 as depth
from OrgChartPath;


/* 経路列挙モデル（上司の抽出） */

select 
  o1.emp
  , (select emp from OrgChartPath where path = max(o2.path)) as level_0
  , (select emp from OrgChartPath where path = max(o3.path)) as level_1
  , (select emp from OrgChartPath where path = max(o4.path)) as level_2
from
  OrgChartPath as o1
  left join OrgChartPath as o2
    on o1.path like o2.path || '_%'
  left join OrgChartPath as o3
    on o2.path like o3.path || '_%'
  left join OrgChartPath as o4
    on o3.path like o4.path || '_%'
group by
  o1.emp
;



/* 経路列挙モデル（リーフノード） */
select * from OrgChartPath as parents
where not exists (
  select 1 from OrgChartPath as children
  where children.path like parents.path || '_%'
);


/* 経路列挙モデル（ルートノード） */
select * from OrgChartPath
where emp = replace(path, '/', '');


/* 閉包テーブルモデル（ノードの深さ）*/
CREATE TABLE OrgChart
 (emp  VARCHAR(32) PRIMARY KEY,
  role VARCHAR(32) NOT NULL,
  tree_id INTEGER  UNIQUE NOT NULL); 

CREATE TABLE Closure
(parent INTEGER NOT NULL,
 child  INTEGER NOT NULL,
   CONSTRAINT pk_Closure PRIMARY KEY (parent, child),
   CONSTRAINT fk_parent FOREIGN KEY  (parent) REFERENCES OrgChart (tree_id),
   CONSTRAINT fk_child  FOREIGN KEY  (child)  REFERENCES OrgChart (tree_id));


INSERT INTO OrgChart VALUES ('高橋',  '社長', 1);
INSERT INTO OrgChart VALUES ('鈴木',  '部長', 2);
INSERT INTO OrgChart VALUES ('藤井',  '部長', 3);
INSERT INTO OrgChart VALUES ('吉村',  '課長', 4);
INSERT INTO OrgChart VALUES ('香川',  '課長', 5);
INSERT INTO OrgChart VALUES ('高田',  '課長', 6);
INSERT INTO OrgChart VALUES ('木曽',  'ヒラ', 7);

INSERT INTO Closure VALUES (1, 1);
INSERT INTO Closure VALUES (1, 2);
INSERT INTO Closure VALUES (1, 3);
INSERT INTO Closure VALUES (1, 4);
INSERT INTO Closure VALUES (1, 5);
INSERT INTO Closure VALUES (1, 6);
INSERT INTO Closure VALUES (1, 7);
INSERT INTO Closure VALUES (2, 2);
INSERT INTO Closure VALUES (3, 3);
INSERT INTO Closure VALUES (3, 4);
INSERT INTO Closure VALUES (3, 5);
INSERT INTO Closure VALUES (3, 6);
INSERT INTO Closure VALUES (3, 7);
INSERT INTO Closure VALUES (4, 4);
INSERT INTO Closure VALUES (4, 7);
INSERT INTO Closure VALUES (5, 5);
INSERT INTO Closure VALUES (6, 6);
INSERT INTO Closure VALUES (7, 7);


select o.emp, count(*) as depth
from OrgChart as o inner join Closure as c
  on o.tree_id = c.child
group by
  o.emp
order by
  depth
;


/* 閉包テーブルモデル（上司の列挙）*/

select emp
from OrgChart as o inner join (
  select c.parent
  from OrgChart as o inner join Closure as c
    on o.tree_id = c.child
  where
    o.emp = '香川'
) as tmp
on o.tree_id = tmp.parent;


/* 閉包テーブルモデル（リーフノード）*/
select emp
from OrgChart as o inner join (
  select parent, count(*) as cnt
  from Closure
  group by parent
  having count(*) = 1
) as c
on o.tree_id = c.parent;

/* 閉包テーブルモデル（ルートノード）*/

select distinct o.emp
from (
  select parent, count(*) as cnt
  from Closure
  group by parent
) as c
inner join
(
  select parent, max(cnt) over() as max_cnt
  from (
    select parent, count(*) as cnt
    from Closure
    group by parent
  )
) as mc
on c.cnt = mc.max_cnt
inner join orgchart as o on o.tree_id = c.parent;
