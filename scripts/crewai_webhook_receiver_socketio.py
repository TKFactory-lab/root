"""Socket.IO-based chat webhook receiver exposing `application` for Gunicorn.

This is a dedicated Socket.IO receiver separate from the historical
`crewai_webhook_receiver.py` to avoid overwriting legacy webhook code.
Run with: python scripts/crewai_webhook_receiver_socketio.py --host 0.0.0.0 --port 8000
or via gunicorn: gunicorn -k eventlet -w 1 scripts.crewai_webhook_receiver_socketio:application
"""

import sys
use_eventlet = False
try:
    # Prefer eventlet on non-Windows platforms; on Windows fallback to threading
    if sys.platform != 'win32':
        import eventlet
        # Monkey-patch before importing Flask/werkzeug to avoid runtime errors
        eventlet.monkey_patch()
        use_eventlet = True
    else:
        # Running on Windows: avoid eventlet monkey-patch which can be problematic
        eventlet = None
        use_eventlet = False
except Exception:
    # If eventlet is unavailable or fails to patch, fall back to threading mode
    eventlet = None
    use_eventlet = False

from flask import Flask, request, jsonify
import os as _os
try:
    import openai as _openai
except Exception:
    _openai = None
from flask_socketio import SocketIO, emit, join_room
import socketio as pysocketio
import os
import logging
import json
import time
from uuid import uuid4

logging.basicConfig(level=logging.INFO)

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('FLASK_SECRET', 'dev-secret')
async_mode = 'eventlet' if use_eventlet else 'threading'
socketio = SocketIO(app, cors_allowed_origins='*', async_mode=async_mode, logger=False, engineio_logger=False)

AGENT_NAME = os.environ.get('CREWAI_AGENT_NAME', 'nobu')
CHAT_LOG_DIR = os.environ.get('CHAT_LOG_DIR', '/var/log/crewai_chat')
os.makedirs(CHAT_LOG_DIR, exist_ok=True)


def _save_chat_log(session_id, message_obj):
    try:
        # clean and normalize the configured directory, ensure it exists
        log_dir = (CHAT_LOG_DIR or '/var/log/crewai_chat').strip()
        # normalize path to remove stray spaces or duplicate slashes
        log_dir = os.path.normpath(log_dir)
        os.makedirs(log_dir, exist_ok=True)
        fn = os.path.join(log_dir, f"chat_{session_id}.log")
        with open(fn, 'a', encoding='utf-8') as f:
            f.write(json.dumps(message_obj, ensure_ascii=False) + "\n")
    except Exception:
        logging.exception('Failed to write chat log')


def _call_agent_stub(agent_name, text, context=None):
    """A tiny rule-based responder used when no real agent/backend is configured.

    Behavior:
    - simple greeting detection
    - name inquiries
    - Redmine/tool hints
    - question detection asks for clarification
    - default returns a short acknowledgement with a trimmed summary
    """
    time.sleep(0.05)
    t = (text or '').strip()
    # If OpenAI is available and OPENAI_API_KEY is set, call the Chat API
    try:
        key = _os.environ.get('OPENAI_API_KEY')
        model = _os.environ.get('OPENAI_MODEL', 'gpt-4o-mini')
        if _openai and key:
            _openai.api_key = key
            # Use a simple chat completion request; keep short timeout
            try:
                resp = _openai.ChatCompletion.create(
                    model=model,
                    messages=[{"role": "user", "content": t}],
                    max_tokens=256,
                    temperature=0.6,
                )
                if resp and getattr(resp, 'choices', None):
                    # support dict or object response shapes
                    choice = resp.choices[0]
                    content = (choice.get('message') or choice.message).get('content') if isinstance(choice, dict) else choice.message.content
                    return f"[{agent_name}] " + content.strip()
            except Exception:
                # fall through to rule-based responder on errors
                pass
    except Exception:
        # ignore OpenAI errors and fall back
        pass
    # basic greeting
    if any(g in t for g in ['おは', 'こんにちは', 'こんばんは', 'やっほ', 'おっす']):
        return f"[{agent_name}] こんにちは！ご機嫌いかがですか？"

    # name inquiry
    if '名前' in t or 'なまえ' in t:
        return f"[{agent_name}] 私は{agent_name}です。よろしくお願いします。"

    # thanks / polite
    if 'ありがとう' in t or '助かった' in t:
        return f"[{agent_name}] どういたしまして！他にお手伝いできることはありますか？"

    # Redmine/tool hint
    if 'redmine' in t.lower() or 'チケット' in t or 'プロジェクト' in t:
        return f"[{agent_name}] Redmine 操作をしたい場合は、操作内容（例: create_issue）、プロジェクトID、件名、説明を教えてください。"

    # question detection (Japanese question mark or ending particle)
    if '？' in t or '?' in t or t.endswith('か') or t.endswith('か？'):
        return f"[{agent_name}] いい質問です。もう少し詳しく教えていただけますか？（例: 期待する出力や環境情報）"

    # default: concise acknowledgement + short summary
    summary = t if len(t) <= 120 else (t[:117] + '...')
    return f"[{agent_name}] 受け取りました。要約: {summary}"


@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})


@app.route('/chat', methods=['POST'])
def chat():
    data = request.get_json(force=True, silent=True) or {}
    agent = data.get('agent', AGENT_NAME)
    text = data.get('text')
    session = data.get('session') or str(uuid4())

    if not text:
        return jsonify({'error': 'text required'}), 400

    req = {'session': session, 'agent': agent, 'text': text, 'direction': 'user', 'ts': time.time()}
    _save_chat_log(session, req)
    logging.info('HTTP /chat received: %s', req)

    reply = _call_agent_stub(agent, text)
    resp = {'session': session, 'agent': agent, 'text': reply, 'direction': 'agent', 'ts': time.time()}
    _save_chat_log(session, resp)
    logging.info('HTTP /chat reply: %s', resp)

    return jsonify({'reply': reply, 'session': session}), 200


@socketio.on('connect')
def _on_connect():
    logging.info('socket connected: %s', request.sid)
    emit('connected', {'sid': request.sid})


@socketio.on('start_session')
def _on_start_session(data):
    session = data.get('session') or str(uuid4())
    agent = data.get('agent') or AGENT_NAME
    join_room(session)
    emit('session_started', {'session': session, 'agent': agent}, room=session)
    logging.info('started session %s for %s', session, agent)


@socketio.on('message')
def _on_message(data):
    session = data.get('session')
    agent = data.get('agent') or AGENT_NAME
    text = data.get('text')
    if not session or not text:
        emit('error', {'error': 'session and text required'})
        return
    req = {'session': session, 'agent': agent, 'text': text, 'direction': 'user', 'ts': time.time()}
    _save_chat_log(session, req)

    reply = _call_agent_stub(agent, text)
    resp = {'session': session, 'agent': agent, 'text': reply, 'direction': 'agent', 'ts': time.time()}
    _save_chat_log(session, resp)

    emit('reply', resp, room=session)


@socketio.on('disconnect')
def _on_disconnect():
    logging.info('socket disconnect')


# Expose WSGI application for gunicorn to serve Socket.IO
# Use python-socketio's WSGIApp wrapping the underlying server created
# by Flask-SocketIO (socketio.server).
application = pysocketio.WSGIApp(socketio.server, app)


if __name__ == '__main__':
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument('--host', default='0.0.0.0')
    p.add_argument('--port', default=8000, type=int)
    args = p.parse_args()
    socketio.run(app, host=args.host, port=args.port)
