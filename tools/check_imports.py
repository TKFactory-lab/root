import importlib
import sys
pkgs = ['dotenv', 'pydantic', 'redmine', 'redminelib', 'crewai']
for p in pkgs:
    try:
        m = importlib.import_module(p)
        path = getattr(m, '__file__', None)
        print(f"{p}: OK - {path}")
    except Exception as e:
        print(f"{p}: FAIL - {type(e).__name__}: {e}")
print('sys.path:')
for p in sys.path:
    if 'site-packages' in str(p):
        print('  ', p)
