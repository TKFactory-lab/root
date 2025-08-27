$names = @('GITHUB_TOKEN','GH_TOKEN','GITHUB_API_TOKEN','PERSONAL_TOKEN')
foreach ($n in $names) {
    $val = [Environment]::GetEnvironmentVariable($n)
    if ([string]::IsNullOrEmpty($val)) { Write-Output "$n not found" } else { Write-Output "$n found" }
}
