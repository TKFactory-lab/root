@echo off
set CHAT_LOG_DIR=D:\ai\crewai\crewai-docker\chat_logs
python -u scripts\crewai_webhook_receiver_socketio.py --host 127.0.0.1 --port 5000 > receiver.log 2> receiver.err
