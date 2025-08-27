# Simple pre-commit hook to prevent committing files larger than threshold
param(
    [int]$ThresholdMB = 5
)

$threshold = $ThresholdMB * 1MB
$staged = git diff --cached --name-only

foreach ($f in $staged) {
    if (Test-Path $f) {
        $size = (Get-Item $f).Length
        if ($size -ge $threshold) {
            Write-Host "ERROR: Staged file $f is $([math]::Round($size/1MB,2)) MB > $ThresholdMB MB threshold."
            exit 1
        }
    }
}

exit 0
