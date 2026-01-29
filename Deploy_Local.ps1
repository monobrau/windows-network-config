# Local Deployment Script
# Runs the Windows Autorun Analyzer from local files

param(
    [string]$ScriptPath = ".\WindowsAutorunAnalyzer_Portable.ps1",
    [string]$OutputPath = "C:\dev\AutorunAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx"
)

Write-Host "Local Deployment Mode" -ForegroundColor Cyan
Write-Host "Using script: $ScriptPath" -ForegroundColor Yellow

if (Test-Path $ScriptPath) {
    try {
        # Execute the script
        & $ScriptPath -OutputPath $OutputPath
        Write-Host "Analysis completed successfully" -ForegroundColor Green
    } catch {
        Write-Host "Error executing script: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Script not found at: $ScriptPath" -ForegroundColor Red
    Write-Host "Please ensure the script file exists in the current directory" -ForegroundColor Yellow
}
