Redmine init: create users and API tokens

What this does
- `scripts/create_redmine_users.rb` will create or update the users: nobu, hide, yasu.
- It sets nobu as admin, disables self-mail notifications, and writes API tokens from environment variables.

How it's run automatically
- `docker-compose.yml` includes a `redmine_init` one-shot service that waits until Redmine is healthy then copies and runs `scripts/create_redmine_users.rb` inside the Redmine image.

Manual commands
- To run manually inside the running Redmine container:

```powershell
# from the repository root on Windows (PowerShell)
docker compose -f .\docker-compose.yml exec -T redmine bash -lc "cd /usr/src/redmine && NOBUNAGA_API_KEY=$env:NOBUNAGA_API_KEY HIDE_API_KEY=$env:HIDE_API_KEY IEYASU_API_KEY=$env:IEYASU_API_KEY bundle exec rails runner scripts/create_redmine_users.rb"
```

Re-run init from host (one-shot container):

```powershell
# starts a temporary container that runs the script once
docker compose -f .\docker-compose.yml run --rm redmine_init
```

Notes
- The script attempts to be compatible across Redmine versions: it writes to `api_key`/`api_token` if present, otherwise it creates/updates Token-like records.
- If you want quieter logs, the script already omits debug prints in its current state.
