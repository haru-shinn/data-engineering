# ベースイメージとしてUbuntu 24.04を指定
FROM ubuntu:24.04

# パッケージのインストールを非対話型に設定
ENV DEBIAN_FRONTEND=noninteractive

# パッケージリストを更新し、必要なツールをインストール
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    postgresql \
    postgresql-contrib \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# パスの永続化
ENV PATH="/usr/lib/postgresql/16/bin:${PATH}"
ENV PGDATA="/var/lib/postgresql/16/main"

# rootユーザーの段階でディレクトリを更地にして権限を整える
# ビルド時にinitdbが動き、systemctl経由でpostgresqlが起動できるようにするために準備する
# ただし、セキュリティや仕組みの制限により、この「自動起動や自動初期化」が途中で失敗し、中身が壊れた（不完全な）ディレクトリが残る
# そのため、ビルドの段階で一度中身を完全に削除してから、再度ディレクトリを作成し、権限を整えることで、ビルドの段階で「初期化が完了した状態」を作る
RUN rm -rf ${PGDATA}/* &&\
    mkdir -p ${PGDATA} &&\
    chown -R postgres:postgres /var/lib/postgresql/

# postgresユーザーに切り替えて、ビルド時に初期化(initdb)を済ませる
USER postgres
RUN initdb -D ${PGDATA}

# 外部からの接続を許可（ここでpg_hba.confやpostgresql.confを書き換え）
RUN echo "host all all all md5" >> ${PGDATA}/pg_hba.conf
RUN echo "listen_addresses='*'" >> ${PGDATA}/postgresql.conf

EXPOSE 5432

# コンテナ起動時のデフォルトコマンド
CMD ["postgres", "-D", "/var/lib/postgresql/16/main"]