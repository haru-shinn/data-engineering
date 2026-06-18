-- アンチパターン
CREATE TABLE Bugs (
  bug_id      SERIAL PRIMARY KEY,
  description VARCHAR(1000),
  tag1        VARCHAR(20),
  tag2        VARCHAR(20),
  tag3        VARCHAR(20)
);

INSERT INTO Bugs (description, tag1, tag2, tag3)
VALUES ('保存処理クラッシュ', 'crash', '', '');

-- 解決方法
CREATE TABLE BugTags (
  bug_id  INT,
  tag     VARCHAR(20),
  PRIMARY KEY (bug_id, tag),
  FOREIGN KEY (bug_id) REFERENCES Bugs(bug_id)
);

INSERT INTO BugTags (bug_id, tag)
VALUES (1, 'crash');
