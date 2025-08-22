@echo off
setlocal enabledelayedexpansion

echo ============================================
echo Step 1: Check Python installation
echo ============================================
python --version
if errorlevel 1 (
    echo Python is not installed or not in PATH.
    pause
    exit /b 1
)

echo ============================================
echo Step 2: Create required folders
echo ============================================
if not exist "log" mkdir "log"
if not exist "projects" mkdir "projects"

echo ============================================
echo Step 3: Run project_manager.py
echo ============================================
python project_manager.py

if errorlevel 1 (
    echo An error occurred during script execution.
    pause
    exit /b 1
)

echo ============================================
echo Script execution complete.
echo Check the 'log' and 'projects' folders for output.
echo ============================================
pause