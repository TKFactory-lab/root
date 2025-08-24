#!/usr/bin/env python3
"""
roadmap_ui.py

簡易なブラウザ UI: `docs/roadmap_reports` 内の Markdown レポート一覧を提供する小さな Flask アプリ。
- / : レポート一覧
- /report/<name> : 指定レポートをプレーン表示

※ 依存を増やさない形で Markdown はシンプルに整形します（厳密な HTML 変換は行いません）。
"""
from __future__ import annotations
import os
from flask import Flask, render_template_string, abort, send_from_directory

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
REPORT_DIR = os.path.join(ROOT, "docs", "roadmap_reports")

# フレームワークの有無で挙動を変える
try:
    HAVE_FLASK = True
except Exception:
    HAVE_FLASK = False

app = Flask(__name__)

INDEX_TMPL = """
<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>Crewai ロードマップ報告一覧</title>
<style>body{font-family:Inter,Segoe UI,Arial;margin:2rem;} pre{white-space:pre-wrap;}</style>
</head>
<body>
<h1>Crewai ロードマップ報告一覧</h1>
<ul>
{% for name in files %}
  <li><a href="/report/{{ name | urlencode }}">{{ name }}</a></li>
{% endfor %}
</ul>
<p><em>注: レポートは自動生成されます。ローカルで生成したファイルが表示されます。</em></p>
</body>
</html>
"""

REPORT_TMPL = """
<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>{{ name }}</title>
<style>body{font-family:Inter,Segoe UI,Arial;margin:2rem;} pre{white-space:pre-wrap;background:#f7f7f7;padding:1rem;border-radius:6px;}</style>
</head>
<body>
<p><a href="/">← 一覧へ戻る</a></p>
<h1>{{ name }}</h1>
<pre>{{ content }}</pre>
</body>
</html>
"""


@app.route('/')
def index():
    try:
        files = sorted(os.listdir(REPORT_DIR))
    except FileNotFoundError:
        files = []
    return render_template_string(INDEX_TMPL, files=files)


@app.route('/report/<path:name>')
def report(name):
    safe_path = os.path.join(REPORT_DIR, name)
    # basic check
    if not os.path.isfile(safe_path):
        abort(404)
    with open(safe_path, 'r', encoding='utf-8') as f:
        content = f.read()
    return render_template_string(REPORT_TMPL, name=name, content=content)


if __name__ == '__main__':
    # デフォルトでローカルホスト:8001
    # Flask が使える場合は Flask で起動、なければ組み込みの http.server で簡易表示
    try:
        # flask が存在するか確認
        import flask  # type: ignore
        app.run(host='0.0.0.0', port=8001)
    except Exception:
        import http.server
        import socketserver
        import urllib.parse
        import html

        PORT = 8001

        class Handler(http.server.SimpleHTTPRequestHandler):
            def do_GET(self):
                parsed = urllib.parse.urlparse(self.path)
                if parsed.path == '/' or parsed.path == '':
                    try:
                        files = sorted(os.listdir(REPORT_DIR))
                    except Exception:
                        files = []
                    content = '<html><head><meta charset="utf-8"><title>Crewai ロードマップ報告一覧</title></head><body>'
                    content += '<h1>Crewai ロードマップ報告一覧</h1><ul>'
                    for name in files:
                        content += f'<li><a href="/report/{urllib.parse.quote(name)}">{html.escape(name)}</a></li>'
                    content += '</ul><p><em>注: レポートは自動生成されます。</em></p></body></html>'
                    self.send_response(200)
                    self.send_header('Content-type','text/html; charset=utf-8')
                    self.end_headers()
                    self.wfile.write(content.encode('utf-8'))
                elif parsed.path.startswith('/report/'):
                    name = urllib.parse.unquote(parsed.path[len('/report/'):])
                    safe_path = os.path.join(REPORT_DIR, name)
                    if not os.path.isfile(safe_path):
                        self.send_error(404)
                        return
                    with open(safe_path, 'r', encoding='utf-8') as f:
                        data = f.read()
                    page = f'<html><head><meta charset="utf-8"><title>{html.escape(name)}</title></head><body>'
                    page += f'<p><a href="/">← 一覧へ戻る</a></p><h1>{html.escape(name)}</h1><pre>{html.escape(data)}</pre></body></html>'
                    self.send_response(200)
                    self.send_header('Content-type','text/html; charset=utf-8')
                    self.end_headers()
                    self.wfile.write(page.encode('utf-8'))
                else:
                    return http.server.SimpleHTTPRequestHandler.do_GET(self)

        with socketserver.TCPServer(('', PORT), Handler) as httpd:
            print(f"Serving at port {PORT} (fallback http.server)")
            httpd.serve_forever()
