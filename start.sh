#!/bin/bash
set -e

# Wait for Redmine service to become available.
# Retry every 10s up to 30 times (~5 minutes).
for i in $(seq 1 30); do
  if curl -sSf "http://redmine:3000/" >/dev/null 2>&1; then
    echo "Redmine service is available"
    break
  else
    echo "Waiting for Redmine to become available... ($i/30)"
    sleep 10
  fi
done

# Run the main Python manager (runs once)
# Start the Socket.IO receiver (so the chat UI can connect) in background
# This script is lightweight; run it in background and log to /tmp/socketio.log
if [ -f ./scripts/crewai_webhook_receiver_socketio.py ]; then
  echo "Starting Socket.IO receiver..."
  nohup python ./scripts/crewai_webhook_receiver_socketio.py --host 0.0.0.0 --port 8000 > /tmp/socketio.log 2>&1 &
  sleep 0.5
fi

# Run the main Python manager (runs once)
python project_manager.py

# Keep the container alive after the manager finishes
exec tail -f /dev/null
