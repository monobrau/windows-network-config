@echo off
echo ========================================
echo Windows Autorun Analyzer - GitHub Setup
echo ========================================
echo.

echo Your code is ready to push to GitHub!
echo.

echo STEP 1: Create Repository on GitHub
echo ===================================
echo 1. Go to: https://github.com/new
echo 2. Repository name: windows-autorun-analyzer
echo 3. Description: Universal Windows Autorun Analyzer - PowerShell script for analyzing autoruns, scheduled tasks, services, and registry entries
echo 4. Make it PUBLIC
echo 5. Don't initialize with README
echo 6. Click "Create repository"
echo.

pause

echo.
echo STEP 2: Push Your Code
echo =====================
echo.

echo Pushing your code to GitHub...
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS! Your Windows Autorun Analyzer is now on GitHub!
    echo.
    echo Repository URL: https://github.com/monobrau/windows-autorun-analyzer
    echo.
    echo You can now:
    echo - Share the repository with others
    echo - Test the GitHub download mode
    echo - Use the raw URL for direct downloads
    echo.
) else (
    echo.
    echo Push failed. Please make sure:
    echo 1. You created the repository on GitHub
    echo 2. You're logged into GitHub
    echo 3. You have push permissions
    echo.
)

pause
