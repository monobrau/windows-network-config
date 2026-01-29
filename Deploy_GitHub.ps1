# GitHub Deployment Script
# Downloads and runs the Windows Autorun Analyzer from GitHub

param(
    [string]$GitHubUrl = "https://raw.githubusercontent.com/yourusername/windows-autorun-analyzer/main/WindowsAutorunAnalyzer_Portable.ps1",
    [string]$OutputPath = "C:\dev\AutorunAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx"
)

Write-Host "GitHub Deployment Mode" -ForegroundColor Cyan
Write-Host "Downloading from: $GitHubUrl" -ForegroundColor Yellow

try {
    # Download the script
    $scriptContent = Invoke-WebRequest -Uri $GitHubUrl -UseBasicParsing
    $scriptPath = "C:\dev\WindowsAutorunAnalyzer_Portable.ps1"
    $scriptContent.Content | Out-File -FilePath $scriptPath -Encoding UTF8
    
    Write-Host "Script downloaded successfully" -ForegroundColor Green
    
    # Execute the script
    & $scriptPath -OutputPath $OutputPath
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure you have internet connectivity and the GitHub URL is correct" -ForegroundColor Yellow
}
