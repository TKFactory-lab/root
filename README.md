## CrewAI リポジトリ（簡易 README）

短く：このリポジトリは Redmine と連携する CrewAI サービスの開発用ワークスペースです。
主要な要素は Docker Compose ベースのサービス群（crewai_app、redmine、db、nginx、rfp_scheduler 等）と、ブラウザで使うチャット UI (`ui/chat.html`) です。

### 必要な前提
- Docker / Docker Compose
- Git と Git LFS （大きなネイティブバイナリを LFS で管理しています）
- Windows 環境での開発: PowerShell を利用します（README の手順は PowerShell 向けの例を含みます）

### 重要：OPENAI_API_KEY の扱い
- セキュリティのため、`OPENAI_API_KEY` は可能な限り Windows の環境変数（User または System）に設定してください。
  例（PowerShell, User スコープ）:

  ```powershell
  [Environment]::SetEnvironmentVariable('OPENAI_API_KEY','sk-xxxx-REPLACE','User')
  ```

### 初回セットアップ（簡易）
1. Git LFS をインストールして有効化
   ```powershell
   git lfs install --local
   ```
2. `.env` を確認して必要な値（REDMINE_URL, REDMINE_API_KEY 等）をセットする（既に `.env` に例が含まれています）。
   - `CREWAI_AGENT_WEBHOOK_INTERNAL` はコンテナ間用（例: http://crewai_app:8000/webhook）
   - `CREWAI_AGENT_WEBHOOK_HOST` はホスト/ブラウザからのアクセス用（例: http://localhost:8000/webhook）

### 起動（開発用）
```powershell
# リポジトリルートで
docker compose up -d --build
docker compose logs -f crewai_app
```

### ブラウザチャット UI
- `ui/chat.html` をブラウザで開き、Socket.IO で接続して `nobu` などのエージェントと会話できます。
- production では Nginx + Gunicorn を経由する構成があります（`docker-compose.yml` を参照）。

### Git LFS / 大ファイルについて（このリポジトリの現状）
- 大きなネイティブ拡張（`modules/**/*.so` 等）は Git LFS に移行済みです（履歴書き換えを実施）。
- 履歴を書き換えたため、既にクローン済みの開発者はリセットが必要になります:
  ```powershell
  git fetch origin
  git reset --hard origin/my-work-backup
  ```

### 今後の注意点
- バイナリや仮想環境を誤ってコミットしないよう `.gitignore` を整備しました。既にコミット済みの大ファイルは LFS に移しました。
- Git LFS のストレージ制限に注意してください（プランによって上限あり）。

### トラブルシュート - 代表例
- `.gitattributes` で `is not a valid attribute name` という警告が出る場合、先頭に余分なテキストや否定パターンがある可能性があります。リポジトリにはヘッダコメント化と無害化を適用済みです。
- チャット UI が接続できない場合：`crewai_app` コンテナが起動しているか、`/health` が OK か確認し、Nginx のプロキシ設定（`nginx.conf`）とポートをチェックしてください。

### 連絡先 / 次のアクション
- 既存クローンを持つメンバーへ履歴書き換えの周知を行ってください。
- README の補足（より詳細なデプロイ手順、TLS 設定、CI ワークフローなど）を追加希望なら指示してください。

### 補助ツールとCI

ローカルで `tools/socketio_smoke_check.py` を実行する場合、Python と以下のパッケージが必要です:

```powershell
python -m pip install requests python-socketio
```

短い README を追加しました。必要であれば英語版や詳細な運用ドキュメントを追加します.
