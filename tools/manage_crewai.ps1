<#
tools/manage_crewai.ps1
A small helper for non-technical operators to perform common tasks.
#>
Param(
  [Parameter(Mandatory=$true)][ValidateSet('start','stop','status','check-env','backup')]
  [string]$Action
)

function Check-Env {
  $envFile = Join-Path (Get-Location) '.env'
  if (-not (Test-Path $envFile)) { Write-Output ".env not found. Copy .env.example to .env and fill values."; exit 1 }
  $content = Get-Content $envFile -Raw
  if ($content -match 'REPLACE_ME') { Write-Output ".env contains placeholder values (REPLACE_ME). Please fill required secrets."; exit 1 }
  Write-Output ".env exists and looks filled."
}

function Backup-Repo {
  $timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
  $dest = Join-Path (Get-Location) "backup-$timestamp.zip"
  Write-Output "Creating zip backup: $dest"
  Compress-Archive -Path * -DestinationPath $dest -Force
  Write-Output "Backup created: $dest"
}

function Start-Services {
  Write-Output "Starting services with Docker Compose (background)..."
  docker compose up -d
  Write-Output "Done. Use 'docker compose ps' to check containers."
}

function Stop-Services {
  Write-Output "Stopping services..."
  docker compose down
  Write-Output "Stopped."
}

function Status {
  Write-Output "Docker compose status:"; docker compose ps
}

switch ($Action) {
  'start' { Check-Env; Start-Services }
  'stop' { Stop-Services }
  'status' { Status }
  'check-env' { Check-Env }
  'backup' { Backup-Repo }
}
