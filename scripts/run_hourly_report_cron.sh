#!/bin/bash
# scripts/run_hourly_report_cron.sh
# Simple loop to run create_hourly_report.rb every hour inside the container.
set -euo pipefail
SCRIPT_PATH=/tmp/create_hourly_report.rb
LOG=/tmp/hourly_report_cron.log
# optional env: PROJECT_IDENTIFIER, AUTHOR, WATCHER, SUBJECT, BODY
echo "START_CRON_LOOP: $(date -u)" >> "$LOG"
while true; do
  echo "RUN_AT: $(date -u)" >> "$LOG"
  # run the Rails runner script and append output
  cd /usr/src/redmine || exit 1
  RAILS_ENV=production bundle exec rails runner "$SCRIPT_PATH" >> "$LOG" 2>&1 || echo "RUN_FAILED: $(date -u)" >> "$LOG"
  # sleep until next full hour: compute seconds to next hour
  now=$(date +%s)
  # seconds since epoch to next hour boundary
  next=$(( ( (now / 3600) + 1 ) * 3600 ))
  sleep_secs=$(( next - now ))
  echo "SLEEP_SECS: ${sleep_secs} (until next hour)" >> "$LOG"
  sleep "$sleep_secs"
done
