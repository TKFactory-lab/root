CrewAI Docker 簡易 README

概要
----
このリポジトリは CrewAI 開発・運用向けの Docker 構成と運用メモを含みます。

主な内容
----
- webhook 受信 / Socket.IO ベースのチャットサーバ
- Redmine 連携スクリプト
- UI（`ui/chat.html` を使った簡易クライアント）
- docker-compose 設定、起動/監視手順

前提
----
- Docker と docker-compose がインストールされていること。
- Windows で運用する場合、`OPENAI_API_KEY` はシステムまたはユーザー環境変数として設定することを推奨します（セキュリティ上 .env に直接書かないため）。
  例（管理者 PowerShell でシステムに永続化）:

  setx OPENAI_API_KEY "<your-key>" /M

クイックスタート
----
1. リポジトリのルートで `.env` を確認または `.env.example` を参照して作成します。
2. Windows の場合は上記で `OPENAI_API_KEY` を設定します。
3. コンテナをビルドして起動します:

   docker-compose up -d --build

4. サービス確認:
   - アプリのヘルスチェック: http://localhost:5000/health
   - UI (nginx 経由): http://localhost:8080/ または `ui/chat.html` を開く

UI の使い方（簡易）
----
- ブラウザで `ui/chat.html` を開き、接続先ホストに `http://localhost:8080`（または実際のホスト）を指定して接続してください。
- Socket.IO は初期の HTTP GET で 404 を返すことがありますが、Socket.IO 接続自体が成功すればチャットが動作します。

文字化け（エンコード）対処
----
GitHub 上で README が文字化けしている場合、ファイルが UTF-16 等で保存されている可能性があります。PowerShell で UTF-8 に再エクスポートする例:

  git show origin/my-work-backup:README.md | Out-File -FilePath README.md -Encoding utf8
  git add README.md
  git commit -m "Re-encode README as UTF-8"
  git push origin HEAD

上記で修正されない場合は、ローカルの編集ツール（VSCode など）でエンコーディングを UTF-8 に変えて保存し、同様にコミット／プッシュしてください。

トラブルシューティング（短いヒント）
----
- OPENAI_API_KEY が未設定だと AI 呼び出しが失敗します（ログ: 認証エラー）。
- Gunicorn / eventlet / socketio の起動エラーが出る場合は、該当ログのエラーメッセージ（ImportError や NameError）を貼ってください。

連絡先・サポート
----
問題が続く場合、発生している症状（ログ抜粋、コマンド出力）を貼ってください。こちらで追加対応します。

---
（このファイルは UTF-8 で保存されています）