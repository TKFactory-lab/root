roadmap_ui container

This folder contains a minimal Dockerfile to run `roadmap_ui.py` as a container.

Build

```powershell
# From repo root
docker build -f ui/Dockerfile -t crewai-roadmap-ui ui
```

Run

```powershell
docker run -d -p 8080:8080 --name crewai-roadmap-ui \
  -e SOME_ENV=VALUE \
  crewai-roadmap-ui
```

Compose snippet (add to your `docker-compose.yml`):

```yaml
roadmap_ui:
  image: crewai-roadmap-ui
  build:
    context: .
    dockerfile: ui/Dockerfile
  ports:
    - "8080:8080"
  environment:
    - SOME_ENV=VALUE
  restart: unless-stopped
```

Notes
- The Dockerfile expects `roadmap_ui.py` at repository root (or adjust COPY paths). It installs packages from `requirements.txt`.
- Adjust env vars and ports to match your deployment.

Additional: Chat UI (local testing)

- A minimal static chat client `ui/chat.html` was added to test the Socket.IO chat server in `scripts/crewai_webhook_receiver.py`.
- To run locally (PowerShell):

```powershell
# Start server in repo root
cd d:\\ai\\crewai\\crewai-docker
. .venv\\Scripts\\Activate.ps1
$env:CHAT_LOG_DIR = Join-Path (Get-Location) 'chat_logs'
python .\\scripts\\crewai_webhook_receiver.py --host 127.0.0.1 --port 8000

# Serve the ui directory and open the page
python -m http.server 8002 -d ui
# Open http://127.0.0.1:8002/chat.html in your browser
```

Note: current agent implementation in the server is a stub that echoes messages; replace `_call_agent_stub` to call the real agent.

## CrewAI ロードマップ UI（運用メモ）

### デプロイ方式
現在のリポジトリではロードマップ UI は独立したコンテナとして起動します（`docker-compose.yml` の `roadmap_ui` サービス）。

- 起動方法
  - `docker compose up -d --build` で `roadmap_ui` を含む全サービスをビルド・起動します。
  - UI はホストの `http://localhost:8001/` でアクセスできます（コンテナが稼働している通りにポートを公開）。

- ライフサイクル
  - UI は `crewai_app` に依存して起動します（`depends_on: - crewai_app`）。
  - UI を別コンテナに分離したことで、ログやスケールが独立して扱えます。

- ログ
  - UI は Flask または組み込みの http.server を使って起動します。コンテナログは `docker compose logs roadmap_ui` で取得してください。

- 注意
  - 以前は UI を `crewai_app` コンテナ内で起動していましたが、競合と運用上の混乱を避けるため分離しました。必要なら再度統合可能です。

## ローカル限定利用メモ（あなたにお願いしたいこと・★★★）
以下はこのマシン上だけで利用する前提の手順と、必ず対応してほしい項目です。外部公開を行わない場合は TLS/ドメイン周りの作業は不要です。

必須（★★★）

1) ★★★ `.env` に必要な環境変数を用意してください（`docker compose` で起動する場合）
   - 少なくとも `REDMINE_URL` / `REDMINE_API_KEY` / `CREWAI_AGENT_TOKEN` 等、実行に必要な値が必要です。
   - 例（実際のシークレットはここに書かないでください）:

```
# .env（例）
REDMINE_URL=http://localhost:3000
REDMINE_API_KEY=xxxx
CREWAI_AGENT_TOKEN=yyyy
```

2) ★★★ サービスを起動していることを確認してください（`docker compose` 推奨）

```powershell
cd D:\ai\crewai\crewai-docker
# ビルド＋デタッチ起動
docker compose up -d --build
# 状態確認
docker compose ps
# ログ確認（必要時）
docker compose logs --tail 200 crewai_app roadmap_ui nginx
```

任意だが推奨（設定次第）

3) ★ UI/チャットをブラウザで見る方法（選択肢）

- A) Compose で起動している場合（通常のセットアップ）
  - Nginx や `roadmap_ui` がポート `8001` を公開していれば次の URL を開いてください。

```
http://127.0.0.1:8001/
# チャットページ（静的ファイル）を直接開く場合（nginx 経由で配置されていれば）
http://127.0.0.1:8001/chat.html
```

- B) 簡易テスト（コンテナを使わずローカルで静的ファイルをサーブする場合）

```powershell
# ui ディレクトリを簡易サーバで公開
cd D:\ai\crewai\crewai-docker
python -m http.server 8002 -d ui
# ブラウザで開く:
# http://127.0.0.1:8002/chat.html
```

4) ★ webhook レシーバをローカルで直接動かす場合（開発用）

```powershell
cd D:\ai\crewai\crewai-docker
# 仮想環境がある場合は有効化
. .venv\Scripts\Activate.ps1
# ログ出力先を設定（任意）
$env:CHAT_LOG_DIR = Join-Path (Get-Location) 'chat_logs'
python .\scripts\crewai_webhook_receiver.py --host 127.0.0.1 --port 8000
```

5) ★ ログやヘルスチェックの確認

```powershell
# コンテナのヘルス状態とログ（問題発生時に実行）
docker compose ps
docker inspect --format "{{json .State.Health}}" crewai_app
docker compose logs --tail 200 crewai_app roadmap_ui nginx
```

トラブルシュートのヒント
- UI が表示されない場合は、`docker compose ps` でポート公開を確認し、`docker compose logs` を確認してください。
- サーバーが 127.0.0.1 でリッスンしているか確認したい場合は、PowerShell で `Invoke-WebRequest http://127.0.0.1:8001/ -UseBasicParsing` を試してください。

注意
- この README はローカル利用向けのメモです。もし将来ドメイン公開や TLS を行う場合は別途作業手順を用意します。

---
