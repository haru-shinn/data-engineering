/* ウインドウ関数 */

/* オーバラップ期間 */
DROP TABLE IF EXISTS guide.reservations;
CREATE TABLE guide.reservations (
  reserver VARCHAR(16) PRIMARY KEY
  , start_date DATE
  , end_date DATE
);
INSERT INTO guide.reservations VALUES ('kimura', '2018-10-26', '2018-10-27');
INSERT INTO guide.reservations VALUES ('araki', '2018-10-28', '2018-10-31');
INSERT INTO guide.reservations VALUES ('hori', '2018-10-31', '2018-11-01');
INSERT INTO guide.reservations VALUES ('yamamoto', '2018-11-03', '2018-11-04');
INSERT INTO guide.reservations VALUES ('uchida', '2018-11-03', '2018-11-05');
INSERT INTO guide.reservations VALUES ('mizuya', '2018-11-06', '2018-11-06');

-- 相関サブクエリ
SELECT
  r1.reserver
  , r1.start_date
  , r1.end_date  
FROM
  guide.reservations AS r1
WHERE
  EXISTS (
    SELECT
      *
    FROM
      guide.reservations AS r2
    WHERE
      r1.reserver <> r2.reserver
      AND (r1.start_date BETWEEN r2.start_date AND r2.end_date
          OR r1.end_date BETWEEN r2.start_date AND r2.end_date)
  )
;

-- ウインドウ関数
WITH duplicate AS (
  SELECT
    reserver
    , start_date
    , end_date 
    , MAX(start_date) OVER(ORDER BY start_date ROWS BETWEEN 1 FOLLOWING AND 1 FOLLOWING) AS next_start_date
    , MAX(end_date) OVER(ORDER BY end_date ROWS BETWEEN 1 FOLLOWING AND 1 FOLLOWING) AS next_end_date
    , MAX(reserver) OVER(ORDER BY start_date ROWS BETWEEN 1 FOLLOWING AND 1 FOLLOWING) AS next_reserver
  FROM
    guide.reservations
)
SELECT
  reserver
  , next_reserver
FROM
  duplicate
WHERE
  next_start_date BETWEEN start_date AND end_date
;

-- ３人が重複しているVer（クエリは上記を利用）
INSERT INTO guide.reservations VALUES ('kimura', '2018-10-26', '2018-10-27');
INSERT INTO guide.reservations VALUES ('araki', '2018-10-28', '2018-10-31');
INSERT INTO guide.reservations VALUES ('hori', '2018-10-31', '2018-11-01');
INSERT INTO guide.reservations VALUES ('yamamoto', '2018-11-03', '2018-11-04');
INSERT INTO guide.reservations VALUES ('uchida', '2018-11-03', '2018-11-05');
INSERT INTO guide.reservations VALUES ('mizuya', '2018-11-04', '2018-11-06');


/* 演習問題 */

/* 演習問題7-1 */
DROP TABLE IF EXISTS guide.accounts;
CREATE TABLE guide.accounts (
  prc_date DATE PRIMARY KEY
  , prc_amt INTEGER
);
INSERT INTO guide.accounts VALUES ('2018-10-26', 12000);
INSERT INTO guide.accounts VALUES ('2018-10-28', 2500);
INSERT INTO guide.accounts VALUES ('2018-10-31', -15000);
INSERT INTO guide.accounts VALUES ('2018-11-03', 34000);
INSERT INTO guide.accounts VALUES ('2018-11-04', -5000);
INSERT INTO guide.accounts VALUES ('2018-11-06', 7200);
INSERT INTO guide.accounts VALUES ('2018-11-11', 11000);

-- ウインドウ関数
SELECT
  prc_date
  , prc_amt
  , AVG(prc_amt) OVER(ORDER BY prc_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) avg_amt
FROM
  guide.accounts
;

-- 相関サブクエリ
SELECT
  a1.prc_date
  , a1.prc_amt
  , (SELECT AVG(a2.prc_amt)
      FROM guide.accounts AS a2
      WHERE a1.prc_date >= a2.prc_date
        AND (SELECT COUNT(*)
              FROM guide.accounts AS a3
              WHERE a3.prc_date BETWEEN a2.prc_date AND a1.prc_date) <= 3) AS mvg_sum
FROM
  guide.accounts AS a1
;

/* 演習問題7-2 */
-- ウインドウ関数
SELECT
  prc_date
  , prc_amt
  , CASE
      WHEN cnt < 3 THEN NULL
      ELSE mvg_avg
    END as mvg_avg
FROM (
  SELECT
    prc_date
    , prc_amt
    , AVG(prc_amt) OVER(ORDER BY prc_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS mvg_avg
    , COUNT(*) OVER(ORDER BY prc_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS cnt
  FROM
    guide.accounts
) AS tmp
;



-- 相関サブクエリ
SELECT
  a1.prc_date
  , a1.prc_amt
  , (SELECT AVG(a2.prc_amt)
      FROM guide.accounts AS a2
      WHERE a1.prc_date >= a2.prc_date
        AND (SELECT COUNT(*)
              FROM guide.accounts AS a3
              WHERE a3.prc_date BETWEEN a2.prc_date AND a1.prc_date) <= 3
              HAVING COUNT(*) = 3) AS mvg_sum
FROM
  guide.accounts AS a1
ORDER BY
  prc_date
;
