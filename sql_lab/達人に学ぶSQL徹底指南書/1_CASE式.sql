/* CASE式 */

/* CASE式のお試し */

CREATE TABLE guide.poptbl (
  pref_name VARCHAR(32) PRIMARY KEY
  , population INTEGER NOT NULL
);
INSERT INTO guide.poptbl VALUES ('徳島', 100);
INSERT INTO guide.poptbl VALUES ('香川', 200);
INSERT INTO guide.poptbl VALUES ('愛媛', 150);
INSERT INTO guide.poptbl VALUES ('高知', 200);
INSERT INTO guide.poptbl VALUES ('福岡', 300);
INSERT INTO guide.poptbl VALUES ('佐賀', 100);
INSERT INTO guide.poptbl VALUES ('長崎', 200);
INSERT INTO guide.poptbl VALUES ('東京', 400);
INSERT INTO guide.poptbl VALUES ('群馬', 50);

SELECT
  CASE
    WHEN population < 100 THEN '01'
    WHEN population >= 100 AND population < 200 THEN '02'
    WHEN population >= 200 AND population < 300 THEN '03'
    WHEN population >= 300 THEN '04'
  END AS pop_class
  , COUNT(*) AS cnt
FROM guide.poptbl
GROUP BY pop_class
ORDER BY pop_class;


/* 異なる条件の集計を行う */
TRUNCATE TABLE guide.poptbl2;
CREATE TABLE guide.poptbl2 (
  pref_name VARCHAR(8)
  , sex CHAR(1)
  , population INTEGER
  , PRIMARY KEY (pref_name, sex)
);
INSERT INTO guide.poptbl2 VALUES ('徳島', '1', 60);
INSERT INTO guide.poptbl2 VALUES ('徳島', '2', 40);
INSERT INTO guide.poptbl2 VALUES ('香川', '1', 100);
INSERT INTO guide.poptbl2 VALUES ('香川', '2', 100);
INSERT INTO guide.poptbl2 VALUES ('愛媛', '1', 100);
INSERT INTO guide.poptbl2 VALUES ('愛媛', '2', 50);
INSERT INTO guide.poptbl2 VALUES ('高知', '1', 100);
INSERT INTO guide.poptbl2 VALUES ('高知', '2', 100);
INSERT INTO guide.poptbl2 VALUES ('福岡', '1', 100);
INSERT INTO guide.poptbl2 VALUES ('福岡', '2', 200);
INSERT INTO guide.poptbl2 VALUES ('佐賀', '1', 20);
INSERT INTO guide.poptbl2 VALUES ('佐賀', '2', 80);
INSERT INTO guide.poptbl2 VALUES ('長崎', '1', 125);
INSERT INTO guide.poptbl2 VALUES ('長崎', '2', 125);
INSERT INTO guide.poptbl2 VALUES ('東京', '1', 250);
INSERT INTO guide.poptbl2 VALUES ('東京', '2', 150);

SELECT
  pref_name
  , SUM(CASE WHEN sex = '1' THEN population ELSE 0 END) AS male
  , SUM(CASE WHEN sex = '2' THEN population ELSE 0 END) as female
FROM guide.poptbl2
GROUP BY pref_name
ORDER BY pref_name;


/* 複数の列の条件関係を定義 */

CREATE TABLE guide.personnel (
  name VARCHAR(8) PRIMARY KEY
  , salary INTEGER
);
INSERT INTO guide.personnel VALUES ('相田', 300000);
INSERT INTO guide.personnel VALUES ('神崎', 270000);
INSERT INTO guide.personnel VALUES ('木村', 220000);
INSERT INTO guide.personnel VALUES ('斎藤', 290000);

SELECT
  name
  , salary
  , CASE
      WHEN salary >= 300000 THEN CAST(salary * 0.9 AS INTEGER)
      WHEN salary BETWEEN 250000 AND 280000 THEN CAST(salary * 1.2 AS INTEGER)
      ELSE salary
    END AS salary_after
FROM
  guide.personnel
;


/* 主キーの入れ替え */

CREATE TABLE guide.sometable (
    p_key char(1) PRIMARY KEY
    , col_1 INTEGER
    , col_2 CHAR(1)
);
INSERT INTO guide.sometable VALUES ('a', 1, 'あ');
INSERT INTO guide.sometable VALUES ('b', 2, 'い');
INSERT INTO guide.sometable VALUES ('c', 3, 'う');

SELECT
  CASE
    WHEN p_key = 'a' THEN 'b'
    WHEN p_key = 'b' THEN 'a'
    ELSE p_key
  END AS p_key
  , col_1
  , col_2
FROM
  guide.sometable
;


/* テーブル同士のマッチング */


CREATE TABLE guide.coursemaster (
  course_id INTEGER PRIMARY KEY
  , course_name VARCHAR(128)
);

INSERT INTO guide.coursemaster VALUES (1, '経理入門');
INSERT INTO guide.coursemaster VALUES (2, '財務知識');
INSERT INTO guide.coursemaster VALUES (3, '簿記検定開港講座');
INSERT INTO guide.coursemaster VALUES (4, '税理士');

SELECT COUNT(*) AS cnt FROM guide.coursemaster;

CREATE TABLE guide.opencourses (
  mon CHAR(6)
  , course_id INTEGER
  , PRIMARY KEY (mon, course_id)
);

INSERT INTO guide.opencourses VALUES ('201806', 1);
INSERT INTO guide.opencourses VALUES ('201806', 3);
INSERT INTO guide.opencourses VALUES ('201806', 4);
INSERT INTO guide.opencourses VALUES ('201807', 4);
INSERT INTO guide.opencourses VALUES ('201808', 2);
INSERT INTO guide.opencourses VALUES ('201808', 4);

SELECT COUNT(*) AS cnt FROM guide.opencourses;

-- max, minで結果が変わるので不採用
EXPLAIN ANALYSE
SELECT
  course_name
  , MAX(CASE WHEN mon = '201806' THEN '〇' ELSE '×' END ) AS jun
  , MAX(CASE WHEN mon = '201807' THEN '〇' ELSE '×' END ) AS jul
  , MAX(CASE WHEN mon = '201808' THEN '〇' ELSE '×' END ) AS aug
FROM
  opencourses AS oc LEFT JOIN coursemaster AS cs
  ON oc.course_id = cs.course_id
GROUP BY
  course_name
;

-- MINだと〇と×が反転してしまう。
SELECT
  course_name
  , MIN(CASE WHEN mon = '201806' THEN '〇' ELSE '×' END ) AS jun
  , MIN(CASE WHEN mon = '201807' THEN '〇' ELSE '×' END ) AS jul
  , MIN(CASE WHEN mon = '201808' THEN '〇' ELSE '×' END ) AS aug
FROM
  opencourses AS oc LEFT JOIN coursemaster AS cs
  ON oc.course_id = cs.course_id
GROUP BY
  course_name
;

-- IN利用
EXPLAIN ANALYSE
SELECT 
  course_name
  , CASE 
      WHEN course_id IN (SELECT course_id FROM opencourses WHERE mon = '201806') THEN '〇' 
      ELSE '×' 
    END AS jun
  , CASE 
      WHEN course_id IN (SELECT course_id FROM opencourses WHERE mon = '201807') THEN '〇' 
      ELSE '×' 
    END AS jul
  , CASE 
      WHEN course_id IN (SELECT course_id FROM opencourses WHERE mon = '201808') THEN '〇' 
      ELSE '×' 
    END AS aug
FROM
  coursemaster
;

-- EXISTS利用
EXPLAIN ANALYSE
SELECT 
  cm.course_name
  , CASE 
      WHEN EXISTS 
        (SELECT course_id FROM opencourses oc 
          WHERE mon = '201806' AND oc.course_id = cm.course_id) THEN '〇' 
      ELSE '×' 
    END AS jun
  , CASE 
      WHEN EXISTS 
        (SELECT course_id FROM opencourses oc 
          WHERE mon = '201807' AND oc.course_id = cm.course_id) THEN '〇' 
      ELSE '×' 
    END AS jul
  , CASE 
      WHEN EXISTS 
        (SELECT course_id FROM opencourses oc 
          WHERE mon = '201808' AND oc.course_id = cm.course_id) THEN '〇' 
      ELSE '×' 
    END AS aug
FROM
  coursemaster AS cm
;

-- 実行計画の比較のためデータ量増やす
-- 1つ目のJoin形式が一番効率よい、3つ目は一番コスト悪い。
DROP TABLE guide.coursemaster;
TRUNCATE guide.coursemaster;
INSERT INTO guide.coursemaster
SELECT 
  i
  , 'course_' || md5(random()::text) || '_' || i
FROM generate_series(1, 100000) s(i);

DROP TABLE guide.opencourses;
TRUNCATE guide.opencourses;
INSERT INTO guide.opencourses
SELECT
  m.mon
  , cs.course_id
FROM
  (SELECT unnest(ARRAY['201806', '201807', '201808']) AS mon) m
CROSS JOIN
  (SELECT course_id FROM guide.coursemaster WHERE random() < 0.4) cs
;

-- Index付与してみる
-- IN述語利用するのがよさそう。EXISTS述語は相関サブクエリがしんどい？
CREATE INDEX idx_opencourses_mon ON guide.opencourses(mon);
/*
まとめ
クエリの手法,インデックス なし の挙動,インデックス あり の挙動,メモリ制限下での評価
1. Hash Join (結合+集約),約130ms全件走査(Seq Scan)して結合。,約125ms挙動はほぼ変わらず。全件走査が続く。,△：やや不利データ増でメモリ不足になりやすく、ディスクへ溢れる。
2. SubPlan (A) (今回の勝者),約130ms以上サブクエリ内で全件走査が発生。,約113msBitmap Index Scanで必要な月だけを狙い撃ち。,◎：最適1回ごとのサブクエリが軽量。キャッシュも効きやすい。
3. SubPlan (B) (JIT有効時),約500ms以上JITの準備と全件走査で低速。,約224msインデックスで速くなるが、JITの準備時間が重い。,×：非効率構造が複雑と判定され、無駄な最適化コストがかかる。
*/


/* CASE式の中で集約 */

CREATE TABLE guide.studentclub (
  std_id CHAR(3)
  , club_id CHAR(1)
  , club_name VARCHAR(16)
  , main_club_flg BOOLEAN
  , PRIMARY KEY (std_id, club_id)
);

INSERT INTO guide.studentclub VALUES ('100', '1', 'baseball', 'Y');
INSERT INTO guide.studentclub VALUES ('100', '2', 'music', 'N');
INSERT INTO guide.studentclub VALUES ('200', '2', 'music', 'N');
INSERT INTO guide.studentclub VALUES ('200', '3', 'badminton', 'Y');
INSERT INTO guide.studentclub VALUES ('200', '4', 'soccer', 'N');
INSERT INTO guide.studentclub VALUES ('300', '4', 'soccer', 'N');
INSERT INTO guide.studentclub VALUES ('400', '5', 'swim', 'N');
INSERT INTO guide.studentclub VALUES ('500', '6', 'go', 'N');

-- 取得条件
-- 一つだけのクラブに所属している学生は、そのクラブID
-- 複数のクラブに所属している学生は、主なクラブのID

SELECT
  std_id
  , CASE WHEN COUNT(std_id) = 1 THEN MAX(club_id)
    ELSE MAX(
      CASE 
        WHEN main_club_flg = 'Y' THEN club_id
        ELSE NULL
      END
    )  END AS main_club_id
FROM
  guide.studentclub
GROUP BY
  std_id
ORDER BY
  std_id
;

-- 別解（パフォーマンスは悪いが自分で思いついたクエリ）
SELECT
  std_id
  , MAX(CASE
      WHEN main_club_flg IS TRUE THEN club_id
      WHEN (SELECT COUNT(std_id) FROM guide.studentclub sub WHERE main.std_id = sub.std_id) = 1 THEN club_id
      ELSE NULL
    END) AS main_club_id
FROM
  guide.studentclub main
GROUP BY
  std_id
;


/* 演習問題 */

/* 演習問題1-1 */
-- 複数列の最大値

CREATE TABLE guide.greatests (
  key CHAR(1) PRIMARY KEY
  , x INTEGER
  , y INTEGER
  , z INTEGER
);

INSERT INTO guide.greatests VALUES ('A', 1, 2, 3);
INSERT INTO guide.greatests VALUES ('B', 5, 5, 2);
INSERT INTO guide.greatests VALUES ('C', 4, 7, 1);
INSERT INTO guide.greatests VALUES ('D', 3, 3, 8);

-- x, y の最大値を取得
SELECT
  key
  , CASE
      WHEN x > y THEN x
      WHEN x < y THEN y
      ELSE x
    END AS greatest
FROM
  guide.greatests
;

-- x, y, z の最大値を取得
SELECT
  key
  , CASE
      WHEN x >= y AND x >= z THEN x
      WHEN y >= x AND y >= z THEN y
      ELSE z
    END AS greatest
FROM
  guide.greatests
;

/* 演習問題1-2 */
-- 合計と埼葛を表頭に出力する行列変換

SELECT
  sex
  , SUM(population) AS "全国"
  , SUM(CASE WHEN pref_name = '徳島' THEN population ELSE 0 END) AS "徳島"
  , SUM(CASE WHEN pref_name = '香川' THEN population ELSE 0 END) AS "香川"
  , SUM(CASE WHEN pref_name = '愛媛' THEN population ELSE 0 END) AS "愛媛"
  , SUM(CASE WHEN pref_name = '高知' THEN population ELSE 0 END) AS "高知"
  , SUM(CASE WHEN pref_name IN ('徳島', '香川', '愛媛', '高知') THEN population ELSE 0 END) AS "四国"
FROM
  guide.poptbl2
GROUP BY
  sex
ORDER BY
  sex
;

/* 演習問題1-3 */
-- ORDER BY でソート列を作る
SELECT 
  key 
FROM 
  guide.greatests 
ORDER BY 
  CASE key 
    WHEN 'B' THEN 1
    WHEN 'A' THEN 2
    WHEN 'D' THEN 3
    WHEN 'C' THEN 4
    ELSE 0
  END
;