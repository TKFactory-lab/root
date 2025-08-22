自動実行について

`redmine_init` サービスは Redmine コンテナが healthy になった後に `scripts/create_redmine_users.rb` を実行します。

必須環境変数
- `REDMINE_ADMIN_API_KEY` : Redmine 管理者の API キー（自動作成用）。
- `REDMINE_URL` : Redmine の URL（.env に既にあるはずです）。
- `NOBUNAGA_API_KEY`, `HIDE_API_KEY`, `IEYASU_API_KEY` : ユーザの API キーを事前に設定したい場合に使用します。指定しない場合はスクリプトがランダムキーを生成し、Redmine 内で設定します。

実行方法
1. `.env` に `REDMINE_ADMIN_API_KEY` を追加します（例: `REDMINE_ADMIN_API_KEY=...`）。
2. `docker compose up -d` を実行すると `redmine_init` が Redmine 起動後に自動実行されます。

セキュリティ
- `REDMINE_ADMIN_API_KEY` は機密情報です。公開リポジトリに追加しないでください。
- 生成された `redmine_user_creds.json` は永続化されます。必ず .gitignore に追加するか手動で削除してください。
