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
INSERT INTO guide.poptbl2 VALUES ('愛媛', '1', 50);
INSERT INTO guide.poptbl2 VALUES ('愛媛', '2', 100);
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
  , course_name VARCHAR(16)
);

INSERT INTO guide.coursemaster VALUES (1, '経理入門');
INSERT INTO guide.coursemaster VALUES (2, '財務知識');
INSERT INTO guide.coursemaster VALUES (3, '簿記検定開港講座');
INSERT INTO guide.coursemaster VALUES (4, '税理士');

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

SELECT
  course_name
  , MAX(CASE WHEN mon = '201806' THEN '〇' ELSE '×' END ) AS jun
  , MAX(CASE WHEN mon = '201807' THEN '〇' ELSE '×' END ) AS jul
  , MAX(CASE WHEN mon = '201808' THEN '〇' ELSE '×' END ) AS Aug
FROM
  opencourses AS oc LEFT JOIN coursemaster AS cs
  ON oc.course_id = cs.course_id
GROUP BY
  course_name
;
select * from guide.coursemaster;