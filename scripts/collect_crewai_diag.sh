#!/bin/sh
# Safe diagnostic collector for CrewAI/Redmine workspace
# - Read-only, gathers logs and env info into ./crewai_diag.txt
# - Run from project root: sh ./scripts/collect_crewai_diag.sh

OUT="$(pwd)/crewai_diag.txt"
echo "Collecting CrewAI diagnostics: $(date)" > "$OUT"

echo "\n===== .env (tail 200) =====" >> "$OUT"
if [ -f .env ]; then
  tail -n 200 .env >> "$OUT" 2>/dev/null || true
else
  echo "no .env file found" >> "$OUT"
fi

echo "\n===== docker-compose ps =====" >> "$OUT"
docker-compose ps --all >> "$OUT" 2>&1 || true

echo "\n===== docker-compose logs -- crewai_app (tail 200) =====" >> "$OUT"
docker-compose logs --no-color --tail 200 crewai_app >> "$OUT" 2>&1 || true

echo "\n===== /var/log/crewai_webhook.log (inside crewai_app) =====" >> "$OUT"
docker-compose exec -T crewai_app sh -c 'cat /var/log/crewai_webhook.log 2>/dev/null || true' >> "$OUT" 2>&1 || true

echo "\n===== python / pip / packages (inside crewai_app) =====" >> "$OUT"
docker-compose exec -T crewai_app sh -c 'python --version 2>/dev/null || true; pip --version 2>/dev/null || true; pip show flask || true; pip show requests || true' >> "$OUT" 2>&1 || true

echo "\n===== listen ports inside crewai_app =====" >> "$OUT"
docker-compose exec -T crewai_app sh -c 'ss -lntp 2>/dev/null || netstat -lntp 2>/dev/null || true' >> "$OUT" 2>&1 || true

echo "\n===== internal health check (crewai_app) =====" >> "$OUT"
docker-compose exec -T crewai_app sh -c 'curl -sS --max-time 5 http://127.0.0.1:8000/health || true' >> "$OUT" 2>&1 || true

echo "\n===== rfp_scheduler output file =====" >> "$OUT"
docker-compose exec -T rfp_scheduler sh -c 'cat /usr/src/redmine/files/crewai_process_rfps_out.txt 2>/dev/null || true' >> "$OUT" 2>&1 || true

echo "\n===== ruby -c process_rfps.rb (inside rfp_scheduler) =====" >> "$OUT"
docker-compose exec -T rfp_scheduler sh -c 'ruby -c /usr/src/redmine/scripts/process_rfps.rb 2>&1 || true' >> "$OUT" 2>&1 || true

echo "\n===== quick Redmine reachable check (from host) =====" >> "$OUT"
# try curl to redmine service
curl -sS --max-time 5 http://redmine:3000/ || echo "redmine unreachable from host/docker network" >> "$OUT" 2>&1 || true

echo "\nDIAG_COLLECTED: $OUT"

echo "Wrote diagnostics to: $OUT"
