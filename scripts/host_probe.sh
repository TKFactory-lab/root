#!/bin/sh
set -e
OUT=/tmp/probe_output.txt
echo "RUBY_C_START" > "$OUT"
ruby -c /usr/src/redmine/scripts/process_rfps.rb >> "$OUT" 2>&1 || true
echo "RUBY_C_END" >> "$OUT"

echo "WEBHOOK_HTTP_START" >> "$OUT"
# use env var if present
curl -s -o /tmp/webhook_body -w "HTTP_CODE:%{http_code}" ${CREWAI_AGENT_WEBHOOK:-http://crewai_app:8000/webhook} >> "$OUT" 2>&1 || true
cat /tmp/webhook_body 2>/dev/null >> "$OUT" || true
echo "\nWEBHOOK_HTTP_END" >> "$OUT"

echo "RUN_START" >> "$OUT"
ruby /usr/src/redmine/scripts/process_rfps.rb >> "$OUT" 2>&1 || true
echo "RUN_END" >> "$OUT"

exit 0
