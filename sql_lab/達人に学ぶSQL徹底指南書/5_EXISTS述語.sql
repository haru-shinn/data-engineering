/* EXISTS述語 */

/*
memo
量化子（限量子、数量詞）
全称量化子: 「すべてのxが条件Pを満たす」 --> SQLには存在しない
存在量化子: 「条件Pを満たすxが少なくとも１つ存在する」 --> EXISTS
*/

/* テーブルに存在しないデータを探す */
DROP TABLE IF EXISTS guide.meetings;
CREATE TABLE guide.meetings (
  meeting VARCHAR(8)
  , person VARCHAR(12)
  , PRIMARY KEY (meeting, person)
);
INSERT INTO guide.meetings VALUES ('first', 'ito');
INSERT INTO guide.meetings VALUES ('first', 'mizushima');
INSERT INTO guide.meetings VALUES ('first', 'bando');
INSERT INTO guide.meetings VALUES ('second', 'ito');
INSERT INTO guide.meetings VALUES ('second', 'miyata');
INSERT INTO guide.meetings VALUES ('third', 'bando');
INSERT INTO guide.meetings VALUES ('third', 'mizushima');
INSERT INTO guide.meetings VALUES ('third', 'miyata');

SELECT DISTINCT
  m1.meeting
  , m2.person
FROM
  guide.meetings AS m1 -- 存在するすべてのmeetingのリストを取得
  CROSS JOIN guide.meetings AS m2 -- 存在するすべてのpersonのリストを取得
WHERE
  NOT EXISTS (SELECT *
              FROM guide.meetings AS m3 -- 「実際に誰がどの会議に出席したか」の現実のデータ
              WHERE m1.meeting = m3.meeting
              AND m2.person = m3.person)
;

/* 全称量化 肯定↔二重否定の変換 */
DROP TABLE IF EXISTS guide.testscores;
CREATE TABLE guide.testscores (
  student_id VARCHAR(3)
  , subject VARCHAR(8)
  , score INTEGER
  , PRIMARY KEY (student_id, subject)
);
INSERT INTO guide.testscores VALUES ('100', 'math', 100);
INSERT INTO guide.testscores VALUES ('100', 'japanese', 80);
INSERT INTO guide.testscores VALUES ('100', 'science', 80);
INSERT INTO guide.testscores VALUES ('200', 'math', 80);
INSERT INTO guide.testscores VALUES ('200', 'japanese', 95);
INSERT INTO guide.testscores VALUES ('300', 'math', 40);
INSERT INTO guide.testscores VALUES ('300', 'japanese', 90);
INSERT INTO guide.testscores VALUES ('300', 'social', 55);
INSERT INTO guide.testscores VALUES ('400', 'math', 80);

SELECT DISTINCT
  student_id
FROM
  guide.testscores AS t1
WHERE
  NOT EXISTS (
    SELECT *
    FROM guide.testscores AS t2
    WHERE t1.student_id = t2.student_id
    AND t2.score < 50
  );

SELECT DISTINCT
  student_id
FROM
  guide.testscores AS ts1
WHERE
  ts1.subject IN ('math', 'japanese')
  AND
  NOT EXISTS (
    SELECT *
    FROM guide.testscores AS ts2
    WHERE
      ts1.student_id = ts2.student_id
      AND 1 = 
        (CASE 
          WHEN ts2.subject = 'math' AND ts2.score < 80 THEN 1
          WHEN ts2.subject = 'japanese' AND ts2.score < 50 THEN 1
          ELSE 0
        END)
  );

SELECT
  student_id
FROM
  guide.testscores AS ts1
WHERE
  ts1.subject IN ('math', 'japanese')
  AND
  NOT EXISTS (
    SELECT *
    FROM guide.testscores AS ts2
    WHERE
      ts1.student_id = ts2.student_id
      AND 1 = 
        (CASE 
          WHEN ts2.subject = 'math' AND ts2.score < 80 THEN 1
          WHEN ts2.subject = 'japanese' AND ts2.score < 50 THEN 1
          ELSE 0
        END)
  )
  GROUP BY ts1.student_id
  HAVING COUNT(*) = 2
  ;

/* 全称量化 集合vs述語 */
DROP TABLE IF EXISTS guide.projects;
CREATE TABLE guide.projects (
  project_id VARCHAR(8)
  , step_nbr INTEGER
  , status VARCHAR(16)
  , PRIMARY KEY (project_id, step_nbr)
);
INSERT INTO guide.projects VALUES('AA100', 0, 'completed');
INSERT INTO guide.projects VALUES('AA100', 1, 'wait');
INSERT INTO guide.projects VALUES('AA100', 2, 'wait');
INSERT INTO guide.projects VALUES('B200',  0, 'wait');
INSERT INTO guide.projects VALUES('B200',  1, 'wait');
INSERT INTO guide.projects VALUES('CS300', 0, 'completed');
INSERT INTO guide.projects VALUES('CS300', 1, 'completed');
INSERT INTO guide.projects VALUES('CS300', 2, 'wait');
INSERT INTO guide.projects VALUES('CS300', 3, 'wait');
INSERT INTO guide.projects VALUES('DY400', 0, 'completed');
INSERT INTO guide.projects VALUES('DY400', 1, 'completed');
INSERT INTO guide.projects VALUES('DY400', 2, 'completed');

SELECT
  project_id
FROM
  guide.projects
GROUP BY
  project_id
HAVING
  COUNT(*) = SUM(CASE 
        WHEN step_nbr IN (0, 1) AND status = 'completed' THEN 1
        WHEN step_nbr > 1 AND status = 'wait' THEN 1
        ELSE 0 END)
;

SELECT
  *
FROM
  guide.projects AS p1
WHERE
  NOT EXISTS (
    SELECT status
    FROM guide.projects AS p2
    WHERE p1.project_id = p2.project_id
      AND status <> CASE WHEN step_nbr <= 1 THEN 'completed' ELSE 'wait' END)
;


/* 演習問題 */

/* 演習問題5-1 */
CREATE TABLE guide.arraytbl2 (
  key CHAR(1) NOT NULL
  , i INTEGER NOT NULL
  , val INTEGER
  , PRIMARY KEY (key, i)
);

INSERT INTO guide.arraytbl2 VALUES('A', 1, NULL);
INSERT INTO guide.arraytbl2 VALUES('A', 2, NULL);
INSERT INTO guide.arraytbl2 VALUES('A', 3, NULL);
INSERT INTO guide.arraytbl2 VALUES('A', 4, NULL);
INSERT INTO guide.arraytbl2 VALUES('A', 5, NULL);
INSERT INTO guide.arraytbl2 VALUES('A', 6, NULL);
INSERT INTO guide.arraytbl2 VALUES('A', 7, NULL);
INSERT INTO guide.arraytbl2 VALUES('A', 8, NULL);
INSERT INTO guide.arraytbl2 VALUES('A', 9, NULL);
INSERT INTO guide.arraytbl2 VALUES('A', 10, NULL);
INSERT INTO guide.arraytbl2 VALUES('B', 1, 3);
INSERT INTO guide.arraytbl2 VALUES('B', 2, NULL);
INSERT INTO guide.arraytbl2 VALUES('B', 3, NULL);
INSERT INTO guide.arraytbl2 VALUES('B', 4, NULL);
INSERT INTO guide.arraytbl2 VALUES('B', 5, NULL);
INSERT INTO guide.arraytbl2 VALUES('B', 6, NULL);
INSERT INTO guide.arraytbl2 VALUES('B', 7, NULL);
INSERT INTO guide.arraytbl2 VALUES('B', 8, NULL);
INSERT INTO guide.arraytbl2 VALUES('B', 9, NULL);
INSERT INTO guide.arraytbl2 VALUES('B', 10, NULL);
INSERT INTO guide.arraytbl2 VALUES('C', 1, 1);
INSERT INTO guide.arraytbl2 VALUES('C', 2, 1);
INSERT INTO guide.arraytbl2 VALUES('C', 3, 1);
INSERT INTO guide.arraytbl2 VALUES('C', 4, 1);
INSERT INTO guide.arraytbl2 VALUES('C', 5, 1);
INSERT INTO guide.arraytbl2 VALUES('C', 6, 1);
INSERT INTO guide.arraytbl2 VALUES('C', 7, 1);
INSERT INTO guide.arraytbl2 VALUES('C', 8, 1);
INSERT INTO guide.arraytbl2 VALUES('C', 9, 1);
INSERT INTO guide.arraytbl2 VALUES('C', 10, 1);

SELECT
  *
FROM
  guide.arraytbl2 AS a1
WHERE
  NOT EXISTS (SELECT *
              FROM guide.arraytbl2 AS a2
              WHERE a1.key = a2.key
                AND (a2.val <> 1 OR a2.val IS NULL))
;

/* 演習問題5-2 */
SELECT
  *
FROM
  guide.projects AS p1
WHERE 1 = ALL (
  SELECT CASE 
      WHEN step_nbr IN (0, 1) AND status = 'completed' THEN 1
      WHEN step_nbr > 1 AND status = 'wait' THEN 1
      ELSE 0 END
  FROM
    guide.projects AS p2
  WHERE p1.project_id = p2.project_id)
;

/* 演習問題5-3 */
DROP TABLE IF EXISTS guide.numbers;
CREATE TABLE guide.numbers AS
  SELECT generate_series(1, 100) AS num
;

SELECT
  num
FROM
  guide.numbers AS num1
WHERE
  num > 1
  AND NOT EXISTS (
    SELECT
      *
    FROM
      guide.numbers AS num2
    WHERE
      num2.num <= num1.num / 2
      AND num2.num <> 1
      AND MOD(num1.num, num2.num) = 0
  )
ORDER BY num1.num;