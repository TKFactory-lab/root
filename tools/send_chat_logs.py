import requests
import time
import os

url = 'http://127.0.0.1:5000/chat'
for i in range(1,9):
    try:
        payload = {'agent':'nobu','text': f'テストログ生成 {i}'}
        r = requests.post(url, json=payload, timeout=5)
        print(f'chat{i}:', r.status_code, r.json().get('reply'))
    except Exception as e:
        print(f'chat{i} failed:', e)
    time.sleep(0.2)

# list chat_logs
logdir = os.path.join(os.getcwd(), 'chat_logs')
print('\nCHAT_LOG_DIR=', logdir)
if os.path.isdir(logdir):
    files = sorted([os.path.join(logdir, f) for f in os.listdir(logdir) if f.startswith('chat_')], key=os.path.getmtime, reverse=True)
    if files:
        print('latest file:', files[0])
        with open(files[0], 'r', encoding='utf-8') as fh:
            tail = fh.read().splitlines()[-200:]
            print('\n'.join(tail))
    else:
        print('no chat log files found in', logdir)
else:
    print('chat_logs dir not found')
