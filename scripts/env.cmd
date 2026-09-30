@echo off

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"
for %%I in ("%SCRIPT_DIR%\..") do set "ROOT=%%~fI"

if not exist "%ROOT%\setup\config.cmd" (
    echo ERROR: path configuration is missing:
    echo   "%ROOT%\setup\config.cmd"
    exit /b 1
)

call "%ROOT%\setup\config.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

set "WHISPERX_FFMPEG_BIN=%FFMPEG_HOME%\bin"
set "PATH=%WHISPERX_FFMPEG_BIN%;%PATH%"

set "HF_HOME=%CACHE%\huggingface"
set "HF_HUB_CACHE=%CACHE%\huggingface\hub"
set "HF_XET_CACHE=%CACHE%\huggingface\xet"
set "HF_HUB_DISABLE_SYMLINKS_WARNING=1"

set "TORCH_HOME=%CACHE%\torch"
set "PIP_CACHE_DIR=%CACHE%\pip"
set "PIP_DISABLE_PIP_VERSION_CHECK=1"

set "NLTK_DATA=%CACHE%\nltk"
set "XDG_CACHE_HOME=%CACHE%"

set "TMP=%CACHE%\tmp"
set "TEMP=%CACHE%\tmp"

set "WHISPERX_DISABLE_TF32=1"
set "PYANNOTE_METRICS_ENABLED=0"
