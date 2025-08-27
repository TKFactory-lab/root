from scripts import crewai_webhook_receiver_socketio as server
import json

app = server.app

with app.test_client() as c:
    r = c.get('/health')
    print('GET /health', r.status_code, r.get_data(as_text=True))

    payload = {'agent': 'nobu', 'text': 'ヘルプテスト'}
    r2 = c.post('/chat', data=json.dumps(payload), content_type='application/json')
    print('POST /chat', r2.status_code, r2.get_data(as_text=True))
