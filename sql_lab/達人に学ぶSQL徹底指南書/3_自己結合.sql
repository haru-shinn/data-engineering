/* 自己結合 */

/* 重複順列・順列・組み合わせ */
CREATE TABLE guide.products (
  name VARCHAR(8) PRIMARY KEY
  , price INTEGER
);

INSERT INTO guide.products VALUES ('apple', 100);
INSERT INTO guide.products VALUES ('orange', 50);
INSERT INTO guide.products VALUES ('banana', 80);

-- 重複順列
SELECT
  p1.name AS name_1
  , p2.name AS name_2
FROM
  guide.products AS p1
  CROSS JOIN guide.products AS p2
;

-- 順列
SELECT
  p1.name AS name_1
  , p2.name AS name_2
FROM
  guide.products AS p1
  INNER JOIN guide.products AS p2
  ON p1.name <> p2.name
;

-- 組み合わせ
SELECT
  p1.name AS name_1
  , p2.name AS name_2
FROM
  guide.products AS p1
  INNER JOIN guide.products AS p2
  ON p1.name > p2.name
;

/* 自己非等値結合 */
DROP TABLE guide.products2;
CREATE TABLE guide.products2 (
  name VARCHAR(16) PRIMARY KEY
  , price INTEGER
);

INSERT INTO guide.products2 VALUES ('apple', 50);
INSERT INTO guide.products2 VALUES ('orange', 100);
INSERT INTO guide.products2 VALUES ('grapes', 50);
INSERT INTO guide.products2 VALUES ('watermelon', 80);
INSERT INTO guide.products2 VALUES ('lemon', 30);
INSERT INTO guide.products2 VALUES ('strawbery', 100);
INSERT INTO guide.products2 VALUES ('banana', 100);

-- 値段が同じ商品の組み合わせ
SELECT DISTINCT
  p1.name
  , p1.price
FROM
  guide.products2 AS p1 
  INNER JOIN guide.products2 AS p2
  ON p1.price = p2.price
  AND p1.name <> p2.name
ORDER BY
  p1.price
;

SELECT
  p1.name
  , p1.price
  , p2.name
  , p2.price
FROM
  guide.products2 AS p1 
  INNER JOIN guide.products2 AS p2
  ON p1.price = p2.price
  AND p1.name <> p2.name
ORDER BY
  p1.price
;

-- 相関サブクエリ
SELECT
  p1.name
  , p1.price
FROM
  guide.products2 AS p1
WHERE
  p1.price IN (SELECT p2.price FROM guide.products2 AS p2 WHERE p1.name <> p2.name)
;

/* 順位付け */
SELECT
  name
  , price
  , RANK() OVER(ORDER BY price DESC) AS rank_1
  , DENSE_RANK() OVER(ORDER BY price DESC) AS rank_2
FROM
  guide.products2
;

-- 相関サブクエリ
SELECT
  p1.name
  , p1.price
  , (SELECT COUNT(p2.price) FROM guide.products2 AS p2 WHERE p2.price > p1.price) + 1 AS rank_1
FROM
  guide.products2 AS p1
ORDER BY
  rank_1
;

-- 自己結合
SELECT
  p1.name
  , MAX(p1.price) AS price
  , COUNT(p2.name) + 1 AS rank_1
FROM
  guide.products2 AS p1
  LEFT JOIN guide.products2 AS p2
  ON p1.price < p2.price
GROUP BY
  p1.name
ORDER BY
  rank_1
;

/* 演習問題 */

/* 演習問題3-1 */
-- 重複組み合わせ
SELECT
  p1.name AS name_1
  , p2.name AS name_2
FROM
  guide.products AS p1
  INNER JOIN guide.products AS p2
  ON p1.name = p2.name OR p1.name > p2.name
;

-- ウインドウ関数で重複削除
DROP TABLE guide.products3;
CREATE TABLE guide.products3 (
  name VARCHAR(16)
  , price INTEGER
);

INSERT INTO guide.products3 VALUES ('apple', 50);
INSERT INTO guide.products3 VALUES ('orange', 100);
INSERT INTO guide.products3 VALUES ('orange', 100);
INSERT INTO guide.products3 VALUES ('orange', 100);
INSERT INTO guide.products3 VALUES ('banana', 80);

SELECT
  name
  , ROW_NUMBER() OVER(PARTITION BY name) AS row_id
FROM (
  SELECT name, ROW_NUMBER() OVER(PARTITION BY name) AS row_id
  FROM guide.products3
)
WHERE
  row_id = 1
;