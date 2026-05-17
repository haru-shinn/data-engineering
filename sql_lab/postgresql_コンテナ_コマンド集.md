# コマンド集

## ## Dockerfile利用（検証環境構築・運用手順書）

### 新しい手順（推奨）

Dockerfile のビルド時に `initdb`（初期化）を完了させているため、コンテナ起動後は余計な初期化コマンドを叩く必要がなく、すぐに PostgreSQL を利用可能。  
また、コンテナの重複エラーを防ぐために使い捨て（`--rm`）での運用を標準としている。

#### 初回およびコンテナの新規起動

```bash
# 1. イメージのビルド（Dockerfileの変更を反映）
docker buildx build -t ossdb-study-img .

# 2. コンテナを起動して同時にログイン（使い捨てモードで名前の衝突を防ぐ）
docker run -it --rm --name ossdb-container ossdb-study-img /bin/bash

# --- これ以降はコンテナ内（postgresユーザー）での操作 ---

# 3. PostgreSQLの起動（Dockerfile内でPGDATAが定義されているため-D不要）
pg_ctl start

# 4. 検証用データベースの作成と確認
createdb study_db  # または psql -d postgres -c "CREATE DATABASE study_db;"
psql -d study_db

```

#### 2回目以降の接続・複数ユーザーのシミュレーション

既存のコンテナが起動している状態で、別ターミナルから追加でログインしたり、試験対策の「同時実行制御（ロック）」を検証したりする際の手順。

```bash
# パターンA: 別のターミナルから同じコンテナにBashで入る
docker exec -it -u postgres ossdb-container /bin/bash

# パターンB: 2人目のユーザーとして直接psqlで特定のDBに接続する（ロック検証などに最適）
docker exec -it ossdb-container psql -U postgres -d study_db

```

（番外編：docker run, docker exec の違い）

|項目|docker run|docker exec|
|--|--|--|
|コンテナの状態|まだ存在しない（新しく作る）|すでに起動している必要がある|
|実行した結果|新しいコンテナが1つ増える|コンテナの数は増えない（中身が増える）|
|主な用途|テスト環境を新しく立ち上げる時|起動中のDBにログインしてSQLを叩く時、ログを監視する時|
|対象の指定|イメージ名 を指定する(ossdb-study-img)|コンテナ名 / ID を指定する(ossdb-container)|

---

### 過去の手順とトラブルシュート履歴（ログとして保管）

以前発生していたエラーの原因と、当時の対応策のログです。今後のトラブルシューティングの参考として残す。

#### 初回設定時のログ

当初、Ubuntuにパッケージインストールした直後の不完全なディレクトリが残っていたため、単に `pg_ctl start` を実行するとデータディレクトリ不正でエラーになっていた。そのため、以下の「力技の初期化」をコンテナ内で手動実行して回避していた。

```bash
# スタートに失敗したので、クラスターの初期化
# すでにある不完全なディレクトリを強制削除
rm -rf /var/lib/postgresql/16/main/*

# 手動でinitdbを実行して初期化
/usr/lib/postgresql/16/bin/initdb -D /var/lib/postgresql/16/main

# 設定ファイルの存在確認
ls -l /var/lib/postgresql/16/main/postgresql.conf

# 起動
pg_ctl start -D /var/lib/postgresql/16/main

```

#### 旧：2回目以降の手順ログ

以前は `--rm` なしで `docker run` をしていたため、コンテナを抜けた後に「同名のコンテナが既に存在します」というエラー（Conflict）が多発していた。そのため、停止したコンテナを `start` して `attach` する必要があった。

```bash
$ cd sql_lab/oss-db

# 停止中の古いコンテナを再利用する場合
$ docker container ls -a
$ docker container start {$image_id}
$ docker container attach {$image_id}  # ←注意: exitするとコンテナがまた停止する

# 新しいプロセスを開始する（attach よりこっち優先的に利用する）
docker exec -it -u {$user_name} {$image_id} /bin/bash

# 複数ユーザがログインする場合
docker exec -it {$container_name} psql -U {$二人目のユーザ名} -d {$db_name}

```

---

## DockerCompose利用

- レプリケーション演習など複数DBを立ち上げることを想定

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
$ psql -h localhost -p {$port} -U {$user_name$} -d {$db_name}
# DB内のテーブル確認
docker exec -it {$container_name} psql -U {$user_name$} -d {$db_name} -c "\dt"

# 設定変更する場合
$ docker compose up -d
$ docker compose restart {$db_name}
## 確認の一例
$ docker compose exec training_db psql -U -c "SHOW max_connections;"
```
