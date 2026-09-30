@echo off
setlocal EnableExtensions
call "%~dp0config.cmd"

echo.
echo ========================================
echo Rebuilding corrupted Python environment
echo ========================================
echo.

if not exist "%PYTHON_HOME%\python.exe" (
    echo ERROR: local Python is not available:
    echo   "%PYTHON_HOME%\python.exe"
    exit /b 1
)

if exist "%VENV%" (
    echo [FIX] remove corrupted venv
    rmdir /s /q "%VENV%"
    if exist "%VENV%" (
        echo ERROR: cannot remove:
        echo   "%VENV%"
        exit /b 1
    )
)

call "%SETUP_DIR%\03-ensure-venv.cmd" || exit /b 1
call "%SETUP_DIR%\04-ensure-runtime.cmd" || exit /b 1
call "%SETUP_DIR%\05-ensure-pytorch.cmd" || exit /b 1

call "%SETUP_DIR%\06-ensure-whisperx.cmd"
set "WX_RC=%ERRORLEVEL%"
if not "%WX_RC%"=="0" if not "%WX_RC%"=="10" exit /b %WX_RC%

rem WhisperX dependency resolution is not authoritative for CUDA torch.
call "%SETUP_DIR%\05-ensure-pytorch.cmd" || exit /b 1
call "%SETUP_DIR%\04-ensure-runtime.cmd" || exit /b 1
call "%SETUP_DIR%\07-ensure-pyannote-patch.cmd" || exit /b 1

call "%SCRIPTS_DIR%\env.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

"%VENV%\Scripts\python.exe" "%SETUP_DIR%\functional_smoke.py"
if errorlevel 1 (
    echo ERROR: rebuilt venv still fails the functional runtime smoke test.
    exit /b 1
)

echo.
echo [OK] rebuilt Python environment
exit /b 0
