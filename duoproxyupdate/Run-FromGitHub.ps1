# Download and Execute DuoProxyUpgrade.ps1 from GitHub
# Usage: powershell.exe -ExecutionPolicy Bypass -File Run-FromGitHub.ps1

# GitHub repository details (update these if needed)
$GitHubUser = "monobrau"
$GitHubRepo = "windows-network-config"
$GitHubBranch = "main"
$ScriptFile = "DuoProxyUpgrade.ps1"

# Construct raw GitHub URL
$GitHubUrl = "https://raw.githubusercontent.com/$GitHubUser/$GitHubRepo/$GitHubBranch/$ScriptFile"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Duo Proxy Upgrade Helper" -ForegroundColor Cyan
Write-Host "Downloading from GitHub..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Download script to temp location
    $TempScript = "$env:TEMP\DuoProxyUpgrade.ps1"
    Write-Host "Downloading: $GitHubUrl" -ForegroundColor Yellow
    Invoke-WebRequest -Uri $GitHubUrl -OutFile $TempScript -UseBasicParsing
    
    Write-Host "Download complete!" -ForegroundColor Green
    Write-Host "Executing script..." -ForegroundColor Yellow
    Write-Host ""
    
    # Execute the downloaded script
    & powershell.exe -ExecutionPolicy Bypass -File $TempScript
    
} catch {
    Write-Host "ERROR: Failed to download or execute script" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Tried URL: $GitHubUrl" -ForegroundColor Yellow
    exit 1
}
