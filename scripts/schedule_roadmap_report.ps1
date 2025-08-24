# schedule_roadmap_report.ps1
# Windows向け: schtasks を使って毎日定時にロードマップレポートを生成するタスクを作成します。
# 実行例: 管理者として PowerShell を開き、このスクリプトを実行してください。

$scriptPath = Join-Path $PSScriptRoot "generate_roadmap_report.py"
if (-not (Test-Path $scriptPath)) {
  Write-Error "スクリプトが見つかりません: $scriptPath"
  exit 1
}

# 実行コマンド（Python が PATH にある前提）。必要ならフルパスに変更してください。
# PowerShell ではダブルクォートをエスケープするためにバッククォート (`) を使用します。
$action = "python `"$scriptPath`""
$taskName = "Crewai_Roadmap_Report"
$time = "09:00"

Write-Output "タスクを作成: $taskName -> $action @ $time"
Start-Process -FilePath schtasks -ArgumentList "/Create","/SC","DAILY","/TN",$taskName,"/TR",$action,"/ST",$time,"/F" -NoNewWindow -Wait
Write-Output "作成完了。または既存タスクが上書きされました。手動実行例: python `"$scriptPath`""
