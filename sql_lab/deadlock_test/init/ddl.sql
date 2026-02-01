/*
データベースの初期化
*/

-- DB作成（公式のイメージ位をPULLしているためか、compose.yml内の設定を見てtraining_dbが作成されている？）
-- CREATE DATABASE training_db;

-- DBへの接続
\c training_db;

-- テーブル作成
DROP TABLE IF EXISTS sample_tbl;
CREATE TABLE sample_tbl (
  id VARCHAR(128) NOT NULL PRIMARY KEY
  , balance INTEGER NOT NULL
  , created_date_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- サンプルデータの登録
INSERT INTO sample_tbl (id, balance, created_date_time)
SELECT 
  md5(random()::text), 
  (random()*10000)::int, 
  now() - (random() * interval '365 days')
FROM generate_series(1, 1000000);
