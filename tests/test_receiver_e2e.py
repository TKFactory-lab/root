import os
import sys
import time
import glob
import subprocess
import requests


def wait_for_health(url, timeout=15.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            r = requests.get(url, timeout=1.0)
            if r.status_code == 200:
                return True
        except Exception:
            pass
        time.sleep(0.5)
    return False


def test_receiver_writes_chat_logs(tmp_path):
    """起動中の受信器に /chat を POST して chat_logs にファイルが生成されることを確認するE2Eテスト。

    - 受信器をサブプロセスで起動（環境変数 CHAT_LOG_DIR を tmp dir に設定）
    - /health が立ち上がるのを待つ
    - /chat を複数回 POST
    - chat_logs に chat_*.log が生成され、中身に送信したテキストが含まれることを検証
    """

    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    script = os.path.join(repo_root, 'scripts', 'crewai_webhook_receiver_socketio.py')
    assert os.path.exists(script), f"受信器スクリプトが見つかりません: {script}"

    port = 5001
    host = '127.0.0.1'
    base_url = f'http://{host}:{port}'
    health_url = f'{base_url}/health'
    chat_url = f'{base_url}/chat'

    env = os.environ.copy()
    env['CHAT_LOG_DIR'] = str(tmp_path)

    # prepare files for receiver stdout/stderr so CI can collect them
    out_path = os.path.join(str(tmp_path), 'receiver.out')
    err_path = os.path.join(str(tmp_path), 'receiver.err')
    out_f = open(out_path, 'wb')
    err_f = open(err_path, 'wb')

    # start receiver (write logs to files to avoid buffering issues)
    proc = subprocess.Popen([sys.executable, '-u', script, '--host', host, '--port', str(port)], env=env, cwd=repo_root, stdout=out_f, stderr=err_f)

    try:
        started = wait_for_health(health_url, timeout=30.0)
        if not started:
            # dump receiver logs to help debugging
            out_f.flush(); err_f.flush()
            with open(out_path, 'rb') as rfo, open(err_path, 'rb') as rfe:
                ro = rfo.read().decode('utf-8', errors='replace')
                re = rfe.read().decode('utf-8', errors='replace')
            raise AssertionError(f"受信器の /health がタイムアウトしました\n--- STDOUT ---\n{ro}\n--- STDERR ---\n{re}")

        # POST messages
        texts = [f'テストログ生成 {i}' for i in range(1, 4)]
        for t in texts:
            payload = {'agent': 'nobu', 'text': t}
            r = requests.post(chat_url, json=payload, timeout=5.0)
            assert r.status_code == 200, f'/chat 応答が200でない: {r.status_code} {r.text}'

        # give receiver a moment to flush logs
        time.sleep(1.0)

        logs = glob.glob(os.path.join(str(tmp_path), 'chat_*.log'))
        assert logs, 'chat_logs にファイルが生成されませんでした'

        # check contents of newest log
        newest = max(logs, key=os.path.getmtime)
        with open(newest, 'r', encoding='utf-8') as fh:
            content = fh.read()

        for t in texts:
            assert t in content, f'ログに期待するテキストが含まれません: {t}'

    finally:
        # cleanup process
        try:
            proc.terminate()
            proc.wait(timeout=5)
        except Exception:
            proc.kill()
        finally:
            try:
                out_f.close()
            except Exception:
                pass
            try:
                err_f.close()
            except Exception:
                pass
