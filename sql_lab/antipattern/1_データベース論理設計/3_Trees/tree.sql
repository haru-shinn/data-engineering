-- DDL
CREATE TABLE Comments (
  comment_id   BIGINT PRIMARY KEY,
  bug_id       BIGINT,
  parent_id    BIGINT,
  author_name  VARCHAR(255),
  comment      TEXT NOT NULL
);

-- 初期データ
INSERT INTO Comments (comment_id, bug_id, parent_id, author_name, comment)
  VALUES (1, 7, NULL, 'Kukla', 'バグの原因は？'),
         (2, 7, 1, 'Ollie', 'ヌルポ？'),
         (3, 7, 2, 'Fran', 'ちがうよ！'),
         (4, 7, 1, 'Kukla', '無効な入力は？'),
         (5, 7, 4, 'Ollie', 'バグの原因はそれかな？'),
         (6, 7, 4, 'Fran', 'チェック機能を追加してもらえる？'),
         (7, 7, 6, 'Kukla', 'OK!');

-- 階層構造の表示
SELECT c1.*, c2.*, c3.*, c4.*
FROM Comments c1                     -- 1階層目
  LEFT OUTER JOIN Comments c2
    ON c2.parent_id = c1.comment_id  -- 2階層目
  LEFT OUTER JOIN Comments c3
    ON c3.parent_id = c2.comment_id  -- 3階層目
  LEFT OUTER JOIN Comments c4
    ON c4.parent_id = c3.comment_id; -- 4階層目

-- 再帰的な階層構造の表示
WITH RECURSIVE CommentTree
    (comment_id, bug_id, parent_id, author_name, comment, depth)
AS (
    SELECT comment_id, bug_id, parent_id, author_name, comment, 0 AS depth
    FROM Comments
    WHERE parent_id IS NULL
    UNION ALL
    SELECT c.comment_id, c.bug_id, c.parent_id, c.author_name, c.comment,
        ct.depth+1 AS depth
    FROM CommentTree ct
    JOIN Comments c ON (c.parent_id = ct.comment_id)
)
SELECT * FROM CommentTree WHERE bug_id = 7;
