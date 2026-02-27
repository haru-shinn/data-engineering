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



---------------------------------------------------------------
-- 第４章　SQLで数学パズルを解く
---------------------------------------------------------------




---------------------------------------------------------------
-- 第５章　ウインドウ関数 SQLで魔法をかける
---------------------------------------------------------------






---------------------------------------------------------------
-- 第６章　SQLで木構造を扱う
---------------------------------------------------------------




---------------------------------------------------------------
-- 第７章　卒業試験
---------------------------------------------------------------




