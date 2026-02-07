# 演習1：PITR（ポイントインタイムリカバリ）の実践

演習内容: 「間違えて大事なデータを削除した」という状況を想定し、WAL（ログ）を使って特定の時刻の状態に戻す。

PITR(ピントインタイムリカバリ): DBを過去の任意の時間の状態に戻すこと。物理バックアップ+トランザクションのログ（WAL）により、任意の時間の状態に戻すことが可能。

## シナリオ

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

## 設定

### postgresql.conf

|パラメータ名|説明|設定値|
|--|--|--|
|wal_level|walに記録する情報の量を設定する。`minimal`, `replica`, `logical`を指定可能。デフォルトは`replica`|`replica`以上|
|archive_mode|WALアーカイビングを有効化するかどうかを設定する。`on`, `off`, `always`を指定可能。|`on` か `always`|
|archive_command|WALセグメントファイルをアーカイブする際に実行するコマンドを設定する。`%p`, `%f`を指定可能。|適当なコマンド|
|restore_command|リストア時に必要となるWALセグメントファイルを取得するコマンドを設定する。`%p`, `$f`を指定可能。|適当なコマンド|
|max_wal_senders|standbyサーバやバックアップ取得のためのWAL senderの最大数を設定する。デフォルトは10。|適当な数|

### pg_hba.conf

物理バック取得コマンドを実行するサーバからreplication接続を許可

```bash
# 例
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
```

## 手順

### 環境

```bash
OS: Ubuntu 16.11-0ubuntu0.24.04.1
DB: PostgreSQL 16.11
```

### DBの設定

```bash
# 設定ファイルの場所
$ psql -c "show config_file;"
                 config_file                 
---------------------------------------------
 /var/lib/postgresql/16/main/postgresql.conf

# 設定変更
postgres@642e764eae2f:/$ grep "archive_" /var/lib/postgresql/16/main/postgresql.conf
#archive_mode = off             # enables archiving; off, on, or always
#archive_library = ''           # library to use to archive a WAL file
                                # (empty string indicates archive_command should
#archive_command = ''           # command to use to archive a WAL file
#archive_timeout = 0            # force a WAL file switch after this
#archive_cleanup_command = ''   # command to execute at every restartpoint
#max_standby_archive_delay = 30s        # max delay before canceling queries

postgres@642e764eae2f:/$ sed -i "s|#archive_command = ''|archive_command = 'cp %p //var/backups/wal_archives/%f'|" /var/lib/postgresql/16/main/postgresql.conf
postgres@642e764eae2f:/$ sed -i "s|#archive_mode = off|archive_mode = on|" /var/lib/postgresql/16/main/postgresql.conf

postgres@642e764eae2f:/$ grep "restore_command" /var/lib/postgresql/16/main/postgresql.conf
#restore_command = ''           # command to use to restore an archived WAL file
postgres@642e764eae2f:/$ sed -i "s|#restore_command = ''|restore_command = 'cp //var/backups/wal_archives//%f %p'|" /var/lib/postgresql/16/main/postgresql.conf
```

### データの準備

```sql
-- 接続
-- $ psql -U postgres -d study_db

-- 作成
create schema pitr_schema;
create table pitr_schema.test_tbl (id varchar(30));
insert into pitr_schema.test_tbl (id) values ('record_001'), ('record_002'), ('record_003');
select * from pitr_schema.test_tbl;
/*
     id     
------------
 record_001
 record_002
 record_003
(3 rows)
*/
```

### 物理バックアップ

`pg_basebackup` を利用することで、オンライン（DBが稼働状態）で物理バックアップを取得可能。

```bash
$ pg_basebackup -D /var/backups/wal_archives/20260207 -Ft -P -v -U postgres
$ ls -la /var/backups/wal_archives/20260207/
total 55000
drwx------ 2 postgres postgres     4096 Feb  7 04:49 .
drwxrwxrwx 3 root     root         4096 Feb  7 04:49 ..
-rw------- 1 postgres postgres   225155 Feb  7 04:49 backup_manifest
-rw------- 1 postgres postgres 39302656 Feb  7 04:49 base.tar
-rw------- 1 postgres postgres 16778752 Feb  7 04:49 pg_wal.tar
```

### データの追加

```sql
-- 接続
-- $ psql -U postgres -d study_db

-- 追加
insert into pitr_schema.test_tbl (id) values ('record_004'), ('record_005'), ('record_006');
select * from pitr_schema.test_tbl;
     id     
------------
 record_001
 record_002
 record_003
 record_004
 record_005
 record_006
(6 rows)
```

### 誤操作

```sql
-- 誤ったデータ追加
insert into pitr_schema.test_tbl (id) values ('record_007');

-- 誤削除
delete from pitr_schema.test_tbl where id = 'record_002';

-- 確認
select * from pitr_schema.test_tbl;
     id     
------------
 record_001
 record_003
 record_004
 record_005
 record_006
 record_007
(6 rows)
```

### リストア

```bash
# DB停止
$ pg_ctl stop

# WALを圧縮して退避
$ cd /var/lib/postgresql/16/main/pg_wal/
$ ls
000000010000000000000003  000000010000000000000004  archive_status  study_db.dump
$ tar zcvf latest_pg_wal.tar.gz *
$ mv latest_pg_wal.tar.gz /var/backups/wal_archives/

# ${PGDATA}配下を削除
$ cd ../
$ rm -rf main/ 

# 物理バックアップ (base.tar) を${PGDATA}にコピーし解凍
$ cp /var/backups/wal_archives/20260207/base.tar ./main/
$ cd ./main
$ tar xvf base.tar
$ rm base.tar

# 物理バックアップ時のWAL (pg_wal.tar) を${PGDATA}/pg_walにコピーし解凍
$ cp /var/backups/wal_archives/20260207/pg_wal.tar ./main/
$ cd ./main
$ tar xvf pg_wal.tar
$ rm pg_wal.tar

# 退避した最新WAL（事故直前のデータが入っているもの）をアーカイブ場所に展開
$ mkdir -p /tmp/latest_wal
$ tar zxvf /var/backups/wal_archives/latest_pg_wal.tar.gz -C /tmp/latest_wal/
$ cp /tmp/latest_wal/00000001* /var/backups/wal_archives
$ ls /var/backups/wal_archives/
000000010000000000000003  000000010000000000000004  20260207  latest_pg_wal.tar.gz
postgres@642e764eae2f:~/16/main$ 

$ tar xvf /var/backups/wal_archives/20260207/pg_wal.tar -C /tmp/
000000010000000000000002
$ cp /tmp/00000001* /var/backups/wal_archives/

# recovery.signalの確認
$ touch /var/lib/postgresql/16/main/recovery.signal

# 復旧確認（誤操作前に戻すためには、recovery_target_timeを指定する必要がある。）
$ pg_ctl start
$ psql -U postgres -d study_db
study_db=# select * from pitr_schema.test_tbl;
     id     
------------
 record_001
 record_003
 record_004
 record_005
 record_006
 record_007
(6 rows)
```

### 整理

```bash
# バックアップの場所
$ grep "/var/backups/wal_archives" /var/lib/postgresql/16/main/postgresq.conf
archive_command = 'cp %p /var/backups/wal_archives/%f'          # command to use to archive a WAL file
restore_command = 'cp /var/backups/wal_archives/%f %p'          # command to use to restore an archived WAL file

# 正常操作後の物理バックアップデータ
$ ls /var/backups/wal_archives/20260207
backup_manifest  base.tar  pg_wal.tar

# 誤操作後のwalファイル
$ls /var/backups/wal_archives/
000000010000000000000003  000000010000000000000004  20260207  latest_pg_wal.tar.gz
```
