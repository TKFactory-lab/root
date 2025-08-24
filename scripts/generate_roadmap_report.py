#!/usr/bin/env python3
"""
generate_roadmap_report.py

シンプルなロードマップ定期レポート生成スクリプト（日本語出力）。
- オプションで `docs/roadmap_state.json` を読み込む（存在すればそちらを優先）。
- 出力は `docs/roadmap_reports/YYYY-MM-DD_HHMMSS.md` と `log/roadmap_reports.log` に保存。
"""
from __future__ import annotations
import os
import sys
import json
from datetime import datetime

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DOCS = os.path.join(ROOT, "docs")
REPORT_DIR = os.path.join(DOCS, "roadmap_reports")
LOG_DIR = os.path.join(ROOT, "log")

DEFAULT_STATE = {
    "version": "snapshot-2025-08-24",
    "goals": [
        "Redmine上でAIエージェントとリアルタイム会話",
        "RFPチケットの自動処理（作成→応答→Redmineコメント投稿）",
        "運用化（.env, Docker Compose, secrets, cron, 監視, ドキュメント）",
        "永続対話セッション（WebSocketベース）とブラウザUIの完成",
    ],
    "completed": [
        "Webhook受信とRedmineコメント投稿の動作確認",
        "Flask+Socket.IOによる永続チャットサーバの実装（サーバ側）",
        "py_compileゲートの導入と破損PYファイルの整理",
    ],
    "in_progress": [
        "ブラウザ向けチャットUIの実装",
        "Watcher自動化と運用スケジュールの完成",
    ],
    "next_steps": [
        "ブラウザUIを実装してE2Eテストを行う",
        "CI/監視の追加と定期レポートの運用化",
    ],
}


def load_state(path: str) -> dict:
    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            return data
        except Exception as e:
            print(f"docs/roadmap_state.json の読み込みに失敗しました: {e}", file=sys.stderr)
    return DEFAULT_STATE


def ensure_dirs():
    os.makedirs(REPORT_DIR, exist_ok=True)
    os.makedirs(LOG_DIR, exist_ok=True)


def build_report(state: dict) -> str:
    now = datetime.utcnow()
    ts = now.strftime("%Y-%m-%d %H:%M:%S UTC")
    lines = []
    lines.append(f"# Crewai 開発ロードマップ報告 ({ts})")
    lines.append("")
    lines.append("## 概要")
    lines.append(f"- スナップショット: {state.get('version', 'unknown')}")
    lines.append("")
    lines.append("## 目的")
    for g in state.get("goals", []):
        lines.append(f"- {g}")
    lines.append("")
    lines.append("## 完了済み（抜粋）")
    for c in state.get("completed", []):
        lines.append(f"- {c}")
    lines.append("")
    lines.append("## 進行中")
    for p in state.get("in_progress", []):
        lines.append(f"- {p}")
    lines.append("")
    lines.append("## 次のアクション")
    for n in state.get("next_steps", []):
        lines.append(f"- {n}")
    lines.append("")
    lines.append("## 注意事項")
    lines.append("- このレポートは自動生成されています。必要に応じて `docs/roadmap_state.json` を編集してください。")
    return "\n".join(lines)


def write_report(content: str) -> str:
    ts = datetime.utcnow().strftime("%Y-%m-%d_%H%M%S")
    fname = f"{ts}.md"
    path = os.path.join(REPORT_DIR, fname)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    # append to log
    log_path = os.path.join(LOG_DIR, "roadmap_reports.log")
    with open(log_path, "a", encoding="utf-8") as lf:
        lf.write(f"{datetime.utcnow().isoformat()}\t{path}\n")
    return path


def main():
    ensure_dirs()
    state_file = os.path.join(DOCS, "roadmap_state.json")
    state = load_state(state_file)
    report = build_report(state)
    out = write_report(report)
    print(report)
    print("\n# Saved to:\n", out)


if __name__ == '__main__':
    main()
