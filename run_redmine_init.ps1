# run_redmine_init.ps1
# Copy create_redmine_users.rb into the running redmine container and run it via rails runner.
# Run from the repository root in PowerShell.

# load .env (simple parse)
$envFile = Join-Path $PSScriptRoot '.env'
if (Test-Path $envFile) {
  Get-Content $envFile | ForEach-Object {
    if ($_ -match '^[ \t]*([^#=\s]+)\s*=\s*(.*)') {
  $k = $matches[1]; $v = $matches[2];
  # strip surrounding quotes
  if ($v -match '^"(.*)"$') { $v = $matches[1] }
  # set environment variable
  Set-Item -Path env:$k -Value $v
    }
  }
}

# find redmine container id
 $cid = docker compose -f "$PSScriptRoot/docker-compose.yml" ps -q redmine
if (-not $cid) { Write-Error "redmine container not found or not running"; exit 1 }
Write-Host "Using redmine container: $cid"

# copy script
docker cp "$PSScriptRoot/scripts/create_redmine_users.rb" "$($cid):/usr/src/redmine/scripts/create_redmine_users.rb"

# run rails runner with env vars
$cmd = "cd /usr/src/redmine && NOBUNAGA_API_KEY=$Env:NOBUNAGA_API_KEY HIDE_API_KEY=$Env:HIDE_API_KEY IEYASU_API_KEY=$Env:IEYASU_API_KEY bundle exec rails runner scripts/create_redmine_users.rb"
Write-Host "Running: $cmd"
docker exec -it $cid bash -lc "$cmd"
