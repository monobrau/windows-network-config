# PowerShell script to create GitHub repository and push Windows Autorun Analyzer
# This script will help you create the repository on GitHub

param(
    [string]$RepositoryName = "windows-autorun-analyzer",
    [string]$Description = "Universal Windows Autorun Analyzer - PowerShell script for analyzing autoruns, scheduled tasks, services, and registry entries"
)

function Write-Status {
    param($Message, $Color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

Write-Status "GitHub Repository Creation Helper" "Cyan"
Write-Status "=================================" "Cyan"
Write-Status ""
Write-Status "Repository Name: $RepositoryName" "Yellow"
Write-Status "Description: $Description" "Yellow"
Write-Status ""

Write-Status "To create the repository on GitHub, you have two options:" "Green"
Write-Status ""
Write-Status "OPTION 1: Using GitHub CLI (if installed)" "Cyan"
Write-Status "Run this command:" "Yellow"
Write-Status "gh repo create $RepositoryName --public --description `"$Description`"" "White"
Write-Status ""
Write-Status "OPTION 2: Manual creation on GitHub.com" "Cyan"
Write-Status "1. Go to https://github.com/new" "Yellow"
Write-Status "2. Repository name: $RepositoryName" "Yellow"
Write-Status "3. Description: $Description" "Yellow"
Write-Status "4. Make it PUBLIC" "Yellow"
Write-Status "5. Don't initialize with README (we have one)" "Yellow"
Write-Status "6. Click 'Create repository'" "Yellow"
Write-Status ""

Write-Status "After creating the repository, run these commands:" "Green"
Write-Status "git remote remove origin" "White"
Write-Status "git remote add origin https://github.com/monobrau/$RepositoryName.git" "White"
Write-Status "git push -u origin main" "White"
Write-Status ""

Write-Status "Or run this script again with -CreateRepo parameter" "Yellow"
Write-Status ""

# Check if GitHub CLI is available
try {
    $ghVersion = gh --version 2>$null
    if ($ghVersion) {
        Write-Status "GitHub CLI detected! You can create the repository automatically." "Green"
        Write-Status ""
        $create = Read-Host "Create repository automatically? (y/n)"
        if ($create -eq "y" -or $create -eq "Y") {
            Write-Status "Creating repository on GitHub..." "Yellow"
            gh repo create $RepositoryName --public --description $Description
            if ($LASTEXITCODE -eq 0) {
                Write-Status "Repository created successfully!" "Green"
                Write-Status "Now pushing your code..." "Yellow"
                git remote remove origin
                git remote add origin "https://github.com/monobrau/$RepositoryName.git"
                git push -u origin main
                if ($LASTEXITCODE -eq 0) {
                    Write-Status "Code pushed successfully!" "Green"
                    Write-Status "Repository URL: https://github.com/monobrau/$RepositoryName" "Cyan"
                } else {
                    Write-Status "Push failed. Please check your GitHub credentials." "Red"
                }
            } else {
                Write-Status "Repository creation failed." "Red"
            }
        }
    } else {
        Write-Status "GitHub CLI not found. Please use the manual method above." "Yellow"
    }
} catch {
    Write-Status "GitHub CLI not available. Please use the manual method above." "Yellow"
}
