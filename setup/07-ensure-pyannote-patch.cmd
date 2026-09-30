@echo off
setlocal
call "%~dp0config.cmd"

set "PY=%VENV%\Scripts\python.exe"
set "PATCHER=%SETUP_DIR%\patch_pyannote_pooling.py"
set "TARGET=%VENV%\Lib\site-packages\pyannote\audio\models\blocks\pooling.py"

if not exist "%PY%" (
    echo ERROR: venv Python not found.
    exit /b 1
)

if not exist "%PATCHER%" (
    echo ERROR: pyannote patch helper not found:
    echo   "%PATCHER%"
    exit /b 1
)

"%PY%" "%PATCHER%" --apply "%TARGET%"
exit /b %ERRORLEVEL%
