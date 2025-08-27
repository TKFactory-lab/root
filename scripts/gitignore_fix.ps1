# Safe script to add .gitignore entries and untrack local env dirs
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$branch = 'fix/ignore-local-envs'
Write-Output "Working directory: $(Get-Location)"

# create or checkout branch
if (git show-ref --verify --quiet "refs/heads/$branch") {
    Write-Output "Switching to existing branch $branch"
    git checkout $branch
} else {
    Write-Output "Creating and switching to branch $branch"
    git checkout -b $branch
}

# ensure .gitignore exists
if (-not (Test-Path '.gitignore')) {
    Write-Output 'Creating .gitignore'
    New-Item -Path .gitignore -ItemType File | Out-Null
}

$entries = @(
    'final_crewai_env*/',
    'final_crewai_env_corrupt*/',
    'final_crewai_env/',
    'final_crewai_env_corrupt_*/',
    'venv/',
    'env/',
    '__pycache__/',
    '*.pyc'
)

foreach ($e in $entries) {
    # escape for Select-String
    $escaped = [regex]::Escape($e)
    if (-not (Select-String -Path .gitignore -Pattern $escaped -Quiet -ErrorAction SilentlyContinue)) {
        Write-Output "Adding entry to .gitignore: $e"
        Add-Content -Path .gitignore -Value $e
    } else {
        Write-Output "Already present in .gitignore: $e"
    }
}

# stage .gitignore
git add .gitignore

# commit .gitignore if changes
try {
    git commit -m 'ci: ignore local Python envs (final_crewai_env* etc.)'
    Write-Output 'Committed .gitignore updates.'
} catch {
    Write-Output 'No changes to commit for .gitignore.'
}

# find tracked files matching pattern
$trackedRaw = git ls-files -- 'final_crewai_env*' 2>$null
if (-not [string]::IsNullOrWhiteSpace($trackedRaw)) {
    $tracked = $trackedRaw -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    Write-Output "Tracked files matching pattern (count: $($tracked.Count))"
    foreach ($f in $tracked) { Write-Output " - $f" }

    # untrack them from index (do not delete working tree files)
    foreach ($f in $tracked) {
        Write-Output "Untracking: $f"
        git rm --cached -r -- "$f" 2>&1 | Write-Output
    }

    # commit removal if any
    $staged = git diff --cached --name-only
    if (-not [string]::IsNullOrWhiteSpace($staged)) {
        Write-Output 'Committing removal of tracked env files'
        git commit -m 'chore: remove tracked local envs from index'
    } else {
        Write-Output 'No staged changes to commit after untracking.'
    }
} else {
    Write-Output 'No tracked final_crewai_env* files found in index.'
}

# push branch
Write-Output "Pushing branch $branch to origin"
git push -u origin $branch
Write-Output 'Done.'
