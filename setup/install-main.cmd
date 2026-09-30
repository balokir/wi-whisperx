@echo off
setlocal EnableExtensions
call "%~dp0config.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

echo.
echo ========================================
echo WhisperX local installer
echo ========================================
echo.

call "%SETUP_DIR%\ensure-all.cmd"
exit /b %ERRORLEVEL%
