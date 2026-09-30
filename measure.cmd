@echo off
setlocal EnableExtensions

set "MEASURE_PS1=%~dp0scripts\measure.ps1"

if not exist "%MEASURE_PS1%" (
    echo ERROR: measure script is missing:
    echo   "%MEASURE_PS1%"
    exit /b 1
)

if "%~1"=="" (
    echo Usage:
    echo   measure.cmd ^<command^> [args...]
    echo.
    echo Example:
    echo   measure.cmd transcribe-diarize-speakers.bat "C:\path\meeting.m4a" 4
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%MEASURE_PS1%" %*
exit /b %ERRORLEVEL%
