@echo off
setlocal
call "%~dp0config.cmd"
call "%SCRIPTS_DIR%\env.cmd"

set "PY=%VENV%\Scripts\python.exe"
set "CHECKPOINT=%VENV%\Lib\site-packages\whisperx\assets\pytorch_model.bin"
set "CHECKER=%SETUP_DIR%\check_checkpoint.py"
set "UPGRADER=%SETUP_DIR%\upgrade_checkpoint.py"

if not exist "%PY%" (
    echo ERROR: venv Python not found.
    exit /b 1
)

if not exist "%CHECKER%" (
    echo ERROR: checkpoint checker not found:
    echo   "%CHECKER%"
    exit /b 1
)

if not exist "%UPGRADER%" (
    echo ERROR: checkpoint upgrader not found:
    echo   "%UPGRADER%"
    exit /b 1
)

"%PY%" -c "import lightning" >nul 2>&1
if errorlevel 1 (
    echo ERROR: lightning import is required for checkpoint validation.
    exit /b 1
)

rem The checkpoint is a required WhisperX package asset.
if not exist "%CHECKPOINT%" (
    echo [FIX] WhisperX checkpoint asset

    rem Restore only the WhisperX package files. Dependencies are already
    rem owned by the previous ensure steps.
    "%PY%" -m pip install --force-reinstall --no-deps "whisperx==%WHISPERX_VERSION%"
    if errorlevel 1 exit /b 1

    if not exist "%CHECKPOINT%" (
        echo ERROR: WhisperX checkpoint asset is still missing after package repair:
        echo   "%CHECKPOINT%"
        exit /b 1
    )
)

"%PY%" "%CHECKER%" "%CHECKPOINT%" >nul 2>&1
if not errorlevel 1 (
    echo [OK] WhisperX checkpoint format
    exit /b 0
)

echo [FIX] WhisperX checkpoint format

"%PY%" "%UPGRADER%" "%CHECKPOINT%"
if errorlevel 1 (
    echo ERROR: WhisperX checkpoint migration failed.
    exit /b 1
)

"%PY%" "%CHECKER%" "%CHECKPOINT%" >nul 2>&1
if errorlevel 1 (
    echo ERROR: WhisperX checkpoint is still invalid after migration.
    exit /b 1
)

echo [OK] WhisperX checkpoint format
exit /b 0
