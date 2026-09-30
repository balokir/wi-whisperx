@echo off
setlocal EnableExtensions

call "%~dp0setup\config.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

set "LOGGER=%SCRIPTS_DIR%\run-with-log.ps1"
set "TARGET=%SETUP_DIR%\install-main.cmd"

if not exist "%LOGGER%" (
    echo ERROR: logging wrapper is missing:
    echo   "%LOGGER%"
    exit /b 1
)

if not exist "%TARGET%" (
    echo ERROR: target script is missing:
    echo   "%TARGET%"
    exit /b 1
)

"%SYSTEM_POWERSHELL%" -NoProfile -ExecutionPolicy Bypass ^
  -File "%LOGGER%" ^
  -Name "install" ^
  -Script "%TARGET%"

exit /b %ERRORLEVEL%
