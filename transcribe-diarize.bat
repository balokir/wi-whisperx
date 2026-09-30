@echo off
call "%~dp0scripts\transcribe-common.cmd" "%~1" diarize
exit /b %ERRORLEVEL%
