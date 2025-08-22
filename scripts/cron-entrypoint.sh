#!/bin/bash
set -euo pipefail

# Simple scheduler: run tasks once at start and then every hour.
# It uses rails runner inside the redmine container's app directory.

LOG_DIR=/tmp
SCRIPTS_DIR=/usr/src/redmine/scripts
APP_DIR=/usr/src/redmine

# Ensure essential rails env vars are present for rails runner
export RAILS_ENV="${RAILS_ENV:-production}"
# SECRET_KEY_BASE must be provided via environment (.env or compose). Do not hardcode here.
if [ -z "${SECRET_KEY_BASE:-}" ]; then
  echo "SCHEDULER: WARNING SECRET_KEY_BASE not set; rails may refuse to boot" >> "$LOG_DIR/scheduler.log"
fi

run_once() {
  echo "SCHEDULER: running notify_rfps.rb $(date)" >> "$LOG_DIR/scheduler.log"
  if [ -f "$SCRIPTS_DIR/notify_rfps.rb" ]; then
    (cd "$APP_DIR" && rails runner "$SCRIPTS_DIR/notify_rfps.rb") > "$LOG_DIR/notify_rfps_out.txt" 2>&1 || true
  fi
  echo "SCHEDULER: running process_rfps.rb $(date)" >> "$LOG_DIR/scheduler.log"
  if [ -f "$SCRIPTS_DIR/process_rfps.rb" ]; then
    (cd "$APP_DIR" && rails runner "$SCRIPTS_DIR/process_rfps.rb") > "$LOG_DIR/process_rfps_out.txt" 2>&1 || true
  fi
}

ensure_database_yml() {
  DB_HOST="${REDMINE_DB_MYSQL:-db}"
  DB_NAME="${REDMINE_DB_DATABASE:-redmine_prod}"
  DB_USER="${REDMINE_DB_USERNAME:-redmine}"
  DB_PASS="${REDMINE_DB_PASSWORD:-secret}"
  DB_PORT="${REDMINE_DB_PORT:-3306}"
  CFG="$APP_DIR/config/database.yml"
  if [ ! -f "$CFG" ]; then
    echo "SCHEDULER: creating $CFG" >> "$LOG_DIR/scheduler.log"
    mkdir -p "$(dirname "$CFG")"
    cat > "$CFG" <<EOF
production:
  adapter: mysql2
  host: "${DB_HOST}"
  port: "${DB_PORT}"
  username: "${DB_USER}"
  password: "${DB_PASS}"
  database: "${DB_NAME}"
EOF
  fi
}

# Ensure database config exists then run once on container start
ensure_database_yml
run_once

# Log masked CrewAI env for debugging
mask() { echo "$1" | sed -E 's/(.{4}).*(.{4})/\1...\2/'; }
echo "SCHEDULER: CREWAI_AGENT_WEBHOOK=${CREWAI_AGENT_WEBHOOK:-}<set>" >> "$LOG_DIR/scheduler.log"
if [ -n "${CREWAI_AGENT_TOKEN:-}" ]; then
  echo "SCHEDULER: CREWAI_AGENT_TOKEN=[MASKED:$(mask ${CREWAI_AGENT_TOKEN})]" >> "$LOG_DIR/scheduler.log"
else
  echo "SCHEDULER: CREWAI_AGENT_TOKEN=<missing>" >> "$LOG_DIR/scheduler.log"
fi
echo "SCHEDULER: CREWAI_AGENT_USERS=${CREWAI_AGENT_USERS:-nobu,hide,yasu}" >> "$LOG_DIR/scheduler.log"

# Sleep loop: run hourly
while true; do
  sleep 3600
  run_once
done
