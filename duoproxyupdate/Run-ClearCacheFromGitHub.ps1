# Download and Execute Clear-ServerCache.ps1 from GitHub
# Usage: powershell.exe -ExecutionPolicy Bypass -File Run-ClearCacheFromGitHub.ps1
# Compatible with PowerShell 5.1+

# Ensure TLS 1.2 is enabled for PowerShell 5.x compatibility with GitHub
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# GitHub repository details (update these if needed)
$GitHubUser = "monobrau"
$GitHubRepo = "windows-network-config"
$GitHubBranch = "main"
$SubDirectory = "duoproxyupdate"
$ScriptFile = "Clear-ServerCache.ps1"

# Construct raw GitHub URL
$GitHubUrl = "https://raw.githubusercontent.com/$GitHubUser/$GitHubRepo/$GitHubBranch/$SubDirectory/$ScriptFile"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Server Cache Cleaner" -ForegroundColor Cyan
Write-Host "Downloading from GitHub..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Download script to temp location
    $TempScript = "$env:TEMP\Clear-ServerCache.ps1"
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
