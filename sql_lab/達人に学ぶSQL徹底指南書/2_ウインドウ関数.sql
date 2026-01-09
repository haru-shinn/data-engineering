/* ウインドウ関数 */

/* 行間比較 */
CREATE TABLE guide.loadsample (
  sample_date DATE PRIMARY KEY
  , load_val INTEGER
);
INSERT INTO guide.loadsample VALUES ('2018-02-01', 1024);
INSERT INTO guide.loadsample VALUES ('2018-02-02', 2366);
INSERT INTO guide.loadsample VALUES ('2018-02-05', 2366);
INSERT INTO guide.loadsample VALUES ('2018-02-07', 985);
INSERT INTO guide.loadsample VALUES ('2018-02-08', 780);
INSERT INTO guide.loadsample VALUES ('2018-02-12', 1000);

SELECT
  sample_date AS cur_date
  , MIN(sample_date) OVER(ORDER BY sample_date ASC ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING) AS latest_1
  , MIN(sample_date) OVER(ORDER BY sample_date ASC ROWS BETWEEN 2 PRECEDING AND 2 PRECEDING) AS latest_2
  , MIN(sample_date) OVER(ORDER BY sample_date ASC ROWS BETWEEN 3 PRECEDING AND 3 PRECEDING) AS latest_3
FROM
  guide.loadsample
;

/* 列の値に基づいたフレームの設定 */
SELECT
  sample_date AS cur_date
  , load_val AS cur_load
  , MIN(sample_date) OVER(ORDER BY sample_date ASC RANGE BETWEEN interval '1' day PRECEDING AND interval '1' day PRECEDING) AS day1_before
  , MIN(load_val) OVER(ORDER BY sample_date ASC RANGE BETWEEN interval '1' day PRECEDING AND interval '1' day PRECEDING) AS load_day1_before
FROM
  guide.loadsample
;

/* ウインドウ関数の内部動作 */
-- PRIMARY KEY 指定しているためか、Index Scan しておりSortしていない。
EXPLAIN ANALYSE
SELECT
  sample_date AS cur_date
  , AVG(load_val) OVER(ORDER BY sample_date ASC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg
FROM
  guide.loadsample
;

/* 演習問題 */

/* 演習問題2-1 */
-- ウインドウ関数の結果予想 その１
CREATE TABLE guide.serverloadsample(
  server VARCHAR(3) NOT NULL
  , sample_date DATE NOT NULL
  , load_val INTEGER NOT NULL
);

INSERT INTO guide.serverloadsample VALUES('A', '2018-02-01', 1024);
INSERT INTO guide.serverloadsample VALUES('A', '2018-02-02', 2366);
INSERT INTO guide.serverloadsample VALUES('A', '2018-02-05', 2366);
INSERT INTO guide.serverloadsample VALUES('A', '2018-02-07', 985);
INSERT INTO guide.serverloadsample VALUES('A', '2018-02-08', 780);
INSERT INTO guide.serverloadsample VALUES('A', '2018-02-12', 1000);
INSERT INTO guide.serverloadsample VALUES('B', '2018-02-01', 54);
INSERT INTO guide.serverloadsample VALUES('B', '2018-02-02', 39008);
INSERT INTO guide.serverloadsample VALUES('B', '2018-02-03', 2900);
INSERT INTO guide.serverloadsample VALUES('B', '2018-02-04', 556);
INSERT INTO guide.serverloadsample VALUES('B', '2018-02-05', 12600);
INSERT INTO guide.serverloadsample VALUES('B', '2018-02-06', 7309);
INSERT INTO guide.serverloadsample VALUES('C', '2018-02-01', 1000);
INSERT INTO guide.serverloadsample VALUES('C', '2018-02-07', 2000);
INSERT INTO guide.serverloadsample VALUES('C', '2018-02-16', 500);

SELECT
  server
  , sample_date
  , SUM(load_val) OVER() AS sum_load
FROM
  guide.serverloadsample
;

-- ウインドウ関数の結果予想 その２
SELECT
  server
  , sample_date
  , SUM(load_val) OVER(PARTITION BY server) AS sum_load
FROM
  guide.serverloadsample
;
