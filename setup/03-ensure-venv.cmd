@echo off
setlocal
call "%~dp0config.cmd"

if exist "%VENV%\Scripts\python.exe" (
    "%VENV%\Scripts\python.exe" -c "import os, sys; expected=os.path.normcase(os.path.abspath(sys.argv[1])); actual=os.path.normcase(os.path.abspath(sys._base_executable)); raise SystemExit(0 if actual == expected else 1)" "%PYTHON_HOME%\python.exe" >nul 2>&1
    if not errorlevel 1 (
        echo [OK] venv
        exit /b 0
    )
)

echo [FIX] venv

if not exist "%PYTHON_HOME%\python.exe" exit /b 1

if exist "%VENV%" (
    rmdir /s /q "%VENV%"
    if exist "%VENV%" exit /b 1
)

"%PYTHON_HOME%\python.exe" -m venv "%VENV%"
if errorlevel 1 exit /b 1

echo [OK] venv
exit /b 0
