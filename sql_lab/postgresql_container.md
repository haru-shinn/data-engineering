# コマンド集

```bash
# コンテナ起動
$ docker compose up -d
$ docker container ps

# ログの確認
$ docker logs postgres_container_index
$ docker logs -f postgres_container_index

# 初期化
# 1. コンテナ停止 ＆ ボリュームの完全削除
docker compose down -v

# 2. ローカルの pgdata フォルダを物理削除（念のため）
sudo rm -rf ./pgdata

# 3. 起動（これで ddl.sql が実行されます）
docker compose up -d


# DBへの接続
$ psql -h localhost -p 5433 -U test-user -d training_db

# DB内のテーブル確認
docker exec -it postgres_container psql -U test-user -d training_db -c "\dt"

```
