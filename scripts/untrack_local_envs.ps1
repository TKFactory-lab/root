<#
Safe helper to untrack local virtualenv directories from git index without deleting files.
Usage:
  .\scripts\untrack_local_envs.ps1 -Paths @('final_crewai_env') -DryRun
#>
param(
    [string[]]$Paths = @('final_crewai_env'),
    [switch]$DryRun = $true
)

foreach ($p in $Paths) {
    if (Test-Path $p) {
        Write-Host "Found path: $p"
        if ($DryRun) {
            Write-Host "DryRun: git rm -r --cached --ignore-unmatch $p"
        } else {
            git rm -r --cached --ignore-unmatch $p
            Write-Host "Removed $p from index. Commit the change: git commit -m 'Remove local env from repo index'"
        }
    } else {
        Write-Host "Path not found: $p"
    }
}
