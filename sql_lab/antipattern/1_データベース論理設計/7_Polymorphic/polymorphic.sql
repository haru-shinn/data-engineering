-- アンチパターン
CREATE TABLE Comments (
    comment_id INT PRIMARY KEY,
    bug_id INT NOT NULL,
    author_id INT NOT NULL,
    comment_date DATETIME NOT NULL,
    comment TEXT NOT NULL,
    FOREIGN KEY (bug_id) REFERENCES Bugs(bug_id),
    FOREIGN KEY (author_id) REFERENCES Accounts(author_id)
);

-- 解決方法
CREATE TABLE BugComments (
    issue_id    BIGINT NOT NULL,
    comment_id  BIGINT NOT NULL,
    PRIMARY KEY (issue_id, comment_id),
    FOREIGN KEY (issue_id) REFERENCES Bugs(issue_id),
    FOREIGN KEY (comment_id) REFERENCES Comments(comment_id)
);
CREATE TABLE FeaturesComments (
  issue_id    BIGINT NOT NULL,
  comment_id  BIGINT NOT NULL,
  PRIMARY KEY (issue_id, comment_id),
  FOREIGN KEY (issue_id) REFERENCES FeatureRequests(issue_id),
  FOREIGN KEY (comment_id) REFERENCES Comments(comment_id)
);
