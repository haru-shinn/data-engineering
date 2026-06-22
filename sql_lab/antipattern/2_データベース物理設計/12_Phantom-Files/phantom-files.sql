-- アンチパターン
CREATE TABLE Accounts (
  account_id      SERIAL PRIMARY KEY,
  account_name    VARCHAR(20),
  portrait_image  BLOB
);

CREATE TABLE Screenshots (
  image_id          SERIAL NOT NULL,
  bug_id            BIGINT NOT NULL,
  screenshot_image  BLOB,
  caption           VARCHAR(100),
  PRIMARY KEY (image_id, bug_id),
  FOREIGN KEY (bug_id) REFERENCES Bugs(bug_id)
);

CREATE TABLE Screenshots (
  image_id          SERIAL NOT NULL,
  bug_id            BIGINT NOT NULL,
  screenshot_path   VARCHAR(100),
  caption           VARCHAR(100),
  PRIMARY KEY (image_id, bug_id),
  FOREIGN KEY (bug_id) REFERENCES Bugs(bug_id)
);
