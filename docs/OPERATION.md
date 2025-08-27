# CrewAI — Operation Guide (non-technical)

This file explains the simplest, safest steps for the CrewAI team to operate the local environment.
Keep this short and follow the numbered steps.

Prerequisites
- Docker Desktop installed and running.
- Git installed.
- You have a local copy of the repository (this folder).

Quick start (one-command)
- Open PowerShell, change to the repository root, then run:

```powershell
# starts services in the background
.\tools\manage_crewai.ps1 start
```

Stop services

```powershell
.\tools\manage_crewai.ps1 stop
```

Check status

```powershell
.\tools\manage_crewai.ps1 status
```

Checklist to prepare before starting (do these once)
1. Copy `.env.example` to `.env` in the repo root and fill values. If you are unsure, ask the team lead for the correct tokens.
2. Do NOT commit `.env` to git. It is ignored by `.gitignore`.
3. If you find any leaked token in documentation or messages, rotate the credential immediately and notify the team.

Common tasks (non-destructive helpers)
- Validate environment file exists and values are non-placeholder:

```powershell
.\tools\manage_crewai.ps1 check-env
```

- Create a backup of the repository (recommended before any history-rewrite):

```powershell
.\tools\manage_crewai.ps1 backup
```

History cleanup (advanced — read SECURITY_CLEANUP.md first)
- A helper for history rewrite exists at `tools/run_git_filter_repo.ps1` and a conservative `paths-to-remove.txt` was created.
- DO NOT run history rewrite until you have rotated any exposed credentials and communicated with collaborators.

If something breaks
- Collect the output of the last command and open an issue attaching the output.
- If containers fail to start, try `docker desktop` and check logs: `docker compose logs --tail 100`.

Where to get help
- Ask the CrewAI on-call or project lead and provide the error text and the steps you ran.

Safety notes
- Never paste secret tokens into chat or issue trackers.
- After any history-rewrite, all collaborators must reclone. See `SECURITY_CLEANUP.md`.


