# OSS-DB Silver 学習まとめ

## PostgreSQLの一般知識

---

### OSS-DBの一般的特徴

#### 歴史

- バークレー校で開発されたIngressが元となって、Postgresの開発が開始、Postgres95を経て、PostgreSQLとなる。
- ボランティア団体に参加する技術者がメンテナンス実施。
- 日本のコミュニティは公式ドキュメントの日本語化や普及活動を実施。個人で参加可能（入会金・年会費不要）。

#### ライセンス

- 商用、非商用問わずに無償。
- PostgreSQLライセンスを採用しており、元の著作権の表示と免責条項を明記すれば、ソースコードを改変しても開示する義務がなく、自由に配布可能。
- BSDをベースとしたPOSTGRESライセンスを採用。
- 改変およびサポートを有償化すること可能。
- PostgreSQLのコミュニティは製造物の責任を負わない。

#### ライフサイクル

- 年一回のメジャーアップデートと年4回のマイナーアップデートがある。
- 年一回のメジャーアップデートでは、バグやセキュリティ対策だけでなく機能更新や仕様変更が行われる。
- マイナーアップデートでは、機能更新は行われない。
- メジャーバージョンが同じであれば、互換性あり。ただし、新しいバージョンから古いバージョンへのダウングレードは非推奨。
- バージョン9以下の際は、x.y.z の x.y がメジャーバージョンを示していた。
- バージョン10以降は、xy.z のxy がメジャーバージョンを示している。

#### その他

- エンコーディング（データベース側：EUC_JP, UTF8、クライアント側：EUC_JP, SJIS, UTF8）

---

### RDBに関する一般知識

#### データベース管理システムの役割

- データ定義機能、データ操作機能（CRUD）、データ制御機能、同時実行制御、障害回復・バックアップ、トランザクション、トリガー機能

#### SQLの一般知識

- ANSI/ISOによる標準化
- 非手続き型言語

#### SQLの分類

- DDL（Data Definition Language）: データ定義言語、CREATE, ALTER, DROP
- DML（Data Manipulation Language）: データ操作言語、INSERT, UPDATE, DELETE, SELECT, MERGE
- DCL（Data Control Language）: データ制御言語、GRANT, REVOKE, COMMIT, ROLLBAK

---

## 運用

### インストール方法

- initdb
  - データベースクラスタの作成。一つのサーバ内に複数のクラスタを作成可能（物理的にフォルダの分割が必要、ポート番号の変更が必要）。
  - rootユーザでの実行不可。ロケール(言語・文字コード・カレンダー等の地域に依存する設定情報)の無効化が可能。OSユーザと同じユーザと同じ名前のデータベース作成。
  - オプションを指定しない場合は、デフォルトの場所（環境変数 `PGDATA`）へDBが作成される。
  - 何も指定しない場合は、`-o --no-local` オプションを指定する。
  - エンコーディングは、`-o --enocding=UTF-8`
  - 例: `initdb -D /usr/local/pgsql/data -U postgres`
- PGDATA : PostgreSQLのデータベースクラスタ（全データベース、設定ファイル、WALログなど）が格納される物理的なルートディレクトリを指す環境変数または設定オプション。
- template0, template1
  - `create database` 実行時は、template1をコピーして新しいデータベースが作成される。
  - template1 に共通関数などを作ると自動的にコピーされる。
  - template0 は更新や削除不可。クリーンなデータベースを作成した場合などに利用される。
- データベースクラスタ:

### 標準付属ツールの使い方

#### サーバ管理

- pg_ctlコマンド
  - 起動・停止・再起動を行う。
  - `start`, `stop`, `restart`, `reload`, `status`, `kill` が存在する。
  - `start` が時間内に起動しない場合は、コマンド自体は失敗するが、PostgreSQLの起動自体はバックグランドで行われる。
    - `-t` でタイムアウト時間を指定可能。
  - `stop` で停止が可能。
    - `-m` 停止のモード用のオプション。
    - `s` (`smart`): クライアントからの接続がすべて切断されてから停止を行う。
    - `f` (`fast`): クライアントからの接続をすべて強制シャッドダウンを行う。実行中のトランザクションはすべてロールバックされる。
    - `i` (`immediate`): 緊急停止を行うため、次回起動時に復旧処理が必要。
  - `restart` で再起動を行う。
  - `reload` でpostgresql.conf, pg_hba.confの二つの設定ファイルを反映させる。
  - `status` で起動確認を行う。
  - `kill` プロセスにシグナルを送信可能。
  - `promote` スタンバイサーバーに対してスタンバイモードを終了し、読み書き操作を行えるよう指示をだす。
- pg_isready
  - 接続可能な状態かどうかをチェックをする。
- pg_controldata
  - データベースの制御情報（チェックポイントの位置やカタログのバージョンなど）を表示。
  - メンテナンスやトラブルシューティングで内部状態を確認するために利用する。
- pg_resetwal
  - WALをリセットする。緊急コマンドであるため、壊れてサーバーが起動しないときの最終手段として利用される。

#### ユーザ・DB操作

- createuser / dropuser
- createdb / dorpdb

#### クライアント・開発ツール

- psql
  - `psql`は外部から接続可能。
  - pg_hba.confなどで接続許可を行う必要はある。
- pg_config
  - 設定情報（パスやコンパイルオプション）を表示する。
    - `\l` : データベースの一覧表示
    - `\d` : テーブルやインデックスの一覧表示
    - `\q` : psqlの終了
    - `\c` データベース名 : 別のDBに切り替え

#### メタコマンド

- psqlの中だけで利用可能

### 設定ファイル

#### postgres.conf

- ログ
  - logging_collector: ログ収集の有無を設定
  - log_directory: ログ出力先ディレクトリを設定
  - log_filename: ログファイル名を設定
  - log_rotation_age: ログファイルを切り替える間隔を設定
  - log_rotation_size: ログファイルを切り替えるサイズを設定
  - log_truncatio_on_rotation: ログファイル切り替え時に既存の内容を上書きするかどうかを設定
  - log_line_prefix: ログの改行に付与する書式文字列を設定
  - log_min_messages: ログに記録するメッセージレベルを設定
  - log_checkpoints: データベースのチェックポイントの発生とその詳細をログに記録するかどうかを設定
- エンコーディング
  - クライアント側の環境変数　`PGCLIENTENCODING` を UTF-8 に設定。
  - psqlで接続後、`\encoding UTF-8` を実行。
  - SETコマンドで `client_encoding` パラメータをUTF-8に設定。
  - postgresql.confでclient_encodingパラメータをUTF-8に設定。
- 設定値の反映
  - postmaster: サーバー起動時に設定ファイルの内容が反映される
  - sighup: 設定ファイルのリロード操作で設定ファイルの内容が反映される
  - user: サーバー起動時、設定ファイルのリロード操作の他、SQLで動的変更が可能

#### pg_hba.conf

- クライアントの接続認証を設定。
- `pg_ctl reload` で変更を反映可能。
- 外部からの接続設定の際は、postgresql.conf の listen_addressesパラメータ（設定の変更には再起動が必要）を変更必要
  - `#listen_addresses = 'localhost'`

#### SET/SHOW

```sql
 psql -U postgres
psql (16.11 (Ubuntu 16.11-0ubuntu0.24.04.1))
Type "help" for help.

postgres=# show server_version;
            server_version             
---------------------------------------
 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)
(1 row)

postgres=# show server_encoding;
 server_encoding 
-----------------
 SQL_ASCII
(1 row)


\set                     
AUTOCOMMIT = 'on'
COMP_KEYWORD_CASE = 'preserve-upper'
DBNAME = 'postgres'
ECHO = 'none'
ECHO_HIDDEN = 'off'
ENCODING = 'SQL_ASCII'


\set ONE 1
SELECT * FROM my_table WHERE n = :ONE;
```

### バックアップとリストア

- 物理バックアップと論理バックアップが存在する。
- 物理バックアップには、ファイル毎バックアップと、`` が存在する。
  - `pg_basebackup` を利用することで、オンライン（DBが稼働状態）で物理バックアップを取得可能。
  - ファイルバックアップは停止が必要。
    - `rsync` や`tar` コマンドなどを用いてバックアップとして取得し、リストア先のディレクトリに配置する。
    - `WAL` ファイルを利用して、PITRを行う。
- 論理バックアップには、`pg_dump` と `pg_dumpall` が存在する。
  - `pg_dump` データベースのバックアップ。
    - 基本的にはテキスト形式でdumpファイルが取得されるが、tar形式などへ変更可能。
    - リストア時は、テキストの場合は、`psql`コマンド。tar形式などでは、`pg_restore`コマンドを使用。
    - `pg_dump -Fp -f (ファイル名) (対象のデータベース名)`
    - `-Fp` テキスト形式で取得。`-Ft` とすると、tar形式となる。
    - `-f` ファイル名の指定。これがない場合は、標準出力される。
    - データベース名の指定がない場合は、すべてのデータベースを対象にバックアップされる。
    - リストア時にはデータベースの作成は別途手動で実施が必要。`createdb db名`。
  - `pg_dumpall` データベースクラスタのバックアップ。
    - テキスト形式でバックアップされる。
    - `-f` で出力先のファイルを指定する。
    - リストア時にはディレクトリの作成と、`initdb` コマンドの実行が必要。
    - `psql` でリストアを行う。

### 基本的な運用管理作業

---

## 開発/SQL

### SQL コマンド

### 組み込み関数

### トランザクションの概念

---
