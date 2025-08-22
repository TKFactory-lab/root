使い方: Redmine 初期ユーザ作成スクリプト

概要
---
`create_redmine_users.py` は Redmine 管理者の API キーを使って、nobu/hide/yasu のユーザを自動作成します。作成済みのユーザはスキップします。

前提
---
- Redmine が起動して HTTP でアクセス可能であること（例: http://localhost:3000）。
- python-redmine がインストールされていること（`pip install python-redmine`）。
- 管理者 API キーを取得して環境変数 `REDMINE_ADMIN_API_KEY` に設定すること。

使い方（例）
---
Windows PowerShell の例:

```powershell
# Redmine がローカルで 3000 ポートで動いている想定
$env:REDMINE_URL = "http://localhost:3000"
$env:REDMINE_ADMIN_API_KEY = "<your-admin-api-key>"
python .\scripts\create_redmine_users.py
```

任意: パスワードを指定する

```powershell
$env:NOBU_PW = "StrongPass1!"
$env:HIDE_PW = "StrongPass2!"
$env:YASU_PW = "StrongPass3!"
python .\scripts\create_redmine_users.py
```

出力
---
- 既存ユーザはスキップされます。
- 新たに作成したユーザのログイン情報は `redmine_user_creds.json` に出力されます。絶対にコミットしないでください。

注意
---
- スクリプトは管理者 API キーを使用します。キーの取り扱いに注意してください。
- まずテスト環境で実行して挙動を確認してください。
