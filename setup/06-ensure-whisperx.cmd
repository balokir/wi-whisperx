@echo off
setlocal EnableExtensions

call "%~dp0config.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

call "%SCRIPTS_DIR%\env.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

set "PY=%VENV%\Scripts\python.exe"

if not exist "%PY%" (
    echo ERROR: venv Python not found.
    exit /b 1
)

set "NEEDS_FIX=0"

rem Verify the exact tested compatibility-critical package set.
"%PY%" -c "import importlib.metadata as m, sys; reqs=sys.argv[1:]; ok=True; exec('for r in reqs:\n n,v=r.split(\"==\",1)\n try:\n  actual=m.version(n)\n except m.PackageNotFoundError:\n  ok=False\n  continue\n if actual != v:\n  ok=False'); raise SystemExit(0 if ok else 1)" %WHISPERX_COMPAT_REQUIREMENTS% >nul 2>&1
if errorlevel 1 set "NEEDS_FIX=1"

"%PY%" -m pip check >nul 2>&1
if errorlevel 1 set "NEEDS_FIX=1"

if "%NEEDS_FIX%"=="0" (
    echo [OK] WhisperX %WHISPERX_VERSION% compatibility stack
    echo [OK] Python dependency closure
    exit /b 0
)

echo [FIX] WhisperX compatibility stack
for %%R in (%WHISPERX_COMPAT_REQUIREMENTS%) do echo       %%R

rem Install the exact tested compatibility set in one resolver transaction.
rem The orchestrator reasserts the separate CUDA PyTorch contract afterwards.
"%PY%" -m pip install %WHISPERX_COMPAT_REQUIREMENTS%
if errorlevel 1 exit /b 1

rem Verify exact metadata again after resolution.
"%PY%" -c "import importlib.metadata as m, sys; reqs=sys.argv[1:]; ok=True; exec('for r in reqs:\n n,v=r.split(\"==\",1)\n try:\n  actual=m.version(n)\n except m.PackageNotFoundError:\n  ok=False\n  continue\n if actual != v:\n  print(f\"ERROR: {n}=={actual}, expected {v}\")\n  ok=False'); raise SystemExit(0 if ok else 1)" %WHISPERX_COMPAT_REQUIREMENTS%
if errorlevel 1 (
    echo ERROR: WhisperX compatibility stack does not match configured versions.
    exit /b 1
)

"%PY%" -m pip check
if errorlevel 1 (
    echo ERROR: Python dependency closure is still broken.
    exit /b 1
)

echo [OK] WhisperX %WHISPERX_VERSION% compatibility stack
echo [OK] Python dependency closure

rem Signal mutation so the orchestrator reasserts the CUDA PyTorch contract.
exit /b 10
