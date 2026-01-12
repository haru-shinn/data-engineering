/* 集合演算 */

/* テーブル同士のコンペア（集合の相等性チェック）基礎編 */
-- データが同じ
CREATE TABLE guide.tbl_a (
  key CHAR(1) PRIMARY kEY
  , col_1 INTEGER
  , col_2 INTEGER
  , col_3 INTEGER
);
CREATE TABLE guide.tbl_b (
  key CHAR(1) PRIMARY kEY
  , col_1 INTEGER
  , col_2 INTEGER
  , col_3 INTEGER
);
INSERT INTO guide.tbl_a VALUES ('A', 2, 3, 4);
INSERT INTO guide.tbl_a VALUES ('B', 0, 7, 9);
INSERT INTO guide.tbl_a VALUES ('C', 5, 1, 6);
INSERT INTO guide.tbl_b VALUES ('A', 2, 3, 4);
INSERT INTO guide.tbl_b VALUES ('B', 0, 7, 9);
INSERT INTO guide.tbl_b VALUES ('C', 5, 1, 6);

SELECT
  COUNT(*) AS row_cnt
FROM (
  SELECT * FROM guide.tbl_a
  UNION
  SELECT * FROM guide.tbl_b
) AS tmp;

-- データが違う場合
TRUNCATE guide.tbl_a;
TRUNCATE guide.tbl_b;

INSERT INTO guide.tbl_a VALUES ('A', 2, 3, 4);
INSERT INTO guide.tbl_a VALUES ('B', 0, 7, 9);
INSERT INTO guide.tbl_a VALUES ('C', 5, 1, 6);
INSERT INTO guide.tbl_b VALUES ('A', 2, 3, 4);
INSERT INTO guide.tbl_b VALUES ('B', 0, 7, 8);
INSERT INTO guide.tbl_b VALUES ('C', 5, 1, 6);
-- クエリは上記を利用する。


/* テーブル同士のコンペア（集合の相等性チェック）応用編 */
SELECT
  CASE
    WHEN COUNT(*) = 0 THEN '等しい'
    ELSE '異なる'
  END AS result
FROM (
  (SELECT * FROM guide.tbl_a UNION SELECT * FROM guide.tbl_b)
  EXCEPT
  (SELECT * FROM guide.tbl_a INTERSECT SELECT * FROM guide.tbl_b)
) AS tmp;

(SELECT * FROM guide.tbl_a EXCEPT SELECT * FROM guide.tbl_b)
UNION ALL
(SELECT * FROM guide.tbl_b EXCEPT SELECT * FROM guide.tbl_a)
;


/* 差集合で関係除算 */
CREATE TABLE guide.skills (
  skill VARCHAR(32)
  , PRIMARY KEY(skill)
);

CREATE TABLE guide.empskills (
  emp VARCHAR(32)
  , skill VARCHAR(32)
  , PRIMARY KEY(emp, skill)
);

INSERT INTO guide.skills VALUES('Oracle');
INSERT INTO guide.skills VALUES('UNIX');
INSERT INTO guide.skills VALUES('Java');

INSERT INTO guide.empskills VALUES('相田', 'Oracle');
INSERT INTO guide.empskills VALUES('相田', 'UNIX');
INSERT INTO guide.empskills VALUES('相田', 'Java');
INSERT INTO guide.empskills VALUES('相田', 'C#');
INSERT INTO guide.empskills VALUES('神崎', 'Oracle');
INSERT INTO guide.empskills VALUES('神崎', 'UNIX');
INSERT INTO guide.empskills VALUES('神崎', 'Java');
INSERT INTO guide.empskills VALUES('平井', 'UNIX');
INSERT INTO guide.empskills VALUES('平井', 'Oracle');
INSERT INTO guide.empskills VALUES('平井', 'PHP');
INSERT INTO guide.empskills VALUES('平井', 'Perl');
INSERT INTO guide.empskills VALUES('平井', 'C++');
INSERT INTO guide.empskills VALUES('若田部', 'Perl');
INSERT INTO guide.empskills VALUES('渡来', 'Oracle');

-- 差集合で関係除算
SELECT DISTINCT
  emp
FROM
  guide.empskills AS es1
WHERE
  NOT EXISTS (
    SELECT skill FROM guide.skills
    EXCEPT
    SELECT skill FROM guide.empskills AS es2
    WHERE es1.emp = es2.emp
  );



/* 等しい部分集合を見つける */
CREATE TABLE guide.supparts (
  sup CHAR(32) NOT NULL
  , part CHAR(32) NOT NULL
  , PRIMARY KEY(sup, part)
);

INSERT INTO guide.supparts VALUES('A', 'ボルト');
INSERT INTO guide.supparts VALUES('A', 'ナット');
INSERT INTO guide.supparts VALUES('A', 'パイプ');
INSERT INTO guide.supparts VALUES('B', 'ボルト');
INSERT INTO guide.supparts VALUES('B', 'パイプ');
INSERT INTO guide.supparts VALUES('C', 'ボルト');
INSERT INTO guide.supparts VALUES('C', 'ナット');
INSERT INTO guide.supparts VALUES('C', 'パイプ');
INSERT INTO guide.supparts VALUES('D', 'ボルト');
INSERT INTO guide.supparts VALUES('D', 'パイプ');
INSERT INTO guide.supparts VALUES('E', 'ヒューズ');
INSERT INTO guide.supparts VALUES('E', 'ナット');
INSERT INTO guide.supparts VALUES('E', 'パイプ');
INSERT INTO guide.supparts VALUES('F', 'ヒューズ');

SELECT
  sp1.sup AS s1
  , sp2.sup AS s2
FROM
  guide.supparts AS sp1, guide.supparts AS sp2
WHERE
  sp1.sup < sp2.sup
  AND sp1.part = sp2.part
GROUP BY
  sp1.sup, sp2.sup
HAVING
  COUNT(*) = (
    SELECT COUNT(*) 
    FROM guide.supparts AS sp3
    WHERE sp3.sup = sp1.sup
  )
  AND COUNT(*) = (
    SELECT COUNT(*)
    FROM guide.supparts AS sp4
    WHERE sp4.sup = sp2.sup
  )
;


/* 演習問題 */

/* 演習問題9-1 */
SELECT
  CASE
    WHEN COUNT(*) = (SELECT COUNT(*) FROM guide.tbl_a) 
      AND COUNT(*) = (SELECT COUNT(*) FROM guide.tbl_b)
    THEN '等しい'
    ELSE '異なる'
  END AS result
FROM (
  SELECT * FROM guide.tbl_a
  UNION
  SELECT * FROM guide.tbl_b
) AS tmp;


/* 演習問題9-2 */
SELECT DISTINCT emp
FROM guide.empskills AS es1
WHERE NOT EXISTS (
  SELECT skill FROM guide.skills
  EXCEPT
  SELECT skill FROM guide.empskills AS es2
  WHERE es1.emp = es2.emp
)
AND NOT EXISTS (
  SELECT skill FROM guide.empskills AS es3
  WHERE es1.emp = es3.emp
  EXCEPT
  SELECT skill FROM guide.skills
)
;

