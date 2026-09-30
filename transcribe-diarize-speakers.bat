@echo off
call "%~dp0scripts\transcribe-common.cmd" "%~1" diarize-speakers "%~2"
exit /b %ERRORLEVEL%
