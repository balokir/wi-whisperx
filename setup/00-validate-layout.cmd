@echo off
setlocal EnableExtensions
call "%~dp0config.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

if not exist "%SYSTEM_POWERSHELL%" (
    echo ERROR: Windows PowerShell executable not found:
    echo   "%SYSTEM_POWERSHELL%"
    exit /b 1
)

if not exist "%SETUP_DIR%\validate-layout.ps1" (
    echo ERROR: path validator is missing:
    echo   "%SETUP_DIR%\validate-layout.ps1"
    exit /b 1
)

"%SYSTEM_POWERSHELL%" -NoProfile -ExecutionPolicy Bypass ^
  -File "%SETUP_DIR%\validate-layout.ps1"

if errorlevel 1 (
    echo ERROR: repository path contract failed.
    exit /b 1
)

exit /b 0
