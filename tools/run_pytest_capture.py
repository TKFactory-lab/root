import subprocess, sys
p = subprocess.Popen([sys.executable,'-m','pytest','-q','tests/test_receiver_e2e.py::test_receiver_writes_chat_logs','-s'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
out, _ = p.communicate(timeout=120)
print(out.decode('utf-8', errors='replace'))
