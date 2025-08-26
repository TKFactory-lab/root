# AGENTS.md — エージェント開発ガイド（簡潔・日本語）

このファイルは、このリポジトリで新しいエージェントやツールを追加する際の具体手順、OpenAI 等の外部 LLM 呼び出し例、ならびに簡易 E2E テストの作り方を示します。

1) 目的と想定
- 目的: `project_manager.py` が使うエージェントに新しいツール（関数）を追加し、エージェントが会話や Redmine 操作を自律でできるようにする。
- 想定ファイル: `project_manager.py` 内に Agent 定義と `@tool` デコレータを使ったツール登録がある（ファイル内のフォールバック実装を参照）。

2) 新しいツールを追加する手順（最短）
- 1. `project_manager.py` を開き、既存の `@tool("...")` パターンを探します。
- 2. 新しい Python 関数を作成し、`@tool("Tool name")` でデコレートします。関数は辞書や Pydantic モデルを受け取り、文字列結果を返すことが簡単で扱いやすいです。
- 3. 既存の Agent（例: `nobunaga_oda`）の `tools=[ ... ]` リストに新しい関数を追加します。
- 4. 変更をコンテナで反映するにはイメージを再ビルドします:

  docker compose build crewai_app
  docker compose up -d crewai_app

3) OpenAI 呼び出し（例）
- ライブラリは任意ですが、`openai` パッケージか `requests` を使った直接呼び出しが多いです。以下は `requests` ベースの最小例（`OPENAI_API_KEY` は環境変数で設定）:

```python
import os, requests, json

def call_openai(prompt: str, model: str = 'gpt-4o-mini') -> str:
    key = os.environ.get('OPENAI_API_KEY')
    if not key:
        raise RuntimeError('OPENAI_API_KEY not set')
    url = 'https://api.openai.com/v1/chat/completions'
    headers = {'Authorization': f'Bearer {key}', 'Content-Type': 'application/json'}
    payload = {
        'model': model,
        'messages': [{'role': 'user', 'content': prompt}],
        'temperature': 0.2,
    }
    r = requests.post(url, headers=headers, data=json.dumps(payload), timeout=30)
    r.raise_for_status()
    j = r.json()
    return j['choices'][0]['message']['content']
```

- 注意: API のバージョンやレスポンス形式は時間と設定で変わります。上の例は最小での使用例です。実装時はエラー処理、レート制御、応答の安全性チェックを追加してください。

4) E2E の簡易テスト（会話パス）
- 1. `tools/socketio_smoke_check.py` を使って受信器と Socket.IO の疎通を確認。
- 2. 受信器をローカルで立ち上げ、`ui/chat.html` または小さな Python スクリプトで `POST /chat` を叩いて会話の流れを確認します。

例: HTTP 会話確認スニペット

```python
import requests

resp = requests.post('http://localhost:8000/chat', json={'agent':'nobu', 'text':'こんにちは'})
print(resp.json())
```

5) デバッグヒント / よくある落とし穴
- `eventlet.monkey_patch()` は必ず Flask/werkzeug より前に実行すること。これを忘れると Gunicorn 起動時にエラーになります。
- Windows 上で編集したシェルスクリプト（`start.sh` 等）が bind-mount によってコンテナ内で実行不可になる問題が頻出します。LF 正規化を忘れずに。
- `CHAT_LOG_DIR` に書かれるログは会話再現で有用です。問題調査時はまずそこを確認してください。

6) 追加提案
- 望むなら、ここに「新しいツールのテンプレート」「ユニットテストの雛形」「Mocked OpenAI のテスト用スタブ」を追加します。どれが欲しいか指示ください。
