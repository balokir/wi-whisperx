@echo off
setlocal EnableExtensions

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

call "%SCRIPT_DIR%\env.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

set "PY=%VENV%\Scripts\python.exe"
if not exist "%PY%" (
    echo ERROR: WhisperX runtime is not installed:
    echo   "%PY%"
    echo Run install.cmd or repair.cmd first.
    exit /b 1
)

"%PY%" -m whisperx %* ^
  --model_dir "%MODELS%\whisper"

exit /b %ERRORLEVEL%
