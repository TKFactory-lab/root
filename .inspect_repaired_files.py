from pathlib import Path
import re
files = [
    'scripts/crewai_webhook_receiver.py',
    'project_manager.py'
]
for f in files:
    p = Path(f)
    print('='*40)
    print(f, 'exists', p.exists())
    if not p.exists():
        continue
    b = p.read_bytes()
    print('len', len(b))
    head = b[:500]
    # show raw bytes list for first 80 bytes
    print('first80_bytes:', list(head[:80]))
    # check if file is numeric dump: only digits, spaces, newlines
    s = None
    try:
        s = b.decode('utf-8')
    except Exception:
        s = None
    if s is not None:
        dump_like = bool(re.fullmatch(r"[\d\s\r\n]+", s[:200]))
        print('utf8_decoded_preview:', repr(s[:200]))
        print('looks_like_decimal_dump?', dump_like)
    else:
        print('cannot utf8 decode')
print('='*40)
