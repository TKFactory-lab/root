# Rotate Secrets — Quick Guide for CrewAI Operators

This short guide shows the minimal, safe steps to rotate exposed credentials and bring the service back online.
Follow the steps in order. If you are unsure, stop and ask the project lead.

Why rotate first
- Any token that was committed or exposed must be considered compromised. Rotating (recreating) the token removes the old one and prevents unauthorized use.

Checklist (high level)
1. Identify which secrets to rotate (see list below).
2. Generate new credentials in each provider's console (OpenAI, Redmine, internal agent management, etc.).
3. Backup current `.env` (the helper script can create a backup).
4. Update `.env` with new values (use `tools/update_env_values.ps1` to make this easier).
5. Restart services (Docker Compose) to pick up new values.
6. Verify end-to-end (create a test RFP or send a webhook) and confirm services work.
7. Invalidate old credentials where applicable.

Which values to rotate (common in this repo)
- OPENAI_API_KEY
- NOBUNAGA_API_KEY
- IEYASU_API_KEY
- HIDE_API_KEY
- SECRET_KEY_BASE (Rails/scheduler secret)
- CREWAI_AGENT_TOKEN
- Any Redmine personal access tokens used by scripts (`NOBUNAGA_API_KEY` etc.)

Interactive helper
- A helper script `tools/update_env_values.ps1` is provided. It will:
  - Backup `.env` to `.env.bak.<timestamp>`
  - Prompt you to paste new secret values securely (input hidden)
  - Update only the keys you choose, leaving other keys intact
  - NOT print secrets anywhere

Usage example (PowerShell):

```powershell
# from repo root
.\tools\update_env_values.ps1
```

Restarting services

```powershell
# restart docker compose services to load new env
.\tools\manage_crewai.ps1 stop
.\tools\manage_crewai.ps1 start
```

Validation tests (simple)
- Create a test RFP via the provided script or UI and confirm the scheduler and agent reply. See `test_crewai.py` and `scripts/create_test_rfp.rb` for examples.

After rotation
- Run `tools/run_git_filter_repo.ps1` (in `SECURITY_CLEANUP.md`) to remove any committed files from history if needed. Only do this after rotation and after backing up the repo.
- Notify the team that secrets were rotated and that history rewrite (if performed) requires all collaborators to reclone.

If you want, I can run the interactive helper on your machine (I won't see your secrets) or produce a step-by-step email template to notify the team. Choose which next action you prefer.
