# ロードマップ報告 (自動生成)

このフォルダには自動生成されたロードマップ報告が保存されます。

使い方:

- ローカル: `python scripts/generate_roadmap_report.py` を実行すると、`docs/roadmap_reports/` に日付付きの Markdown ファイルが作られます。
- Windows スケジューラ: `scripts/schedule_roadmap_report.ps1` を管理者で実行してタスクを作成できます。
- GitHub Actions: `.github/workflows/roadmap_report.yml` が週次で実行され、生成物をアーティファクトとして保存します。

編集:

- `docs/roadmap_state.json` を編集すると、次回生成されるレポートに反映されます。

注意:

- レポートは日本語で出力されます。英語で表示しないようにしています。
