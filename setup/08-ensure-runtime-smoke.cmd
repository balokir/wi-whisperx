@echo off
setlocal EnableExtensions
call "%~dp0config.cmd"
call "%SCRIPTS_DIR%\env.cmd"

set "PY=%VENV%\Scripts\python.exe"
set "SMOKE=%SETUP_DIR%\functional_smoke.py"

if not exist "%PY%" (
    echo ERROR: venv Python not found.
    exit /b 1
)

if not exist "%SMOKE%" (
    echo ERROR: functional smoke helper not found:
    echo   "%SMOKE%"
    exit /b 1
)

"%PY%" "%SMOKE%" >nul 2>&1
if not errorlevel 1 (
    echo [OK] WhisperX functional runtime smoke
    exit /b 0
)

echo [BROKEN] WhisperX functional runtime smoke
echo [FIX] rebuild Python environment

call "%~dp0rebuild-venv.cmd"
exit /b %ERRORLEVEL%
