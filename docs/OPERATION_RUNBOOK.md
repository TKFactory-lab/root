# Operation Runbook — CrewAI (short)

Purpose
- Short operational runbook for starting, stopping, backups, secrets, and emergency recovery for the CrewAI project in this repo.

Quick start
1. Ensure .env is filled (see `.env.example` or repository docs). Key vars:
   - REDMINE_URL, REDMINE_API_KEY
   - CREWAI_AGENT_TOKEN, CREWAI_AGENT_WEBHOOK
   - SLACK_WEBHOOK_URL (if used)
2. Start containers (root of repo):

```powershell
# Run from repo root
docker compose up -d --build
```
3. Stop:

```powershell
docker compose down
```

Secrets and management
- Store sensitive secrets in your organization vault (Azure Key Vault / AWS Secrets Manager / GitHub Secrets) and inject into the environment used by Docker Compose or Actions. Do not commit secrets to git.
- GitHub Actions: keep `SLACK_WEBHOOK_URL` and similar in repository secrets; Actions workflow `.github/workflows/roadmap_report.yml` reads envs from secrets.

Backups
- Volumes: identify docker volumes (db, uploads). Create periodic backup of DB and uploads.
- Recommended quick DB dump (Postgres example):

```powershell
# Example for container named crewai_db
docker exec -t crewai_db pg_dumpall -c -U postgres > db-backup-$(Get-Date -Format yyyyMMdd).sql
```

- Files: back up any mounted file directories under `files/` and `log/`.

Slack / Integrations
- Confirm Incoming Webhooks and tokens remain valid after plan changes. If you rely on 1:1 connectors, confirm they persist in Free plan.
- If you need to export channel history, use Slack export or API scripts.

Scheduled jobs
- Windows: `scripts\schedule_roadmap_report.ps1` registers a scheduled task to run the report script on Windows.
- GitHub Actions: `.github/workflows/roadmap_report.yml` contains a scheduled workflow that can be used instead of local scheduling.

Monitoring & alerts
- Add a simple healthcheck endpoint to `crewai_webhook_receiver.py` and configure external monitor or a container-level restart policy:
  - `restart: unless-stopped` in compose or `restart: on-failure` as appropriate.

Emergency recovery checklist (short)
1. If service fails, check logs in `log/` and container logs: `docker compose logs -f`.
2. If DB corrupted, restore from the most recent SQL dump.
3. If Slack/webhook tokens expired, reissue tokens and update secrets.

Further improvements (next steps)
- Add automated backup job (Daily) and retention policy.
- Migrate large binary files to Git LFS and add a pre-commit check.
- Containerize `roadmap_ui.py` (template provided in `ui/` directory).

Contact
- Repository maintainers: check `README` or project_manager contacts.

