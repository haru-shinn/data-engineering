/* 外部結合 */

/* 行列変換 行→列 クロス表*/
DROP TABLE IF EXISTS guide.courses;
CREATE TABLE guide.courses (
  name VARCHAR(32)
  , course VARCHAR(32)
  , PRIMARY KEY (name, course)
);

INSERT INTO guide.courses VALUES('赤井', 'SQL入門');
INSERT INTO guide.courses VALUES('赤井', 'UNIX基礎');
INSERT INTO guide.courses VALUES('鈴木', 'SQL入門');
INSERT INTO guide.courses VALUES('工藤', 'SQL入門');
INSERT INTO guide.courses VALUES('工藤', 'Java中級');
INSERT INTO guide.courses VALUES('吉田', 'UNIX基礎');
INSERT INTO guide.courses VALUES('渡辺', 'SQL入門');

-- 外部結合
SELECT
  c0.name
  , CASE WHEN c1.name IS NOT NULL THEN '〇' ELSE NULL END AS "SQL入門"
  , CASE WHEN c2.name IS NOT NULL THEN '〇' ELSE NULL END AS "UNIX基礎"
  , CASE WHEN c3.name IS NOT NULL THEN '〇' ELSE NULL END AS "Java中級"
FROM (
  SELECT DISTINCT name FROM guide.courses
) AS c0
LEFT JOIN
  (SELECT name FROM guide.courses WHERE course = 'SQL入門') AS c1
  ON c0.name = c1.name
  LEFT JOIN
    (SELECT name FROM guide.courses WHERE course = 'UNIX基礎') AS c2
    ON c0.name = c2.name
      LEFT JOIN
      (SELECT name FROM guide.courses WHERE course = 'Java中級') AS c3
      ON c0.name  =c3.name
;

-- CASE式
SELECT
  name
  , CASE
      WHEN SUM(CASE WHEN course = 'SQL入門' THEN 1 ELSE NULL END) = 1 THEN '〇'
      ELSE NULL
    END AS "SQL入門"
  , CASE
      WHEN SUM(CASE WHEN course = 'UNIX基礎' THEN 1 ELSE NULL END) = 1 THEN '〇'
      ELSE NULL
    END AS "UNIX基礎"
  , CASE
      WHEN SUM(CASE WHEN course = 'Java中級' THEN 1 ELSE NULL END) = 1 THEN '〇'
      ELSE NULL
    END AS "Java中級"
FROM
  guide.courses
GROUP BY
  name
;

/* 行列変換 列→行 繰り返し項目を1列にまとめる */
DROP TABLE IF EXISTS guide.personnel;
CREATE TABLE guide.personnel (
  employee varchar(32)
  , child_1 varchar(32)
  , child_2 varchar(32)
  , child_3 varchar(32)
  , PRIMARY KEY(employee)
);

INSERT INTO guide.personnel VALUES('赤井', '一郎', '二郎', '三郎');
INSERT INTO guide.personnel VALUES('工藤', '春子', '夏子', NULL);
INSERT INTO guide.personnel VALUES('鈴木', '夏子', NULL,NULL);
INSERT INTO guide.personnel VALUES('吉田', NULL,NULL,NULL);

SELECT employee, child_1 AS child FROM guide.personnel
UNION ALL
SELECT employee, child_2 AS child FROM guide.personnel
UNION ALL
SELECT employee, child_2 AS child FROM guide.personnel
; 

/* 演習問題 */

/* 演習問題8-1 */
CREATE TABLE guide.tblsex (
  sex_cd CHAR(1)
  , sex VARCHAR(5)
  , PRIMARY KEY(sex_cd)
);

CREATE TABLE guide.tblage (
  age_class CHAR(1)
  , age_range VARCHAR(30)
  , PRIMARY KEY(age_class)
);

CREATE TABLE guide.tblpop (
  pref_name VARCHAR(30)
  , age_class CHAR(1)
  , sex_cd CHAR(1)
  , population INTEGER
  , PRIMARY KEY(pref_name, age_class,sex_cd)
);

INSERT INTO guide.tblsex (sex_cd, sex) VALUES('m', '男');
INSERT INTO guide.tblsex (sex_cd, sex) VALUES('f', '女');

INSERT INTO guide.tblage (age_class, age_range) VALUES('1', '21～30歳');
INSERT INTO guide.tblage (age_class, age_range) VALUES('2', '31～40歳');
INSERT INTO guide.tblage (age_class, age_range) VALUES('3', '41～50歳');

INSERT INTO guide.tblpop VALUES('秋田', '1', 'm', 400);
INSERT INTO guide.tblpop VALUES('秋田', '3', 'm', 1000);
INSERT INTO guide.tblpop VALUES('秋田', '1', 'f', 800);
INSERT INTO guide.tblpop VALUES('秋田', '3', 'f', 1000);
INSERT INTO guide.tblpop VALUES('青森', '1', 'm', 700);
INSERT INTO guide.tblpop VALUES('青森', '1', 'f', 500);
INSERT INTO guide.tblpop VALUES('青森', '3', 'f', 800);
INSERT INTO guide.tblpop VALUES('東京', '1', 'm', 900);
INSERT INTO guide.tblpop VALUES('東京', '1', 'f', 1500);
INSERT INTO guide.tblpop VALUES('東京', '3', 'f', 1200);
INSERT INTO guide.tblpop VALUES('千葉', '1', 'm', 900);
INSERT INTO guide.tblpop VALUES('千葉', '1', 'f', 1000);
INSERT INTO guide.tblpop VALUES('千葉', '3', 'f', 900);

SELECT
  master.age_class AS age_class
  , master.sex_cd AS sex_cd
  , SUM(
      CASE WHEN pref_name IN ('青森', '秋田') THEN population ELSE NULL END
    ) AS pop_tohoku
  , SUM(
      CASE WHEN pref_name IN ('東京', '千葉') THEN population ELSE NULL END
    ) AS pop_konto
FROM (
  SELECT age_class, sex_cd
  FROM guide.tblage CROSS JOIN guide.tblsex) AS master
    LEFT JOIN guide.tblpop AS data
    ON master.age_class = data.age_class
      AND master.sex_cd = data.sex_cd
  GROUP BY
    master.age_class, master.sex_cd
;


/* 演習問題8-2 */
CREATE VIEW guide.children(child) AS SELECT child_1 FROM guide.personnel
UNION
SELECT child_2 FROM guide.personnel
UNION
SELECT child_3 FROM guide.personnel
;

SELECT
  emp.employee
  , COUNT(children.child) AS child_cnt
FROM
  guide.personnel AS emp
  LEFT JOIN guide.children
    ON children.child IN (emp.child_1, emp.child_2, emp.child_3)
GROUP BY
  emp.employee
;

/* 演習問題8-3 */
MERGE INTO guide.class_a AS c_a
  USING (SELECT * FROM guide.class_b) AS c_b
    ON (c_a.id = c_b.id)
  WHEN MATCHED THEN UPDATE SET c_a.name = c_b.name
  WHEN NOT MATCHED THEN INSERT (id, name) VALUES (c_b, c_b.name)
;

