# PowerShell script to help push Windows Network Configuration Scripts to GitHub
# Run this script to automate the GitHub deployment process
# Version: 1.0.0

param(
    [string]$GitHubUsername = "",
    [string]$RepositoryName = "windows-network-config",
    [string]$CommitMessage = "Update: Windows Network Configuration Scripts"
)

function Write-Status {
    param($Message, $Color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

function Test-GitInstalled {
    try {
        $gitVersion = git --version
        return $true
    } catch {
        return $false
    }
}

function Initialize-GitRepository {
    Write-Status "Initializing Git repository..." "Yellow"
    
    # Initialize git if not already initialized
    if (-not (Test-Path ".git")) {
        git init
        Write-Status "Git repository initialized" "Green"
    } else {
        Write-Status "Git repository already initialized" "Green"
    }
}

function Add-GitFiles {
    Write-Status "Adding files to Git..." "Yellow"
    
    # Add all files
    git add .
    
    # Check status
    $status = git status --porcelain
    if ($status) {
        Write-Status "Files added to staging area:" "Green"
        $status | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }
    } else {
        Write-Status "No changes to commit" "Yellow"
    }
}

function Commit-Changes {
    param($Message)
    
    Write-Status "Committing changes..." "Yellow"
    git commit -m $Message
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Changes committed successfully" "Green"
    } else {
        Write-Status "Commit failed or no changes to commit" "Yellow"
    }
}

function Set-RemoteOrigin {
    param($Username, $RepoName)
    
    $remoteUrl = "https://github.com/$Username/$RepoName.git"
    
    Write-Status "Setting remote origin to: $remoteUrl" "Yellow"
    
    # Check if remote already exists
    $existingRemote = git remote get-url origin 2>$null
    if ($existingRemote) {
        Write-Status "Remote origin already exists: $existingRemote" "Yellow"
        $update = Read-Host "Update to new URL? (y/n)"
        if ($update -eq "y" -or $update -eq "Y") {
            git remote set-url origin $remoteUrl
            Write-Status "Remote origin updated" "Green"
        }
    } else {
        git remote add origin $remoteUrl
        Write-Status "Remote origin added" "Green"
    }
}

function Push-to-GitHub {
    Write-Status "Pushing to GitHub..." "Yellow"
    
    # Push to main branch
    git push -u origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Successfully pushed to GitHub!" "Green"
        Write-Status "Repository URL: https://github.com/$GitHubUsername/$RepositoryName" "Cyan"
    } else {
        Write-Status "Push failed. You may need to:" "Red"
        Write-Status "1. Create the repository on GitHub first" "Yellow"
        Write-Status "2. Check your GitHub credentials" "Yellow"
        Write-Status "3. Ensure you have push permissions" "Yellow"
    }
}

function Update-ReadmeGitHubUrl {
    param($Username, $RepoName)

    $readmeFile = "README.md"

    if (Test-Path $readmeFile) {
        Write-Status "Updating GitHub URLs in README..." "Yellow"

        $content = Get-Content $readmeFile -Raw
        $updatedContent = $content -replace 'https://raw\.githubusercontent\.com/monobrau/windows-network-config/', "https://raw.githubusercontent.com/$Username/$RepoName/"

        if ($content -ne $updatedContent) {
            $updatedContent | Set-Content $readmeFile -NoNewline
            Write-Status "GitHub URLs updated in README" "Green"
        } else {
            Write-Status "GitHub URLs already correct" "Green"
        }
    }
}

# Main execution
Write-Status "Windows Network Configuration - GitHub Deployment Helper" "Cyan"
Write-Status "=========================================================" "Cyan"

# Check if Git is installed
if (-not (Test-GitInstalled)) {
    Write-Status "Git is not installed or not in PATH" "Red"
    Write-Status "Please install Git from https://git-scm.com/" "Yellow"
    exit 1
}

# Get GitHub username if not provided
if (-not $GitHubUsername) {
    $GitHubUsername = Read-Host "Enter your GitHub username"
}

if (-not $GitHubUsername) {
    Write-Status "GitHub username is required" "Red"
    exit 1
}

Write-Status "GitHub Username: $GitHubUsername" "Cyan"
Write-Status "Repository Name: $RepositoryName" "Cyan"
Write-Status "Commit Message: $CommitMessage" "Cyan"
Write-Status ""

# Confirm before proceeding
$confirm = Read-Host "Proceed with GitHub deployment? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Status "Deployment cancelled" "Yellow"
    exit 0
}

try {
    # Step 1: Initialize Git repository
    Initialize-GitRepository

    # Step 2: Update README with correct GitHub URLs
    Update-ReadmeGitHubUrl -Username $GitHubUsername -RepoName $RepositoryName

    # Step 3: Add files to Git
    Add-GitFiles

    # Step 4: Commit changes
    Commit-Changes -Message $CommitMessage

    # Step 5: Set remote origin
    Set-RemoteOrigin -Username $GitHubUsername -RepoName $RepositoryName

    # Step 6: Push to GitHub
    Push-to-GitHub

    Write-Status ""
    Write-Status "🎉 GitHub deployment completed!" "Green"
    Write-Status ""
    Write-Status "Next steps:" "Cyan"
    Write-Status "1. Go to https://github.com/$GitHubUsername/$RepositoryName" "Yellow"
    Write-Status "2. Verify all files are uploaded" "Yellow"
    Write-Status "3. Test the scripts:" "Yellow"
    Write-Status "   .\NetworkConfig.ps1 -Action status" "Cyan"
    Write-Status "4. Share your repository!" "Yellow"
    
} catch {
    Write-Status "Error during deployment: $($_.Exception.Message)" "Red"
    Write-Status "Please check the error and try again" "Yellow"
}
