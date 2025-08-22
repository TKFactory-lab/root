<#
tools/clean_git_secrets.ps1
PowerShell helper to scan for likely secrets in the repo and produce recommendations.
This script does NOT rewrite history by default. It prepares a report and a suggested git-filter-repo command.
#>
Param(
  [switch]$ProduceFilterRepoCmd
)

Write-Output "Scanning repository for likely secrets (OPENAI_API_KEY, CREWAI_AGENT_TOKEN, SECRET_KEY_BASE, sk- prefixes)..."
$patterns = @('OPENAI_API_KEY','CREWAI_AGENT_TOKEN','SECRET_KEY_BASE','sk-')
$matches = @()

Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
  $path = $_.FullName
  try {
    $content = Get-Content -Raw -ErrorAction Stop -Path $path
    foreach ($p in $patterns) {
      if ($content -match [regex]::Escape($p)) {
        $matches += [pscustomobject]@{File=$path; Pattern=$p}
      }
    }
  } catch {
    # binary or unreadable
  }
}

if ($matches.Count -eq 0) {
  Write-Output "No likely plaintext patterns found."
} else {
  Write-Output "Potential matches:"
  $matches | Select-Object -Unique | Format-Table -AutoSize
  if ($ProduceFilterRepoCmd) {
    Write-Output "\nSuggested git-filter-repo command (run from repo root):"
    Write-Output "git filter-repo --invert-paths --paths-from-file paths-to-remove.txt"
    Write-Output "(Create paths-to-remove.txt containing the filenames you want to scrub, one per line.)"
  } else {
    Write-Output "Run with -ProduceFilterRepoCmd to get recommended git-filter-repo invocation guidance."
  }
}

Write-Output "\nNOTE: Rewriting git history is destructive to shared repos. Read SECURITY_CLEANUP.md before proceeding."
