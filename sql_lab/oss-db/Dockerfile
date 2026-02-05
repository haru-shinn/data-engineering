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

USER postgres

ENV PGDATA="/var/lib/postgresql/16/main"

# コンテナ起動時のデフォルトコマンド
CMD ["/bin/bash"]