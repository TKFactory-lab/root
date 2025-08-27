#!/usr/bin/env python3
"""
Simple checkpoint writer for interactive coding sessions.

Usage:
  python tools/assistant_checkpoint.py "Short title" "Detailed notes..."

It writes a markdown file into .assistant_checkpoints/<timestamp>_title.md
"""
from __future__ import annotations
import sys
import os
from datetime import datetime


def safe_filename(s: str) -> str:
    keep = "abcdefghijklmnopqrstuvwxyz0123456789-_."
    s = s.lower().replace(' ', '_')
    return ''.join(c for c in s if c in keep)[:60]


def main():
    if len(sys.argv) < 2:
        print('Usage: assistant_checkpoint.py "Title" "optional long notes"')
        sys.exit(2)
    title = sys.argv[1]
    notes = sys.argv[2] if len(sys.argv) > 2 else ''

    base = os.path.join(os.getcwd(), '.assistant_checkpoints')
    os.makedirs(base, exist_ok=True)
    ts = datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    fn = f"{ts}_{safe_filename(title)}.md"
    path = os.path.join(base, fn)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(f"# {title}\n\n")
        f.write(f"Created: {ts} UTC\n\n")
        f.write(notes + '\n')

    print('Wrote checkpoint:', path)


if __name__ == '__main__':
    main()
