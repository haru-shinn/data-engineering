/*
データベースの初期化
*/

-- DB作成（公式のイメージ位をPULLしているためか、compose.yml内の設定を見てtraining_dbが作成されている？）
-- CREATE DATABASE training_db;

-- DBへの接続
\c training_db;

-- 悲観ロック用
-- テーブル作成
DROP TABLE IF EXISTS sample_tbl;
CREATE TABLE sample_tbl (
  id CHAR(15) NOT NULL PRIMARY KEY
  , balance INTEGER NOT NULL
  , created_date_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ID用シーケンスの作成
CREATE SEQUENCE sample_id_seq START 1;

-- サンプルデータの登録
INSERT INTO sample_tbl
SELECT 
    LEFT(MD5(i::text), 8) || '_' || LPAD(nextval('sample_id_seq')::TEXT, 6, '0')
    , FLOOR(RANDOM()*10000 + 100)
    , CURRENT_DATE + (random() * 365)::int * INTERVAL '1 day'
FROM generate_series(1, 100000) s(i);

-- 楽観ロック用
-- テーブル作成
DROP TABLE IF EXISTS sample_tbl_2;
CREATE TABLE sample_tbl_2 (
  id CHAR(15) NOT NULL PRIMARY KEY
  , balance INTEGER NOT NULL
  , created_date_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  , version INTEGER DEFAULT 1
);

-- サンプルデータの登録
INSERT INTO sample_tbl_2
SELECT 
    LEFT(MD5(i::text), 8) || '_' || LPAD(nextval('sample_id_seq')::TEXT, 6, '0')
    , FLOOR(RANDOM()*10000 + 100)
    , CURRENT_DATE + (random() * 365)::int * INTERVAL '1 day'
FROM generate_series(1, 100000) s(i);
