# SECURITY_CLEANUP.md

This document explains how to safely remove secrets from the repository and secure the environment after accidental commits.

Summary of actions you can take:

1. Rotate exposed secrets immediately (OpenAI keys, Redmine tokens, CREWAI agent tokens, etc.).
2. Remove plaintext secrets from the repository and rewrite git history if needed.
3. Add `.env.example` to the repo and add `.env` to `.gitignore` (already done).
4. Move to Docker secrets / environment secret store as appropriate.

Recommended workflow to clean history (high level):

- Option A (preferred): Use `git filter-repo` (faster, recommended by GitHub). Example:
  - Backup your repo (clone mirror): `git clone --mirror <repo> repo-mirror.git`
  - Create a file `paths-to-remove.txt` listing files to remove from history (one per line).
  - Run `git filter-repo --invert-paths --paths-from-file paths-to-remove.txt` inside mirror.
  - Push the rewritten history to remote (force push): `git push --force --all && git push --force --tags`.
  - Notify collaborators to reclone or follow recovery steps.

- Option B: Use BFG Repo-Cleaner for common token patterns (simpler UI).

Important notes:

- Rewriting history is destructive. Coordinate with your team, backup, and rotate credentials before/after.
- After history rewrite, any leaked tokens should be considered compromised and rotated.

Quick checklist before proceeding:

- [ ] Rotate all exposed credentials
- [ ] Backup repository (mirror clone)
- [ ] Run git-filter-repo or BFG in the mirror
- [ ] Force-push rewritten history
- [ ] Invalidate leaked tokens / create new credentials
- [ ] Update CI/production with new secrets

If you want, I can:

- Generate the exact `paths-to-remove.txt` for this repo (based on the quick scan I ran) and a step-by-step PowerShell script to perform the mirror + filter-repo steps on Windows.
- Or I can run the recommended non-destructive scan and produce the list of offending files.

Known files found during a quick scan (sanitized in-place):

- `.env` (contained OpenAI key, Redmine tokens, SECRET_KEY_BASE, CREWAI_AGENT_TOKEN) — already sanitized in-place to placeholders.

If you want me to produce a `paths-to-remove.txt` for git-filter-repo it will include `.env` and any other files you confirm for removal.

