#!/usr/bin/env python3
"""
Create initial Redmine users (nobu, hide, yasu) via REST API using an administrator API key.

Usage (from host, with admin API key set in env):
  REDMINE_URL=http://localhost:3000 REDMINE_ADMIN_API_KEY=... \
  python scripts/create_redmine_users.py

The script will:
- Check if each user exists (by login); skip if present.
- Create the user with a generated password (or from env overrides).
- Save created credentials to ./redmine_user_creds.json (only if new users were created).

Security notes:
- Do NOT commit the generated redmine_user_creds.json to git.
- Prefer passing passwords via environment variables or secret manager.
"""

import os
import json
import secrets
import sys
from typing import Dict

try:
    from redminelib import Redmine
except Exception as e:
    print("ERROR: python-redmine is required. Install with: pip install python-redmine")
    raise

REDMINE_URL = os.getenv("REDMINE_URL", "http://redmine:3000")
ADMIN_KEY = os.getenv("REDMINE_ADMIN_API_KEY")
if not ADMIN_KEY:
    print("ERROR: REDMINE_ADMIN_API_KEY must be set in the environment.")
    sys.exit(2)

# Users to ensure exist. Passwords can be provided via env (NOBU_PW, HIDE_PW, YASU_PW)
USERS = [
    {"login": "nobu", "firstname": "Nobu", "lastname": "Oda", "mail": "nobu@example.com", "pw_env": "NOBU_PW"},
    {"login": "hide", "firstname": "Hide", "lastname": "Toyotomi", "mail": "hide@example.com", "pw_env": "HIDE_PW"},
    {"login": "yasu", "firstname": "Yasu", "lastname": "Tokugawa", "mail": "yasu@example.com", "pw_env": "YASU_PW"},
]

client = Redmine(REDMINE_URL, key=ADMIN_KEY, requests={'timeout': 30})
created: Dict[str, Dict] = {}

for u in USERS:
    login = u["login"]
    print(f"Checking user: {login}")
    try:
        # Try to find existing user by login (name filter). python-redmine allows user filter by name
        found = list(client.user.all(name=login))
    except Exception:
        # Fall back to empty list if filter unsupported
        found = []

    if found:
        user = found[0]
        print(f"  exists: {login} (id={user.id})")
        continue

    # Determine password
    password = os.getenv(u["pw_env"]) or secrets.token_urlsafe(12)

    print(f"  creating: {login} ...")
    try:
        new = client.user.create(
            login=login,
            firstname=u["firstname"],
            lastname=u["lastname"],
            mail=u["mail"],
            password=password,
            must_change_passwd=False,
            status=1,
        )
        created[login] = {"id": new.id, "login": login, "password": password, "mail": u["mail"]}
        print(f"    created id={new.id}")
    except Exception as e:
        print(f"    FAILED to create {login}: {e}")

if created:
    path = os.path.join(os.getcwd(), "redmine_user_creds.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(created, f, indent=2, ensure_ascii=False)
    print(f"Wrote credentials for created users to {path} (DO NOT commit this file)")
else:
    print("No new users were created.")

print("Done.")
