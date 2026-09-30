@echo off
call "%~dp0scripts\transcribe-common.cmd" "%~1" plain
exit /b %ERRORLEVEL%
