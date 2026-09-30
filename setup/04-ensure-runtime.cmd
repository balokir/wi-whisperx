@echo off
setlocal EnableExtensions

call "%~dp0config.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

call "%SETUP_DIR%\runtime-layout.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

if not exist "%VENV%\Lib\site-packages" (
    echo ERROR: venv site-packages directory is missing:
    echo   "%VENV%\Lib\site-packages"
    exit /b 1
)

set "EXPECTED=%SETUP_DIR%\sitecustomize.py"
set "TARGET=%VENV%\Lib\site-packages\sitecustomize.py"

if not exist "%EXPECTED%" (
    echo ERROR: expected runtime sitecustomize.py is missing:
    echo   "%EXPECTED%"
    exit /b 1
)

if not exist "%TARGET%" goto :fix
fc /b "%EXPECTED%" "%TARGET%" >nul 2>&1
if errorlevel 1 goto :fix

for %%D in (%RUNTIME_REQUIRED_DIRS%) do (
    if not exist "%%~D\" goto :fix
)

echo [OK] runtime configuration
exit /b 0

:fix
echo [FIX] runtime configuration

copy /y "%EXPECTED%" "%TARGET%" >nul
if errorlevel 1 (
    echo ERROR: cannot install runtime sitecustomize.py:
    echo   "%TARGET%"
    exit /b 1
)

for %%D in (%RUNTIME_REQUIRED_DIRS%) do (
    call :ensure_dir "%%~D"
    if errorlevel 1 exit /b 1
)

echo [OK] runtime configuration
exit /b 0

:ensure_dir
if exist "%~1\" exit /b 0

mkdir "%~1" >nul 2>&1
if errorlevel 1 (
    echo ERROR: cannot create runtime directory:
    echo   "%~1"
    exit /b 1
)

if not exist "%~1\" (
    echo ERROR: runtime directory is still missing after mkdir:
    echo   "%~1"
    exit /b 1
)

exit /b 0
