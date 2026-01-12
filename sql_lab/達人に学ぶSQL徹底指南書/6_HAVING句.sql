/* HAVING句 */

/* 歯抜けのデータ */
DROP TABLE IF EXISTS guide.seqtbl;
CREATE TABLE guide.seqtbl (
  seq INTEGER PRIMARY KEY
  , name VARCHAR(16)
);
INSERT INTO guide.seqtbl VALUES (1, 'dick');
INSERT INTO guide.seqtbl VALUES (2, 'ann');
INSERT INTO guide.seqtbl VALUES (3, 'rile');
INSERT INTO guide.seqtbl VALUES (5, 'car');
INSERT INTO guide.seqtbl VALUES (6, 'marry');
INSERT INTO guide.seqtbl VALUES (8, 'benn');

SELECT
  '歯抜けあり' AS gap
FROM
  guide.seqtbl
HAVING
  COUNT(*) <> MAX(seq)
;

SELECT
  '歯抜けあり' AS gap
FROM
  guide.seqtbl
HAVING
  COUNT(*) <> (MAX(seq) - MIN(seq) + 1)
;

SELECT
  CASE
    WHEN COUNT(*) = 0 OR MIN(seq) > 1 THEN 1
    ELSE (SELECT MIN(seq + 1)
          FROM guide.seqtbl AS s1
          WHERE NOT EXISTS (SELECT *
                            FROM guide.seqtbl AS s2
                            WHERE s2.seq = s1.seq + 1)) END
FROM
  guide.seqtbl
;

/* HAVING句でサブクエリ */
DROP TABLE IF EXISTS guide.graduates;
CREATE TABLE guide.graduates(
  name VARCHAR(16) PRIMARY KEY
  , income INTEGER NOT NULL
);

INSERT INTO guide.graduates VALUES('サンプソン', 400000);
INSERT INTO guide.graduates VALUES('マイク',     30000);
INSERT INTO guide.graduates VALUES('ホワイト',   20000);
INSERT INTO guide.graduates VALUES('アーノルド', 20000);
INSERT INTO guide.graduates VALUES('スミス',     20000);
INSERT INTO guide.graduates VALUES('ロレンス',   15000);
INSERT INTO guide.graduates VALUES('ハドソン',   15000);
INSERT INTO guide.graduates VALUES('ケント',     10000);
INSERT INTO guide.graduates VALUES('ベッカー',   10000);
INSERT INTO guide.graduates VALUES('スコット',   10000);

SELECT
  income
  , COUNT(*) AS cnt
FROM
  guide.graduates
GROUP BY
  income
HAVING
  COUNT(*) >= ALL(SELECT COUNT(*) FROM guide.graduates GROUP BY income)
;

SELECT
  income
  , COUNT(*) AS cnt
FROM
  guide.graduates
GROUP BY
  income
HAVING
  COUNT(*) >= (SELECT MAX(cnt)
              FROM (SELECT COUNT(*) AS cnt 
                    FROM guide.graduates
                    GROUP BY income) AS tmp)
;

-- 未提出者
CREATE TABLE guide.students_submit (
  student_id INTEGER PRIMARY KEY
  , dpt VARCHAR(16) NOT NULL
  , sbmt_date DATE
);

INSERT INTO guide.students_submit VALUES(100, '理学部', '2018-10-10');
INSERT INTO guide.students_submit VALUES(101, '理学部', '2018-09-22');
INSERT INTO guide.students_submit VALUES(102, '文学部', NULL);
INSERT INTO guide.students_submit VALUES(103, '文学部', '2018-09-10');
INSERT INTO guide.students_submit VALUES(200, '文学部', '2018-09-22');
INSERT INTO guide.students_submit VALUES(201, '工学部', NULL);
INSERT INTO guide.students_submit VALUES(202, '経済学部', '2018-09-25');

SELECT
  dpt
FROM
  guide.students_submit
GROUP BY
  dpt
HAVING
  COUNT(*) = COUNT(sbmt_date)
;

-- 特性関数
CREATE TABLE guide.testresults (
  student_id CHAR(12) NOT NULL PRIMARY KEY
  , class CHAR(1) NOT NULL
  , sex CHAR(1) NOT NULL
  , score INTEGER NOT NULL
);

INSERT INTO guide.testresults VALUES('001', 'A', '男', 100);
INSERT INTO guide.testresults VALUES('002', 'A', '女', 100);
INSERT INTO guide.testresults VALUES('003', 'A', '女', 49);
INSERT INTO guide.testresults VALUES('004', 'A', '男', 30);
INSERT INTO guide.testresults VALUES('005', 'B', '女', 100);
INSERT INTO guide.testresults VALUES('006', 'B', '男', 92);
INSERT INTO guide.testresults VALUES('007', 'B', '男', 80);
INSERT INTO guide.testresults VALUES('008', 'B', '男', 80);
INSERT INTO guide.testresults VALUES('009', 'B', '女', 10);
INSERT INTO guide.testresults VALUES('010', 'C', '男', 92);
INSERT INTO guide.testresults VALUES('011', 'C', '男', 80);
INSERT INTO guide.testresults VALUES('012', 'C', '女', 21);
INSERT INTO guide.testresults VALUES('013', 'D', '女', 100);
INSERT INTO guide.testresults VALUES('014', 'D', '女', 0);
INSERT INTO guide.testresults VALUES('015', 'D', '女', 0);

-- 80点以上とった生徒がクラスの75%以上を求める
SELECT
  class
FROM
  (SELECT 
    class
    , SUM((CASE WHEN score >= 80 THEN 1 ELSE 0 END)) AS cnt
    , COUNT(score) AS cnt_total
    FROM guide.testresults 
    GROUP BY class)
WHERE
  (CAST(cnt AS FLOAT) / cnt_total) >= 0.75
;

SELECT
  class
FROM
  guide.testresults
GROUP BY
  class
HAVING
  COUNT(*) * 0.75 <= SUM((CASE WHEN score >= 80 THEN 1 ELSE 0 END))
;

-- 50点以上取った生徒のうち、男子の数が女子の数より多いクラス
SELECT
  class
FROM
  guide.testresults
GROUP BY
  class
HAVING
  SUM(CASE WHEN sex = '男' AND score >= 50 THEN 1 ELSE 0 END)
  > SUM(CASE WHEN sex = '女' AND score >= 50 THEN 1 ELSE 0 END)
;

-- 女子の平均点が男子の平均点より高いクラス
SELECT
  class
FROM
  guide.testresults
GROUP BY
  class
HAVING
  AVG(CASE WHEN sex = '男' THEN score ELSE 0 END)
  < AVG(CASE WHEN sex = '女' THEN score ELSE 0 END)
  AND SUM(CASE WHEN sex = '男' THEN 1 ELSE 0 END) >= 1
  AND SUM(CASE WHEN sex = '女' THEN 1 ELSE 0 END) >= 1
;

SELECT
  class
FROM
  guide.testresults
GROUP BY
  class
HAVING
  AVG(CASE WHEN sex = '男' THEN score ELSE NULL END)
  < AVG(CASE WHEN sex = '女' THEN score ELSE NULL END)
;

/* HAVING句で全称量化 */
CREATE TABLE guide.teams (
  member CHAR(12) NOT NULL PRIMARY KEY
  , team_id INTEGER NOT NULL
  , status CHAR(8) NOT NULL
);

INSERT INTO guide.teams VALUES('ジョー', 1, '待機');
INSERT INTO guide.teams VALUES('ケン', 1, '出動中');
INSERT INTO guide.teams VALUES('ミック', 1, '待機');
INSERT INTO guide.teams VALUES('カレン', 2, '出動中');
INSERT INTO guide.teams VALUES('キース', 2, '休暇');
INSERT INTO guide.teams VALUES('ジャン', 3, '待機');
INSERT INTO guide.teams VALUES('ハート', 3, '待機');
INSERT INTO guide.teams VALUES('ディック', 3, '待機');
INSERT INTO guide.teams VALUES('ベス', 4, '待機');
INSERT INTO guide.teams VALUES('アレン', 5, '出動中');
INSERT INTO guide.teams VALUES('ロバート', 5, '休暇');
INSERT INTO guide.teams VALUES('ケーガン', 5, '待機');

-- NOT EXISTS
/*
memo
各チーム単位で全員が待機中であるチームを探したい
→ 待機中以外のステータスの人が一人もいない
→ WHERE NOT EXISTS () の中から、全員待機中の場合はTRUEが返ってくる。
　NOT EXISTS () 内で該当しない条件を定義して、それが見つからなかったレコードだけパスする。
*/
SELECT
  t1.team_id
  , t1.member
FROM
  guide.teams AS t1
WHERE
  NOT EXISTS (
    SELECT *
    FROM guide.teams AS t2
    WHERE t1.team_id = t2.team_id
      AND t2.status <> '待機'
  )
;

SELECT
  team_id
FROM
  guide.teams
GROUP BY
  team_id
HAVING
  COUNT(*) = SUM(CASE WHEN status = '待機' THEN 1 ELSE 0 END)
;

/* 一意集合と多重集合 */
/*
memo
リレーショナルデータベースは重複値を認める
集合論は重複値を認めない
*/
CREATE TABLE guide.materials (
  center CHAR(12) NOT NULL
  , receive_date DATE NOT NULL
  , material CHAR(12) NOT NULL
  , PRIMARY KEY(center, receive_date)
);

INSERT INTO guide.materials VALUES('東京' ,'2018-4-01', '錫');
INSERT INTO guide.materials VALUES('東京' ,'2018-4-12', '亜鉛');
INSERT INTO guide.materials VALUES('東京' ,'2018-5-17', 'アルミニウム');
INSERT INTO guide.materials VALUES('東京' ,'2018-5-20', '亜鉛');
INSERT INTO guide.materials VALUES('大阪' ,'2018-4-20', '銅');
INSERT INTO guide.materials VALUES('大阪' ,'2018-4-22', 'ニッケル');
INSERT INTO guide.materials VALUES('大阪' ,'2018-4-29', '鉛');
INSERT INTO guide.materials VALUES('名古屋', '2018-3-15', 'チタン');
INSERT INTO guide.materials VALUES('名古屋', '2018-4-01', '炭素鋼');
INSERT INTO guide.materials VALUES('名古屋', '2018-4-24', '炭素鋼');
INSERT INTO guide.materials VALUES('名古屋', '2018-5-02', 'マグネシウム');
INSERT INTO guide.materials VALUES('名古屋', '2018-5-10', 'チタン');
INSERT INTO guide.materials VALUES('福岡' ,'2018-5-10', '亜鉛');
INSERT INTO guide.materials VALUES('福岡' ,'2018-5-28', '錫');

SELECT
  center
FROM
  guide.materials
GROUP BY
  center
HAVING
  COUNT(material) > COUNT(DISTINCT material)
;

SELECT
  center
  , material
FROM
  guide.materials AS m1
WHERE
  EXISTS (SELECT *
          FROM guide.materials AS m2
          WHERE
            m1.center = m2.center
            AND m1.receive_date <> m2.receive_date
            AND m1.material = m2.material)
;

/* 関係除算でバスケット解析 */
CREATE TABLE guide.items (
  item VARCHAR(16) PRIMARY KEY
);
 
CREATE TABLE guide.shopitems(
  shop VARCHAR(16)
  , item VARCHAR(16)
  , PRIMARY KEY(shop, item)
);

INSERT INTO guide.items VALUES('ビール');
INSERT INTO guide.items VALUES('紙オムツ');
INSERT INTO guide.items VALUES('自転車');

INSERT INTO guide.shopitems VALUES('仙台','ビール');
INSERT INTO guide.shopitems VALUES('仙台','紙オムツ');
INSERT INTO guide.shopitems VALUES('仙台','自転車');
INSERT INTO guide.shopitems VALUES('仙台','カーテン');
INSERT INTO guide.shopitems VALUES('東京','ビール');
INSERT INTO guide.shopitems VALUES('東京','紙オムツ');
INSERT INTO guide.shopitems VALUES('東京','自転車');
INSERT INTO guide.shopitems VALUES('大阪','テレビ');
INSERT INTO guide.shopitems VALUES('大阪','紙オムツ');
INSERT INTO guide.shopitems VALUES('大阪','自転車');


SELECT
  si.shop
FROM
  guide.shopitems AS si
  INNER JOIN guide.items AS i
  ON i.item = si.item
GROUP BY
  si.shop
HAVING
  COUNT(si.item) =
  (SELECT COUNT(item) FROM guide.items)
;

SELECT
  si.shop
FROM
  guide.shopitems AS si
  LEFT JOIN guide.items AS i
  ON si.item = i.item
GROUP BY
  si.shop
HAVING
  COUNT(si.item) = (SELECT COUNT(item) FROM guide.items)
  AND COUNT(i.item) = (SELECT COUNT(item) FROM guide.items)
;

/* 演習問題 */

/* 演習問題6-1 */
SELECT
  CASE
    WHEN COUNT(*) <> MAX(seq) THEN '歯抜けあり'
    ELSE '歯抜けなし'
  END AS gap
FROM
  guide.seqtbl
;

/* 演習問題6-2 */
SELECT
  dpt
FROM
  guide.students_submit AS s1
GROUP BY
  dpt
HAVING
  COUNT(*) = COUNT(sbmt_date)
  AND NOT EXISTS (SELECT * FROM guide.students_submit AS s2
                  WHERE 
                    s1.dpt = s2.dpt
                    AND SUBSTRING(CAST(sbmt_date AS VARCHAR), 6, 2) <> '09')
;


/* 演習問題6-3 */
SELECT
  si.shop
  , COUNT(si.item) AS my_item_cnt
  , (SELECT COUNT(item) FROM guide.items) - COUNT(si.item) AS diff_cnt
FROM
  guide.shopitems AS si INNER JOIN guide.items AS i
  ON si.item = i.item
GROUP BY
  si.shop
;