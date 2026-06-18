-- アンチパターン
CREATE TABLE Customers (
  customer_id   NUMBER(9) PRIMARY KEY,
  contact_info  VARCHAR(255),
  business_type VARCHAR(20),
  revenue       NUMBER(9,2)
);
-- 年ごとのデータを格納する列を追加
ALTER TABLE Customers ADD (revenue2002 NUMBER(9,2));
ALTER TABLE Customers ADD (revenue2003 NUMBER(9,2));
ALTER TABLE Customers ADD (revenue2004 NUMBER(9,2));

-- 解決方法
CREATE TABLE CustomerMetadata (
  customer_id   NUMBER(9) PRIMARY KEY,
  business_type VARCHAR(20),
  revenue       NUMBER(9,2),
  FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);
