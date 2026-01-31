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

-- indexの付与
--CREATE INDEX idx_sample_created_at ON sample_tbl (created_date_time);

/* 書き込み速度が遅くなるかの確認 */
CREATE TABLE test_write_speed (
    id SERIAL PRIMARY KEY
    , val TEXT
    , created_at TIMESTAMP
);

INSERT INTO test_write_speed (val, created_at)
SELECT md5(random()::text), now() FROM generate_series(1, 100000);

CREATE INDEX idx_1 ON test_write_speed (val);
CREATE INDEX idx_2 ON test_write_speed (created_at);
CREATE INDEX idx_3 ON test_write_speed (val, created_at);
