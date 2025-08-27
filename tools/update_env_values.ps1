<#
tools/update_env_values.ps1
Interactive helper to update selected values in .env safely.
#>
Param()

$envFile = Join-Path (Get-Location) '.env'
if (-not (Test-Path $envFile)) { Write-Error ".env not found; copy .env.example to .env and fill base values first."; exit 1 }

function Backup-Env {
  $timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
  $dest = Join-Path (Get-Location) ".env.bak.$timestamp"
  Copy-Item -Path $envFile -Destination $dest -Force
  Write-Output "Backup created: $dest"
}

function Prompt-Secret([string]$prompt) {
  Write-Host "$prompt" -NoNewline
  $secure = Read-Host -AsSecureString
  return [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
}

$keys = @('OPENAI_API_KEY','NOBUNAGA_API_KEY','IEYASU_API_KEY','HIDE_API_KEY','SECRET_KEY_BASE','CREWAI_AGENT_TOKEN')
Write-Output "Creating backup of .env"
Backup-Env

$content = Get-Content -Raw -Path $envFile
foreach ($k in $keys) {
  $choice = Read-Host "Update $k? (y/N)"
  if ($choice -match '^[Yy]') {
    $val = Prompt-Secret "Enter new value for ${k}: "
    if ($content -match "^$k=") {
      $content = [regex]::Replace($content, "(?m)^$k=.*$", "$k=$val")
    } else {
      $content += "`n$k=$val"
    }
    Write-Output "$k updated in .env"
  }
}

Set-Content -Path $envFile -Value $content -Force
Write-Output ".env updated. Do NOT commit the .env file. Restart services to apply changes."
