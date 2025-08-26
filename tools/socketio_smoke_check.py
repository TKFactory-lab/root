"""
Tiny Socket.IO and HTTP smoke-check for the deployed services.
Usage: python tools/socketio_smoke_check.py --http http://localhost:8000/health --socket http://localhost:8000
"""
import argparse
import sys
import time
import requests

try:
    import socketio
except Exception:
    print('python-socketio not installed. Install with: pip install python-socketio requests')
    sys.exit(2)

parser = argparse.ArgumentParser()
parser.add_argument('--http', help='Health endpoint (HTTP)', required=False)
parser.add_argument('--socket', help='Socket.IO base URL', required=False)
args = parser.parse_args()

if args.http:
    try:
        r = requests.get(args.http, timeout=5)
        print('HTTP', args.http, '->', r.status_code)
        if r.status_code != 200:
            sys.exit(3)
    except Exception as e:
        print('HTTP check failed:', e)
        sys.exit(3)

if args.socket:
    sio = socketio.Client()
    try:
        sio.connect(args.socket, namespaces=['/'], transports=['websocket'], socketio_path='socket.io')
        print('Socket.IO connect OK')
        sio.disconnect()
    except Exception as e:
        print('Socket.IO connect failed:', e)
        sys.exit(4)

print('Smoke check OK')
