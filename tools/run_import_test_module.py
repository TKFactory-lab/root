import sys
import os
repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, repo_root)
import tests.test_receiver_e2e as t
import inspect
print('module imported, functions:', [n for n,v in inspect.getmembers(t) if inspect.isfunction(v)])
