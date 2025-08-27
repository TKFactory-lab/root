<#
tools/run_git_filter_repo.ps1
Safe wrapper to create a mirror, run git-filter-repo to remove paths, and print next steps.
Requires: git-filter-repo installed (https://github.com/newren/git-filter-repo)
This script does not push changes. It prepares a cleaned mirror and prints commands to inspect and push.
#>
Param(
  [string]$MirrorDir = "repo-mirror.git",
  [string]$PathsFile = "paths-to-remove.txt"
)

if (-not (Test-Path $PathsFile)) {
  Write-Error "Paths file '$PathsFile' not found. Create it with one path per line."
  exit 1
}

$pwd = Get-Location
$mirrorPath = Join-Path $pwd $MirrorDir
Write-Output "Creating bare mirror at: $mirrorPath"
if (Test-Path $mirrorPath) {
  Write-Output "Mirror dir already exists. Remove or choose a different name and re-run."
  exit 1
}

Write-Output "Running: git clone --mirror . $mirrorPath"
git clone --mirror . $mirrorPath
if ($LASTEXITCODE -ne 0) { Write-Error "git clone --mirror failed."; exit 1 }

Set-Location $mirrorPath
Write-Output "Running git-filter-repo to remove paths listed in $PathsFile"
# git-filter-repo expects paths relative to repo root
git filter-repo --invert-paths --paths-from-file "../$PathsFile"
if ($LASTEXITCODE -ne 0) { Write-Error "git-filter-repo failed."; exit 1 }

Write-Output "Done. Mirror rewritten at: $mirrorPath"
Write-Output "Next steps (manual):"
Write-Output "  1) Inspect the mirror: cd $mirrorPath; git log --oneline -n 5"
Write-Output "  2) If satisfied, push to remote (force) from the mirror: git push --force --all && git push --force --tags"
Write-Output "  3) Rotate credentials that were exposed and notify collaborators."

Write-Output "IMPORTANT: This script does not push or rotate secrets for you. Read SECURITY_CLEANUP.md before pushing changes."

Set-Location $pwd
