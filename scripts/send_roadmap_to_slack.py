#!/usr/bin/env python3
"""
send_roadmap_to_slack.py

最新のロードマップレポートを Slack に送る簡易スクリプト。
環境変数: SLACK_WEBHOOK_URL
オプション:
  --latest: 最新ファイルを送信（デフォルト）
  --file <path>: 指定ファイルを送信
  --dry-run: true/false (デフォルト true) デバッグ用

英語を使わないでください（メッセージは日本語固定）。
"""
from __future__ import annotations
import os
import sys
import argparse
import json
import glob
import urllib.request
import urllib.error

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
REPORT_DIR = os.path.join(ROOT, "docs", "roadmap_reports")


def find_latest_report() -> str | None:
    patterns = os.path.join(REPORT_DIR, "*.md")
    files = glob.glob(patterns)
    if not files:
        return None
    files.sort()
    return files[-1]


def load_text(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def send_to_slack(webhook_url: str, text: str) -> tuple[int, str]:
    payload = {"text": text}
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(webhook_url, data=data, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.getcode(), resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        return e.code, str(e)
    except Exception as e:
        return 0, str(e)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="ロードマップをSlackに送信します（日本語出力）")
    parser.add_argument("--file", help="送信するファイルを指定")
    parser.add_argument("--latest", action="store_true", help="最新ファイルを送信（デフォルト）")
    parser.add_argument("--provider", choices=["slack", "teams"], default="slack", help="送信先プロバイダ: slack または teams")
    parser.add_argument("--dry-run", choices=["true", "false"], default="true", help="dry-run を false にすると実際に送信します")
    args = parser.parse_args(argv)

    target = None
    if args.file:
        target = args.file
    elif args.latest or not args.file:
        target = find_latest_report()

    if not target:
        print("レポートが見つかりません。docs/roadmap_reports を確認してください。", file=sys.stderr)
        return 2

    text = load_text(target)
    # Slack にそのまま送るには長すぎる可能性があるため先頭数行だけ送る
    max_chars = 4000
    slack_text = f"ロードマップ報告: {os.path.basename(target)}\n\n" + (text[:max_chars] + ("\n...（省略）" if len(text) > max_chars else ""))

    dry = args.dry_run == "true"
    provider = args.provider
    webhook = None
    if provider == "slack":
        webhook = os.environ.get("SLACK_WEBHOOK_URL")
    else:
        webhook = os.environ.get("TEAMS_WEBHOOK_URL")
    if dry:
        print("--- dry-run: Slack 送信内容 ---")
        print(slack_text)
        print("--- end ---")
        print(f"ファイル: {target}")
        if webhook:
            print("SLACK_WEBHOOK_URL が設定されています（実送信可能）。")
        else:
            print("SLACK_WEBHOOK_URL は未設定です。実送信は行われません。")
        return 0

    if not webhook:
        print(f"{provider.upper()} の Webhook URL が環境変数に設定されていません。実送信できません。", file=sys.stderr)
        return 3

    if provider == "slack":
        code, body = send_to_slack(webhook, slack_text)
        print(f"送信結果 (Slack): HTTP {code} / {body}")
        return 0 if code in (200, 201) else 4
    else:
        # Microsoft Teams の Incoming Webhook 用の簡易 MessageCard フォーマット
        teams_payload = {
            "@type": "MessageCard",
            "@context": "http://schema.org/extensions",
            "text": slack_text,
        }
        data = json.dumps(teams_payload).encode("utf-8")
        req = urllib.request.Request(webhook, data=data, headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                body = resp.read().decode("utf-8")
                code = resp.getcode()
        except urllib.error.HTTPError as e:
            code = e.code
            body = str(e)
        except Exception as e:
            code = 0
            body = str(e)
        print(f"送信結果 (Teams): HTTP {code} / {body}")
        return 0 if code in (200, 201, 204) else 4


if __name__ == '__main__':
    raise SystemExit(main())
