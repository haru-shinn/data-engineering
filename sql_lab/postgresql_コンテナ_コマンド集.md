# コマンド集

## DockerCompose利用

```bash
# コンテナ起動
$ docker compose up -d
$ docker container ps

# ログの確認
$ docker logs {$container_name}
$ docker logs -f {$container_name}

# 初期化
## コンテナ停止 ＆ ボリュームの完全削除
docker compose down -v
## ローカルの pgdata フォルダを物理削除（念のため）
sudo rm -rf ./pgdata
## 起動（これで ddl.sql が実行される）
docker compose up -d

# DBへの接続
$ psql -h localhost -p 5433 -U {$user_name$} -d {$db_name}
# DB内のテーブル確認
docker exec -it {$container_name} psql -U {$user_name$} -d {$db_name} -c "\dt"

# 設定変更する場合
$ docker compose up -d
$ docker compose restart {$db_name}
## 確認の一例
$ docker compose exec training_db psql -U -c "SHOW max_connections;"
```

## Dockerfile利用

### 初回設定(Dockerfileを利用する場合)

```bash
# Dockerfileの修正
# コンテナの作成
$ docker buildx build -t ossdb-study-img .
[+] Building 51.5s (6/6) FINISHED          
$ docker run -it --name ossdb-container ossdb-study-img /bin/bash
## (2回目以降：docker start {$image-id}→docker attach {$image-id})

# ステータス確認
pg_ctl status -D /var/lib/postgresql/16/main
# 開始
pg_ctl start -D /var/lib/postgresql/16/main
# 停止
pg_ctl stop -D /var/lib/postgresql/16/main
## ENV PGDATA="/var/lib/postgresql/16/main"をdockerfile内に記載している場合は-D オプション不要。


# スタートに失敗したので、クラスターの初期化
# すでにある空のディレクトリを削除（または別の場所を指定）
rm -rf /var/lib/postgresql/16/main/*
# initdbを実行して初期化(環境変数PGDATAが設定されている場合は、pg_ctl initdbのみでよい)
/usr/lib/postgresql/16/bin/initdb -D /var/lib/postgresql/16/main
# 確認
ls -l /var/lib/postgresql/16/main/postgresql.conf
# 起動
pg_ctl start -D /var/lib/postgresql/16/main

# データベース作成
psql -d postgres
postgres=# CREATE DATABASE study_db;
postgres=# \c study_db

# データベース確認
psql -U postgres -c "\l"
```

### 2回目以降

```bash
$ cd sql_lab/oss-db

# 実行中のプロセスに接続する
$ docker container ls -a
$ docker container start {$iamge_id}
$ docker container attach {$image_id}

# 新しいプロセスを開始する
docker exec -it -u {$user_name} {$image_id} /bin/bash

# DB起動
postgres@642e764eae2f:/$ pg_ctl status
postgres@642e764eae2f:/$ pg_ctl start
psql -U postgres -c "\l"
```
