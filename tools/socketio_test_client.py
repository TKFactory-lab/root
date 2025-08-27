import socketio
import sys
import time

sio = socketio.Client(logger=False, engineio_logger=False)
received = {}

@sio.event
def connect():
    print('connected')

@sio.on('session_started')
def on_session_started(data):
    print('session_started', data)

@sio.on('reply')
def on_reply(data):
    print('reply', data)
    received['reply'] = data

@sio.event
def disconnect():
    print('disconnected')


def run():
    try:
        sio.connect('http://127.0.0.1:5000', transports=['websocket'], socketio_path='socket.io')
    except Exception as e:
        print('connect error', e)
        sys.exit(2)
    # start session
    sio.emit('start_session', {'agent': 'nobu'})
    time.sleep(0.2)
    # send a message
    sio.emit('message', {'session': None, 'agent': 'nobu', 'text': 'テストメッセージ'})
    # wait up to 3s for reply
    for _ in range(30):
        if 'reply' in received:
            print('received reply ok')
            break
        time.sleep(0.1)
    else:
        print('no reply')
    sio.disconnect()

if __name__ == '__main__':
    run()
