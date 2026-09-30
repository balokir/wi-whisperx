@echo off
setlocal EnableExtensions
call "%~dp0config.cmd"

echo.
echo ========================================
echo Ensuring WhisperX installation
echo ========================================
echo.

call "%SETUP_DIR%\00-validate-layout.cmd" || exit /b 1
call "%SETUP_DIR%\ensure-hf-token-example.cmd" || exit /b 1
call "%SETUP_DIR%\01-ensure-python.cmd" || exit /b 1
call "%SETUP_DIR%\02-ensure-ffmpeg.cmd" || exit /b 1
call "%SETUP_DIR%\03-ensure-venv.cmd" || exit /b 1
call "%SETUP_DIR%\04-ensure-runtime.cmd" || exit /b 1
call "%SETUP_DIR%\05-ensure-pytorch.cmd" || exit /b 1

call "%SETUP_DIR%\06-ensure-whisperx.cmd"
set "WX_RC=%ERRORLEVEL%"
if "%WX_RC%"=="10" (
    call "%SETUP_DIR%\05-ensure-pytorch.cmd" || exit /b 1
) else if not "%WX_RC%"=="0" (
    exit /b %WX_RC%
)

call "%SETUP_DIR%\04-ensure-runtime.cmd" || exit /b 1
call "%SETUP_DIR%\07-ensure-pyannote-patch.cmd" || exit /b 1

rem Exactly one expensive functional smoke pass in the healthy case.
rem Any failure means the Python environment is treated as corrupted and the
rem whole venv is rebuilt deterministically from local caches where possible.
call "%SETUP_DIR%\08-ensure-runtime-smoke.cmd" || exit /b 1

rem Checkpoint is a shallow, targeted asset repair after runtime health.
call "%SETUP_DIR%\09-ensure-checkpoint.cmd" || exit /b 1

echo.
echo ========================================
echo Installation is healthy
echo ========================================
exit /b 0
