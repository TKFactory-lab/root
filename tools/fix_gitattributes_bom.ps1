<#
Removes UTF-8 BOM or Unicode BOM from .gitattributes and writes UTF-8 without BOM.
Usage: .\tools\fix_gitattributes_bom.ps1
#>
$path = Join-Path $PSScriptRoot '..\.gitattributes'
if (-Not (Test-Path $path)) { Write-Host "No .gitattributes found at $path"; exit 1 }
$raw = Get-Content $path -Raw -Encoding Byte
if ($raw.Length -ge 3 -and $raw[0] -eq 0xEF -and $raw[1] -eq 0xBB -and $raw[2] -eq 0xBF) {
    Write-Host "Found UTF-8 BOM. Removing..."
    $content = [System.Text.Encoding]::UTF8.GetString($raw, 3, $raw.Length - 3)
} else {
    # try UTF-16 BOM
    if ($raw.Length -ge 2 -and (($raw[0] -eq 0xFF -and $raw[1] -eq 0xFE) -or ($raw[0] -eq 0xFE -and $raw[1] -eq 0xFF))) {
        Write-Host "Found UTF-16 BOM. Converting to UTF-8..."
        $content = [System.Text.Encoding]::Unicode.GetString($raw)
    } else {
        Write-Host "No BOM detected. Leaving file as-is (but rewriting as UTF-8)."
        $content = [System.Text.Encoding]::UTF8.GetString($raw)
    }
}
Set-Content -Path $path -Value $content -Encoding UTF8
Write-Host ".gitattributes normalized to UTF-8 (no BOM)."
