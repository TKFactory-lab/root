"""
簡易 CrewAI Webhook 受信サービス（Flask）
- 受信した JSON ペイロードを解析し、簡易応答を Redmine の該当 Issue にコメントとして投稿します。
- 本番運用では認証／署名検証やレート制御を必ず追加してください。

使い方（ローカル）:
python -m venv .venv
.\.venv\Scripts\activate
pip install -r scripts/crewai_webhook_requirements.txt
set REDMINE_URL=http://localhost:3000
set REDMINE_API_KEY=<your_redmine_api_key>
python scripts/crewai_webhook_receiver.py

デフォルトで 0.0.0.0:8000 をリッスンします。process_rfps.rb の環境変数 `CREWAI_AGENT_WEBHOOK` に
http://<host>:8000/webhook を設定すれば、受信→Redmine への返信まで自動で行います。
"""
from flask import Flask, request, jsonify
import os
import requests
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

REDMINE_URL = os.environ.get('REDMINE_URL', 'http://redmine:3000')
REDMINE_API_KEY = os.environ.get('REDMINE_API_KEY')

# If REDMINE_API_KEY isn't provided in the environment, try to load a local
# .env file (project root) and look for common token names used in this repo
def load_dotenv(path):
    data = {}
    if not os.path.exists(path):
        return data
    try:
        with open(path, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if '=' in line:
                    k, v = line.split('=', 1)
                    data[k.strip()] = v.strip()
    except Exception:
        return data
    return data

if not REDMINE_API_KEY:
    envfile = os.path.join(os.path.dirname(__file__), '..', '.env')
    envfile = os.path.abspath(envfile)
    dd = load_dotenv(envfile)
    # prefer NOBUNAGA_API_KEY or NOBU-like keys, fallback to any *_API_KEY
    for key in ['NOBUNAGA_API_KEY', 'NOBU_API_KEY', 'NOBUNAGA_TOKEN', 'NOBU_TOKEN']:
        if dd.get(key):
            REDMINE_API_KEY = dd.get(key)
            break
    if not REDMINE_API_KEY:
        for k, v in dd.items():
            if k.endswith('_API_KEY') and v:
                REDMINE_API_KEY = v
                break

logging.info(f'Using REDMINE_URL={REDMINE_URL} REDMINE_API_KEY_SET={bool(REDMINE_API_KEY)}')
AGENT_NAME = os.environ.get('CREWAI_AGENT_NAME', 'crewai-bot')

if not REDMINE_API_KEY:
    logging.warning('環境変数 REDMINE_API_KEY が設定されていません。Redmine への書き込みは失敗します。')


def post_issue_comment(issue_id, text):
    """Redmine にコメントを追加する。"""
    url = f"{REDMINE_URL}/issues/{issue_id}.json"
    headers = {'Content-Type': 'application/json'}
    if REDMINE_API_KEY:
        headers['X-Redmine-API-Key'] = REDMINE_API_KEY
    payload = {'issue': {'notes': text}}
    try:
        r = requests.put(url, json=payload, headers=headers, timeout=10)
        logging.info(f'Posted comment to issue {issue_id}: {r.status_code}')
        return r.status_code, r.text
    except Exception as e:
        logging.exception('Failed to post comment to Redmine')
        return None, str(e)


def find_status_id_by_name(name):
    """Query Redmine for issue status id by name."""
    try:
        url = f"{REDMINE_URL}/issue_statuses.json"
        headers = {}
        if REDMINE_API_KEY:
            headers['X-Redmine-API-Key'] = REDMINE_API_KEY
        r = requests.get(url, headers=headers, timeout=10)
        if r.status_code == 200:
            j = r.json()
            for s in j.get('issue_statuses', []):
                if s.get('name') == name:
                    return s.get('id')
        logging.warning('Could not find status id for %s (HTTP %s)', name, r.status_code if r is not None else 'N/A')
    except Exception:
        logging.exception('Failed to query issue statuses')
    return None


def update_issue_status(issue_id, status_name):
    """Update the issue status to the given status name (via Redmine API)."""
    sid = find_status_id_by_name(status_name)
    if not sid:
        logging.warning('Status id for %s not found; skipping status update', status_name)
        return None, 'status id not found'
    try:
        url = f"{REDMINE_URL}/issues/{issue_id}.json"
        headers = {'Content-Type': 'application/json'}
        if REDMINE_API_KEY:
            headers['X-Redmine-API-Key'] = REDMINE_API_KEY
        payload = {'issue': {'status_id': sid}}
        r = requests.put(url, json=payload, headers=headers, timeout=10)
        logging.info('Updated issue %s status to %s (id=%s): %s', issue_id, status_name, sid, r.status_code)
        return r.status_code, r.text
    except Exception:
        logging.exception('Failed to update issue status')
        return None, 'exception'


@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})


@app.route('/webhook', methods=['POST'])
def webhook():
    data = request.get_json(force=True, silent=True)
    logging.info('Received webhook payload: %s', data)

    # 最低限のパース
    issue = data.get('issue') if isinstance(data, dict) else None
    recipients = data.get('recipients') if isinstance(data, dict) else None
    issue_id = None
    issue_subject = None
    if issue:
        issue_id = issue.get('id')
        issue_subject = issue.get('subject')

    # シンプルな応答文を作る
    if recipients and isinstance(recipients, list) and len(recipients) > 0:
        to = ', '.join(recipients)
    else:
        to = 'nobu, hide, yasu'

    if issue_id:
        reply = f"@{to} 受信しました。プロジェクトを開始します — 自動応答: {AGENT_NAME}"
        # 実際のエージェント処理をここで呼ぶこともできる（外部プロセス呼び出し等）
        status, body = post_issue_comment(issue_id, reply)
        # attempt to set the issue status to Submitted so scheduler will pick it up
        try:
            upd_status, upd_body = update_issue_status(issue_id, 'Submitted')
            logging.info('Status update result: %s', upd_status)
        except Exception:
            logging.exception('Failed during status update')
        # create a trigger file under Redmine files directory so scheduler can pick it up
        try:
            trigger_dir = '/usr/src/redmine/files'
            os.makedirs(trigger_dir, exist_ok=True)
            trigger_path = os.path.join(trigger_dir, f'crewai_trigger_{issue_id}')
            with open(trigger_path, 'w') as tf:
                tf.write(f'triggered_by=webhook\nissue_id={issue_id}\n')
            logging.info('Wrote trigger file %s', trigger_path)
        except Exception:
            logging.exception('Failed to write trigger file')
        return jsonify({'posted': True, 'status': status, 'body': body}), 200
    else:
        return jsonify({'error': 'no issue id in payload'}), 400


if __name__ == '__main__':
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument('--host', default='0.0.0.0')
    p.add_argument('--port', default=8000, type=int)
    args = p.parse_args()
    app.run(host=args.host, port=args.port)
