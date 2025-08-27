# List files larger than threshold to help pick Git LFS candidates
# Usage: Run from repo root in PowerShell
# .\scripts\list_git_lfs_candidates.ps1 -ThresholdMB 5 -OutFile large-files.csv
param(
    [int]$ThresholdMB = 5,
    [string]$OutFile = "large-files.csv"
)

$threshold = $ThresholdMB * 1MB
Write-Host "Scanning repository for files larger than $ThresholdMB MB..."

$files = Get-ChildItem -Path . -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "\\.git\\" -and $_.Length -ge $threshold } |
    Select-Object @{Name='Path';Expression={$_.FullName}}, @{Name='SizeMB';Expression={[math]::Round($_.Length/1MB,2)}}, LastWriteTime

if ($files.Count -eq 0) {
    Write-Host "No files >= $ThresholdMB MB found."
    exit 0
}

$files | Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $($files.Count) entries to $OutFile"
Write-Host "Suggested next step: review the list and run 'git lfs track' and 'git lfs migrate' as needed."
