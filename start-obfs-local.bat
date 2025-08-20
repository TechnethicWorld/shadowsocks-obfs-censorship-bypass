@echo off
setlocal enabledelayedexpansion

:: Set console code page to UTF-8
chcp 65001 >nul

:: Set console text color to default
color 07

:: Show intro warning
powershell -Command "Write-Host 'WARNING: This script must be run from the directory where obfs-local.exe is located.' -ForegroundColor Yellow"
powershell -Command "Write-Host 'You do NOT need to run it as Administrator.' -ForegroundColor Yellow"
echo.
pause

:: Define separate log files
set SCRIPT_LOG=%CD%\script_debug.log
set OBFSL_LOG=%CD%\obfs_local_output.log

:: Clear previous logs
echo. > "%SCRIPT_LOG%"
echo. > "%OBFSL_LOG%"

:: Get user input
echo Enter Shadowsocks server IP:
set /p SS_SERVER=

echo Enter server port (e.g. 8388):
set /p SS_PORT=

echo Enter local port to listen on (e.g. 1080):
set /p LOCAL_PORT=

:: Check if obfs-local.exe exists in the current directory
if not exist "obfs-local.exe" (
    echo ERROR: obfs-local.exe not found in this folder! >> "%SCRIPT_LOG%"
    echo [!] obfs-local.exe was not found. Please make sure it's in the same folder as this script.
    pause
    exit /b
)

:: Set maximum attempts to reconnect
set MAX_ATTEMPTS=5
set ATTEMPT=1

:: Main reconnect loop
:RETRY_LOOP
echo.
echo ===================================================
echo Attempt !ATTEMPT! to start obfs-local...
echo ===================================================

:: Kill any existing obfs-local.exe process
taskkill /f /im obfs-local.exe >nul 2>&1
timeout /t 2 >nul

:: Confirm it's terminated
tasklist /fi "imagename eq obfs-local.exe" | find /i "obfs-local.exe" >nul
if not errorlevel 1 (
    echo [!] obfs-local.exe is still running. Cannot continue.
    echo [!] obfs-local.exe is still running. >> "%SCRIPT_LOG%"
    pause
    exit /b
)

:: Log and start obfs-local
echo Running: obfs-local.exe -s %SS_SERVER% -p %SS_PORT% --obfs tls -l %LOCAL_PORT% -t 10 -no-proxy >> "%SCRIPT_LOG%"
start /b obfs-local.exe -s %SS_SERVER% -p %SS_PORT% --obfs tls -l %LOCAL_PORT% -t 10 -no-proxy >> "%OBFSL_LOG%" 2>&1
echo [OK] obfs-local started (background process).
echo [OK] obfs-local started (background process). >> "%SCRIPT_LOG%"

timeout /t 3 >nul

:: Connection check loop
:CHECK_CONNECTION
ping -n 1 %SS_SERVER% >nul
if !ERRORLEVEL! EQU 0 (
    echo [OK] Connection to %SS_SERVER%:%SS_PORT% is OK.
    echo [OK] Connection to %SS_SERVER%:%SS_PORT% is OK. >> "%SCRIPT_LOG%"
    timeout /t 10 >nul
    goto CHECK_CONNECTION
) else (
    echo [!] Connection to %SS_SERVER%:%SS_PORT% failed.
    echo [!] Connection to %SS_SERVER%:%SS_PORT% failed. >> "%SCRIPT_LOG%"
    set /a ATTEMPT+=1
    if !ATTEMPT! LEQ !MAX_ATTEMPTS! (
        echo [*] Restarting obfs-local after failed ping...
        echo [*] Restarting obfs-local after failed ping... >> "%SCRIPT_LOG%"
        timeout /t 5 >nul
        goto RETRY_LOOP
    ) else (
        echo [!] Maximum retries reached. Please check the logs:
        echo     - %SCRIPT_LOG%
        echo     - %OBFSL_LOG%
        echo [!] Maximum retries reached. >> "%SCRIPT_LOG%"
        pause
        exit /b
    )
)

pause
exit /b
