# Read large-files.csv (path, SizeMB, LastWriteTime) and produce git lfs commands
param(
    [string]$CsvPath = "large-files.csv",
    [switch]$DryRun = $true
)

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV file not found: $CsvPath"
    exit 1
}

$rows = Import-Csv -Path $CsvPath
if ($rows.Count -eq 0) {
    Write-Host "CSV is empty"
    exit 0
}

Write-Host "Preparing git lfs suggestions from $($rows.Count) files"

# Aggregate by extension
$extStats = @{}
foreach ($r in $rows) {
    $path = $r.Path
    $ext = [System.IO.Path]::GetExtension($path).ToLower()
    $size = 0
    try { $size = [double]$r.SizeMB } catch { $size = 0 }
    if (-not $ext) { $ext = '<noext>' }
    if (-not $extStats.ContainsKey($ext)) { $extStats[$ext] = @{count=0; size=0.0} }
    $extStats[$ext].count += 1
    $extStats[$ext].size += $size
}

# Convert to sortable list
$agg = $extStats.GetEnumerator() | ForEach-Object {
    [PSCustomObject]@{
        Ext = $_.Key
        Count = $_.Value.count
        TotalSizeMB = [math]::Round($_.Value.size,2)
    }
} | Sort-Object -Property TotalSizeMB -Descending

Write-Host "Top extensions by total size (MB) and count:"
$agg | Select-Object -First 30 | Format-Table -AutoSize

# Suggest patterns: prefer binary/native libs and common large assets
$suggested = @()
foreach ($row in $agg) {
    $e = $row.Ext
    if ($e -eq '<noext>') { continue }
    # common large binary/shared lib extensions
    if ($e -in '.so','.pyd','.dll','.dylib','.jar') { $suggested += "$e"; continue }
    # data/asset extensions
    if ($e -in '.zip','.tar','.tar.gz','.tgz','.mp4','.mov','.png','.jpg','.jpeg','.pdf','.parquet' ) { $suggested += "$e"; continue }
    # large python compiled libs
    if ($e -in '.abi3.so') { $suggested += "$e"; continue }
}

if ($suggested.Count -eq 0) {
    Write-Host "No clear extension-based suggestions found. You may want to inspect 'large-files.csv' manually."
} else {
    Write-Host "Suggested git-lfs track patterns (by extension):"
    $unique = $suggested | Select-Object -Unique
    foreach ($u in $unique) {
        # normalize pattern
        if ($u -like '.*') { Write-Host "  *$u" } else { Write-Host "  *$u" }
    }
}

if ($DryRun) {
    Write-Host "Dry run - no git or git lfs commands will be executed. To perform actions, re-run with -DryRun:$false"
    exit 0
}

# Execute tracking for unique suggestions
$unique = $unique = $suggested | Select-Object -Unique
foreach ($u in $unique) {
    $pattern = "*$u"
    Write-Host "git lfs track '$pattern'"
    git lfs track $pattern
}

Write-Host "Now you can run: git add .gitattributes; git commit -m 'track large files with LFS'"
Write-Host "To migrate history, consider: git lfs migrate import --include-ref=refs/heads/main --include='*<ext>' (run with care and backup)"
