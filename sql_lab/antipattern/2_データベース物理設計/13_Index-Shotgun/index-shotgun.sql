-- アンチパターン
CREATE TABLE Bugs (
  bug_id        SERIAL PRIMARY KEY,
  date_reported DATE NOT NULL,
  summary       VARCHAR(80) NOT NULL,
  status        VARCHAR(10) NOT NULL,
  hours         NUMERIC(9,2),
  INDEX (bug_id),
  INDEX (summary),
  INDEX (hours),
  INDEX (bug_id, date_reported, status)
);

-- 解決策: 「MENTOR」の原則に基づいて効果的なインデックス管理を行う
CREATE INDEX BugCovering ON Bugs
  (status, bug_id, date_reported, reported_by, summary);
