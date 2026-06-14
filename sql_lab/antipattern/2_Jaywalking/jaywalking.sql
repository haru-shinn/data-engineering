-- 初期化
DROP TABLE IF EXISTS Accounts;
DROP TABLE IF EXISTS Products;

CREATE TABLE Accounts (
  account_id        VARCHAR(100) PRIMARY KEY,
  account_name      VARCHAR(20),
  first_name        VARCHAR(20),
  last_name         VARCHAR(20),
  email             VARCHAR(100),
  password_hash     CHAR(64),
  portrait_image    BYTEA,
  hourly_rate       NUMERIC(9,2)
);

INSERT INTO Accounts (account_id, account_name, first_name, last_name, email, password_hash, portrait_image, hourly_rate)
SELECT
  n AS account_id,
  'Account ' || n AS account_name,
  'First ' || n AS first_name,
  'Last ' || n AS last_name,
  'user' || n || '@example.com' AS email,
  NULL AS password_hash,
  NULL AS portrait_image,
  NULL AS hourly_rate
FROM generate_series(1, 50) AS n;

-- アンチパターン
DROP TABLE IF EXISTS Products;
CREATE TABLE Products (
  product_id   INTEGER PRIMARY KEY,
  product_name VARCHAR(1000),
  account_id   VARCHAR(100)
);
INSERT INTO Products (product_id, product_name, account_id) VALUES
(100, 'Visual TurboBuilder', '12,34');

-- 解決策
DROP TABLE IF EXISTS Products;
CREATE TABLE Products (
  product_id BIGINT PRIMARY KEY,
  product_name VARCHAR(1000)
);
INSERT INTO Products (product_id, product_name) VALUES
(123, 'Visual TurboBuilder'),
(345, 'AAABBB'),
(567, 'XXXYYY');

DROP TABLE IF EXISTS Contacts;
CREATE TABLE Contacts (
  product_id  BIGINT NOT NULL,
  account_id  BIGINT NOT NULL
);

INSERT INTO Contacts (product_id, account_id)
VALUES (123, 12), (123, 34), (345, 23), (567, 12), (567, 34);
