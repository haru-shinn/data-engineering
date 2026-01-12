/* 数列 */

/* 空席確認 折り返しなし */
CREATE TABLE guide.seats (
  seat INTEGER NOT NULL PRIMARY KEY
  , status CHAR(2) NOT NULL
  CHECK (status IN ('空', '占'))
); 

INSERT INTO guide.seats VALUES (1, '占');
INSERT INTO guide.seats VALUES (2, '占');
INSERT INTO guide.seats VALUES (3, '空');
INSERT INTO guide.seats VALUES (4, '空');
INSERT INTO guide.seats VALUES (5, '空');
INSERT INTO guide.seats VALUES (6, '占');
INSERT INTO guide.seats VALUES (7, '空');
INSERT INTO guide.seats VALUES (8, '空');
INSERT INTO guide.seats VALUES (9, '空');
INSERT INTO guide.seats VALUES (10, '空');
INSERT INTO guide.seats VALUES (11, '空');
INSERT INTO guide.seats VALUES (12, '占');
INSERT INTO guide.seats VALUES (13, '占');
INSERT INTO guide.seats VALUES (14, '空');
INSERT INTO guide.seats VALUES (15, '空');

-- NOT EXISTS
SELECT
  *
FROM
  guide.seats AS s1
  , guide.seats AS s2
WHERE
  s2.seat = s1.seat + 2
  AND NOT EXISTS (
    SELECT *
    FROM guide.seats AS s3
    WHERE s3.seat BETWEEN s1.seat AND s2.seat
      AND s3.status <> '空'
  )
;

-- ウインドウ関数
WITH tmp AS (
  SELECT
    seat
    , MAX(seat) OVER(ORDER BY seat ROWS BETWEEN 2 FOLLOWING AND 2 FOLLOWING) AS end_seat
  FROM
    guide.seats
  WHERE
    status = '空'
)
SELECT * FROM tmp WHERE (end_seat - seat) = 2
;


/* 空席確認 折り返しあり */
CREATE TABLE guide.seats2 (
  seat INTEGER NOT NULL PRIMARY KEY
  , line_id CHAR(1) NOT NULL
  , status CHAR(2) NOT NULL
  CHECK (status IN ('空', '占')) 
); 

INSERT INTO guide.seats2 VALUES (1, 'A', '占');
INSERT INTO guide.seats2 VALUES (2, 'A', '占');
INSERT INTO guide.seats2 VALUES (3, 'A', '空');
INSERT INTO guide.seats2 VALUES (4, 'A', '空');
INSERT INTO guide.seats2 VALUES (5, 'A', '空');
INSERT INTO guide.seats2 VALUES (6, 'B', '占');
INSERT INTO guide.seats2 VALUES (7, 'B', '占');
INSERT INTO guide.seats2 VALUES (8, 'B', '空');
INSERT INTO guide.seats2 VALUES (9, 'B', '空');
INSERT INTO guide.seats2 VALUES (10,'B', '空');
INSERT INTO guide.seats2 VALUES (11,'C', '空');
INSERT INTO guide.seats2 VALUES (12,'C', '空');
INSERT INTO guide.seats2 VALUES (13,'C', '空');
INSERT INTO guide.seats2 VALUES (14,'C', '占');
INSERT INTO guide.seats2 VALUES (15,'C', '空');

-- NOT EXISTS
SELECT
  s1.seat AS start_seat, '~', s2.seat AS end_seat
FROM
  guide.seats2 AS s1, guide.seats2 AS s2
WHERE
  s2.seat = s1.seat + 2
  AND NOT EXISTS (
    SELECT *
    FROM guide.seats2 AS s3
    WHERE s3.seat BETWEEN s1.seat AND s2.seat
      AND (s3.status <> '空' OR s3.line_id <> s1.line_id)
  )
;

-- ウインドウ関数
SELECT
  seat, '~', seat + 2
FROM (
  SELECT
    seat
    , MAX(seat) OVER(PARTITION BY line_id ORDER BY seat
                      ROWS BETWEEN 2 FOLLOWING AND 2 FOLLOWING) AS end_seat
  FROM
    guide.seats2
  WHERE
    status = '空'
) AS tmp
WHERE
  (end_seat - seat) = 2
;


/* 単調増加と単調減少 */
CREATE TABLE guide.mystock (
  deal_date DATE PRIMARY KEY
  , price INTEGER 
); 

INSERT INTO guide.mystock VALUES ('2018-01-06', 1000);
INSERT INTO guide.mystock VALUES ('2018-01-08', 1050);
INSERT INTO guide.mystock VALUES ('2018-01-09', 1050);
INSERT INTO guide.mystock VALUES ('2018-01-12', 900);
INSERT INTO guide.mystock VALUES ('2018-01-13', 880);
INSERT INTO guide.mystock VALUES ('2018-01-14', 870);
INSERT INTO guide.mystock VALUES ('2018-01-16', 920);
INSERT INTO guide.mystock VALUES ('2018-01-17', 1000);
INSERT INTO guide.mystock VALUES ('2018-01-18', 2000);

WITH tmp AS (
  SELECT
    deal_date
    , price
    ,MAX(price) 
        OVER(ORDER BY deal_date
                        ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING) AS before_price
  FROM
    guide.mystock
)
SELECT
  deal_date
  , price
  , CASE 
      WHEN price - before_price > 0 THEN 'up'
      WHEN price - before_price < 0 THEN 'down'
      WHEN price - before_price = 0 THEN 'stay'
      ELSE NULL
    END AS diff
FROM
  tmp
;


/* 演習問題 */

/* 演習問題10-1 */
CREATE TABLE guide.seqtbl_miss_num(seq INTEGER PRIMARY KEY);
INSERT INTO guide.seqtbl_miss_num VALUES (1);
INSERT INTO guide.seqtbl_miss_num VALUES (2);
INSERT INTO guide.seqtbl_miss_num VALUES (4);
INSERT INTO guide.seqtbl_miss_num VALUES (5);
INSERT INTO guide.seqtbl_miss_num VALUES (6);
INSERT INTO guide.seqtbl_miss_num VALUES (7);
INSERT INTO guide.seqtbl_miss_num VALUES (8);
INSERT INTO guide.seqtbl_miss_num VALUES (11);
INSERT INTO guide.seqtbl_miss_num VALUES (12);

DROP TABLE guide.digit;
CREATE TABLE guide.digit (seq INTEGER PRIMARY KEY);
INSERT INTO guide.digit VALUES (0);
INSERT INTO guide.digit VALUES (1);
INSERT INTO guide.digit VALUES (2);
INSERT INTO guide.digit VALUES (3);
INSERT INTO guide.digit VALUES (4);
INSERT INTO guide.digit VALUES (5);
INSERT INTO guide.digit VALUES (6);
INSERT INTO guide.digit VALUES (7);
INSERT INTO guide.digit VALUES (8);
INSERT INTO guide.digit VALUES (9);

CREATE OR REPLACE VIEW guide.sequence_v (seq) AS
  SELECT d1.seq + (d2.seq*10) + (d3.seq*100)
  FROM guide.digit AS d1
    CROSS JOIN guide.digit AS d2
    CROSS JOIN guide.digit AS d3
;

/*
meom
1.EXCEPT --> 王道
2.NOT IN --> わかりやすい
3.NOT EXISTS --> NOT IN と同じ考え方
4.外部結合 --> 邪道
*/

-- EXCEPT
SELECT seq FROM guide.sequence_v WHERE seq BETWEEN 1 AND 12
EXCEPT
SELECT seq FROM guide.seqtbl_miss_num
;

-- NOT IN
SELECT
  seq
FROM
  guide.sequence_v
WHERE
  (seq BETWEEN 1 AND 12)
  AND seq NOT IN (SELECT seq FROM guide.seqtbl_miss_num)
;

-- NOT EXISTS
SELECT
  seq
FROM
  guide.sequence_v AS sv
WHERE
  seq BETWEEN 1 AND 12
  AND NOT EXISTS (
    SELECT *
    FROM guide.seqtbl_miss_num AS s
    WHERE sv.seq = s.seq
  )
;

-- 外部結合
SELECT sv.seq 
FROM guide.sequence_v AS sv
  LEFT JOIN guide.seqtbl_miss_num AS s
  ON sv.seq = s.seq
WHERE
  sv.seq BETWEEN 1 AND 12
  AND s.seq IS NULL
;


/* 演習問題10-2 */

-- 折り返しなし
-- NOT EXISTS (再掲)
SELECT
  s1.seat AS start_seat, '~', s2.seat AS end_seat
FROM
  guide.seats2 AS s1, guide.seats2 AS s2
WHERE
  s2.seat = s1.seat + 2
  AND NOT EXISTS (
    SELECT *
    FROM guide.seats2 AS s3
    WHERE s3.seat BETWEEN s1.seat AND s2.seat
      AND (s3.status <> '空' OR s3.line_id <> s1.line_id)
  )
;

-- 集合思考
SELECT
  s1.seat AS start_seat, '~', s2.seat AS end_seat
FROM
  guide.seats AS s1
  , guide.seats AS s2
  , guide.seats AS s3
WHERE
  s2.seat = s1.seat + 2
  AND s3.seat BETWEEN s1.seat AND s2.seat
GROUP BY
  s1.seat, s2.seat
HAVING
  COUNT(*) = SUM(CASE WHEN s3.status = '空' THEN 1 ELSE 0 END)
;

-- 折り返しあり
SELECT
  s1.seat AS start_seat, '~', s2.seat AS end_seat
FROM
  guide.seats2 AS s1
  , guide.seats2 AS s2
  , guide.seats2 AS s3
WHERE
  s2.seat = s1.seat + 2
  AND s3.seat BETWEEN s1.seat AND s2.seat
GROUP BY
  s1.seat, s2.seat
HAVING
  COUNT(*) = SUM(CASE WHEN s3.status = '空' AND s3.line_id = s1.line_id THEN 1 ELSE 0 END)
;


