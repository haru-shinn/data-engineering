# 演習1：PITR（ポイントインタイムリカバリ）の実践

**【重要度：7 / カテゴリ：S2.4 バックアップ方法】**

「間違えて大事なデータを削除してしまった！」という状況を想定し、WAL（ログ）を使って特定の時刻の状態に戻す演習。

## シナリオ（RITR）

- **準備**: `postgresql.conf` で `archive_mode = on` にし、`archive_command` を設定して再起動します。
- **ベースライン**: `pg_basebackup` を使用して、フルバックアップを取得します。
- **作業**: データベースにログインし、テーブルにデータを数件挿入します。この時の**時刻**をメモしてください。
- **事故発生**: `DELETE` 文または `DROP TABLE` でデータを消去します。
- **復旧**:
  - PostgreSQLを停止します。
  - データディレクトリを退避し、手順2のバックアップを書き戻します。
  - データディレクトリ直下に `recovery.signal` ファイル（空ファイル）を作成します。
  - `postgresql.conf` に `recovery_target_time`（メモした時刻）を記述します。
- **確認**: サーバを起動し、消したはずのデータが戻っているか確認します。

```bash
Bash
# 1. 設定ファイルの場所を確認
psql -c "show config_file;"

# 2. vimなどで設定を変更（例: /etc/postgresql/14/main/postgresql.conf）
# 以下の項目を探して変更してください
# archive_mode = on
# archive_command = 'test ! -f /var/lib/postgresql/archive/%f && cp %p /var/lib/postgresql/archive/%f'
# wal_level = replica

# 3. アーカイブディレクトリの作成
mkdir -p /var/lib/postgresql/archive

# 4. 設定反映（再起動が必要なパラメータです）
pg_ctl restart -D /var/lib/postgresql/14/main
```
