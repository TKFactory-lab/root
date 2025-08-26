<#
Helper to run Git LFS migrate for the candidate patterns in large-files.csv.
This script performs a dry-run first and prints a migration plan. Use with caution.
Usage: .\tools\git_lfs_migrate_helper.ps1 [-Perform]
#>
param(
    [switch]$Perform
)
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
cd $repoRoot
Write-Host "Fetching origin..."
git fetch origin
Write-Host "Listing candidate patterns from large-files.csv (if present)..."
$candidates = @()
if (Test-Path .\large-files.csv) {
    $candidates = Get-Content .\large-files.csv | Where-Object { $_ -and -not ($_ -match "^#") } | ForEach-Object { $_.Trim() }
}
if ($candidates.Count -eq 0) {
    Write-Host "No candidate list found; using default patterns: modules/**/*.so, modules/**/bin/*, *.so, *.dll"
    $candidates = @('modules/**/*.so','modules/**/bin/*','*.so','*.dll')
}
$spec = $candidates -join ";"
Write-Host "Dry-run git lfs migrate import --everything --include="$spec""
# Dry run
git lfs migrate import --everything --include="$spec" --dry-run
if ($Perform) {
    Write-Host "Performing migration now (this will rewrite history). Make sure you have backups."
    git lfs migrate import --everything --include="$spec"
    Write-Host "After migration, push with --force-with-lease to origin and inform collaborators."
}
