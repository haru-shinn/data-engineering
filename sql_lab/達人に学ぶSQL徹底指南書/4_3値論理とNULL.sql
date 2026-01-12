/* 3値論理とNULL */


/* 比較述語とNULL 排中律が成立しない */
DROP TABLE IF EXISTS guide.students;
CREATE TABLE guide.students (
  name VARCHAR(8) PRIMARY KEY
  , age INTEGER
);

INSERT INTO guide.students VALUES ('brown', 22);
INSERT INTO guide.students VALUES ('rally', 19);
INSERT INTO guide.students VALUES ('john', NULL);
INSERT INTO guide.students VALUES ('bogy', 21);

SELECT * FROM guide.students WHERE age = 20 OR age <> 20;
SELECT * FROM guide.students WHERE age = 20 OR age <> 20 OR age IS NULL;

SELECT
  name
  , CASE age
      WHEN 22 THEN 'ok'
      WHEN NULL THEN 'null??'
      ELSE 'ng'
    END AS age_judge
FROM
  guide.students
;

/* NOT IT & NOT EXISTS */
DROP TABLE IF EXISTS guide.class_a;
CREATE TABLE guide.class_a (
  name VARCHAR(16) PRIMARY KEY
  , age INTEGER
  , city VARCHAR(16)
);

INSERT INTO guide.class_a VALUES ('brown', 22, 'tokyo');
INSERT INTO guide.class_a VALUES ('rally', 19, 'saitama');
INSERT INTO guide.class_a VALUES ('bogy', 21, 'chiba');

DROP TABLE IF EXISTS guide.class_b;
CREATE TABLE guide.class_b (
  name VARCHAR(16) PRIMARY KEY
  , age INTEGER
  , city VARCHAR(16)
);

INSERT INTO guide.class_b VALUES ('saito', 22, 'tokyo');
INSERT INTO guide.class_b VALUES ('tajiri', 23, 'tokyo');
INSERT INTO guide.class_b VALUES ('yamada', NULL, 'tokyo');
INSERT INTO guide.class_b VALUES ('izumi', 18, 'chiba');
INSERT INTO guide.class_b VALUES ('takeda', 20, 'chiba');
INSERT INTO guide.class_b VALUES ('ishikawa', 19, 'kanagawa');

-- Bクラスの東京在住の生徒と年齢が一致しないAクラスの生徒を選択
-- NOT IN
SELECT
  *
FROM
  guide.class_a
WHERE
  age NOT IN (SELECT age 
              FROM guide.class_b 
              WHERE city = 'tokyo')
;
/*
meom（where句のみ記述）
1 WHERE age NOT IN (22, 23, NULL)
2 WHERE NOT age IN (22, 23, NULL)
3 WHERE NOT ((age = 22) OR (age = 23) OR (age = NULL))
4 WHERE NOT (age = 22) AND (age = 23) AND (age = NULL)
5 WHERE (age <> 22) AND (age <> 23) AND (age <> NULL)
6 WHERE (age <> 22) AND (age <> 23) AND unknown
7 WHERE false または unknown
WHERE句は1行もtrueに評価されないため、結果として空を返す
*/

-- NOT EXISTS
SELECT
  *
FROM
  guide.class_a AS a
WHERE
  NOT EXISTS (SELECT *
              FROM guide.class_b  AS b
              WHERE a.age = b.age AND city = 'tokyo')
;
/*
meom（サブクエリ内のみ記述）
1 SELECT * FROM guide.class_b AS b WHERE a.age = NULL AND b.city = 'tokyo'
2 SELECT * FROM guide.class_b AS b WHERE unknown AND b.city = 'tokyo'
3 SELECT * FROM guide.class_b AS b WHERE false または unknown
4 サブクエリが結果を返さないため、NOT EXISTS　は true となる
　SELECT * FROM guide.class_a AS a WHERE true
「一致する行が見つからない（空集合）」とき、NOT EXISTS は True を返す
*/

/*
memo（比較 by gemini）
特徴,NOT IN,NOT EXISTS
判定対象,値のリスト（集合）,行の存在有無
NULLの扱い,サブクエリの結果に NULL があると結果が空になる,NULL があっても無視して判定を継続できる
典型的な用途,固定値のリストとの比較,他のテーブルとの複雑な紐付け

特徴,IN,EXISTS
判定の核心,「この値はリストにある？」,「この条件に合う行は存在する？」
NULLの扱い,Unknown として評価される（抽出されない）,結合条件に合わないため「存在しない」扱い（抽出されない）
評価の中断,リストを最後まで見る場合がある,1行見つかった時点でその行の判定を終了する
*/



/* 限定述語とNULL */

TRUNCATE TABLE guide.class_a;
INSERT INTO guide.class_a VALUES ('brown', 22, 'tokyo');
INSERT INTO guide.class_a VALUES ('rally', 19, 'saitama');
INSERT INTO guide.class_a VALUES ('bogy', 21, 'chiba');
TRUNCATE TABLE guide.class_b;
INSERT INTO guide.class_b VALUES ('saito', 22, 'tokyo');
INSERT INTO guide.class_b VALUES ('tajiri', 23, 'tokyo');
INSERT INTO guide.class_b VALUES ('yamada', 20, 'tokyo');
INSERT INTO guide.class_b VALUES ('izumi', 18, 'chiba');
INSERT INTO guide.class_b VALUES ('takeda', 20, 'chiba');
INSERT INTO guide.class_b VALUES ('ishikawa', 19, 'kanagawa');

SELECT
  *
FROM
  guide.class_a
WHERE
  age < ALL (SELECT age
              FROM guide.class_b
              WHERE city = 'tokyo');

SELECT *
FROM guide.class_a
WHERE age < ALL 
    (SELECT age 
      FROM (SELECT 22 AS age
            UNION ALL
            SELECT 23 AS age
            UNION ALL
            SELECT NULL AS age));
/*
meom（内部挙動）
1 SELECT * FROM guide.class_a WHERE age = ALL (22, 23, NULL);
2 SELECT * FROM guide.class_a WHERE (age < 22) AND (age < 23) AND (age < NULL);
3 SELECT * FROM guide.class_a WHERE (age < 22) AND (age < 23) AND unknown;
4 SELECT * FROM guide.class_a WHERE false または unknown;
AND の演算に unknown が含まれると結果が true にならない
*/


/*
限定述語と極値関数
*/

/*
memo
限定述語: ALL, ANY
極値関数: MAX, MIN
*/

-- NULLを排除する
TRUNCATE TABLE guide.class_b;
INSERT INTO guide.class_b VALUES ('saito', 22, 'tokyo');
INSERT INTO guide.class_b VALUES ('tajiri', 23, 'tokyo');
INSERT INTO guide.class_b VALUES ('yamada', NULL, 'tokyo');
INSERT INTO guide.class_b VALUES ('izumi', 18, 'chiba');
INSERT INTO guide.class_b VALUES ('takeda', 20, 'chiba');
INSERT INTO guide.class_b VALUES ('ishikawa', 19, 'kanagawa');
SELECT
  *
FROM
  guide.class_a
WHERE
  age < (SELECT MIN(age)
        FROM guide.class_b
        WHERE city = 'tokyo');

/*
ALL述語と極値関数の表現
*/
/*
memo 例
ALL述語: 彼は東京在住の生徒の誰よりも若い --> 入力が空集合の場合NULLを返す
極値関数: 彼は東京在住の最も若い生徒よりも若い --> 空を返す

ALL述語の内部処理
SELECT * FROM guide.class_a WHERE age < NULL;
SELECT * FROM guide.class_a WHERE unknown;
*/
TRUNCATE TABLE guide.class_b;
INSERT INTO guide.class_b VALUES ('izumi', 18, 'chiba');
INSERT INTO guide.class_b VALUES ('takeda', 20, 'chiba');
INSERT INTO guide.class_b VALUES ('ishikawa', 19, 'kanagawa');

SELECT * FROM guide.class_a WHERE age < ALL (SELECT age FROM guide.class_b WHERE city = 'tokyo');
SELECT * FROM guide.class_a WHERE age < (SELECT MIN(age) FROM guide.class_b WHERE city = 'tokyo');

/*
集約関数とNULL
*/
/*
memo
集約関数: 入力テーブルが空の場合NULLを返す。※COUNT関数以外
下記の例の場合、東京在住の生徒がいない場合、AVG関数はNULLを返す。
外側のWHERE句は常にunknownとなる。
*/
SELECT
  * 
FROM
  guide.class_a
WHERE
  age < (SELECT AVG(age)
        FROM guide.class_b
        WHERE city = 'tokyo'
  );


/*
演習問題
*/

/* 演習問題4-1 */
TRUNCATE TABLE guide.class_b;
INSERT INTO guide.class_b VALUES ('saito', 22, 'tokyo');
INSERT INTO guide.class_b VALUES ('tajiri', 23, 'tokyo');
INSERT INTO guide.class_b VALUES ('yamada', NULL, 'tokyo');
INSERT INTO guide.class_b VALUES ('izumi', 18, 'chiba');
INSERT INTO guide.class_b VALUES ('takeda', 20, 'chiba');
INSERT INTO guide.class_b VALUES ('ishikawa', 19, 'kanagawa');

SELECT age FROM guide.class_b ORDER BY age ASC; -- NULLは一番最後
SELECT age FROM guide.class_b ORDER BY age DESC; -- NULLは先頭

/* 演習問題4-2 */
SELECT 'abc' || NULL ; -- NULLが返ってくる。
SELECT CONCAT('abc', NULL); -- abcが返ってくる。

/* 演習問題4-3 */ 
SELECT COALESCE(age, 0) FROM guide.class_b; -- NULL → 0 へ変換される。
SELECT NULLIF(1, 1) AS a, NULLIF(1, 2) AS b; -- aはNULL, bは1が返ってくる。
