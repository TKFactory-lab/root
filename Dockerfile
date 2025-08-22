# ベースイメージとしてPython 3.11を使用
FROM python:3.11-slim

# 作業ディレクトリを設定
WORKDIR /app

# 必要なシステム依存関係をインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    libpq-dev \
    netcat-traditional \
    curl \
    && rm -rf /var/lib/apt/lists/*

# requirements.txt を先にコピーしてからインストール（依存関係の確実な解決のため）
COPY requirements.txt ./
RUN python -m pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt
    
# アプリケーションコードをコンテナにコピーする
COPY . .

# start.shに実行権限を付与する
RUN chmod +x ./start.sh

# コンテナ起動時にstart.shを実行する
CMD ["./start.sh"]
