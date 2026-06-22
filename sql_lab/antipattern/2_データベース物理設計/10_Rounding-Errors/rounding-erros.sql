-- アンチパターン
DROP TABLE IF EXISTS Accounts;
DROP TABLE IF EXISTS Bugs;
CREATE TABLE Accounts (
  account_id        VARCHAR(100) PRIMARY KEY,
  account_name      VARCHAR(20),
  hourly_rate_f       FLOAT,
  hourly_rate_n       NUMERIC(10, 2)
);
CREATE TABLE Bugs (
  bug_id            VARCHAR(100) PRIMARY KEY,
  date_reported     DATE NOT NULL DEFAULT (CURRENT_DATE),
  assigned_to       VARCHAR,
  hours_f             FLOAT,
  hours_n             NUMERIC(10, 2)
);

INSERT INTO Accounts (account_id, account_name, hourly_rate_f, hourly_rate_n)
VALUES
  ('001', '', 152.5, 152.50)
  ,('002', '', 120.5, 120.50);
INSERT INTO Bugs (bug_id, date_reported, assigned_to, hours_f, hours_n)
VALUES
  ('BUG001', CURRENT_DATE, '001', 10.05, 10.05)
  , ('BUG002', CURRENT_DATE, '002', 7.75, 7.75);


SELECT b.bug_id, b.hours_f * a.hourly_rate_f AS cost_per_bug_f, b.hours_n * a.hourly_rate_n AS cost_per_bug_n
FROM Bugs AS b
  JOIN Accounts AS a ON (b.assigned_to = a.account_id);

SELECT
    hourly_rate_f * 1000000000 AS hourly_rate_in_billion,
    hourly_rate_n * 1000000000 AS hourly_rate_n_in_billion
FROM Accounts;
