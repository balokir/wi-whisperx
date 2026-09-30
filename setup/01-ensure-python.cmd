@echo off
setlocal EnableExtensions
call "%~dp0config.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

rem Existing local Python is healthy only if version, pip and venv all work.
if not exist "%PYTHON_HOME%\python.exe" goto :fix_python

"%PYTHON_HOME%\python.exe" -c "import platform; raise SystemExit(0 if platform.python_version() == '%PYTHON_VERSION%' else 1)" >nul 2>&1
if errorlevel 1 goto :fix_python

"%PYTHON_HOME%\python.exe" -m pip --version >nul 2>&1
if errorlevel 1 goto :fix_python

"%PYTHON_HOME%\python.exe" -c "import venv" >nul 2>&1
if errorlevel 1 goto :fix_python

echo [OK] Python %PYTHON_VERSION%
exit /b 0

:fix_python
echo [FIX] Python %PYTHON_VERSION% portable NuGet package
echo       ROOT=%ROOT%
echo       LOCAL=%LOCAL%
echo       DOWNLOADS=%DOWNLOADS%
echo       RUNTIME=%RUNTIME%
echo       PYTHON_HOME=%PYTHON_HOME%
echo       PACKAGE=%PYTHON_PACKAGE_PATH%
echo       POWERSHELL=%SYSTEM_POWERSHELL%

if not exist "%SYSTEM_POWERSHELL%" (
    echo ERROR: Windows PowerShell executable not found:
    echo   "%SYSTEM_POWERSHELL%"
    exit /b 1
)

echo [STEP] Preparing Python directories...

if not exist "%LOCAL%" mkdir "%LOCAL%"
if errorlevel 1 (
    echo ERROR: cannot create local state directory:
    echo   "%LOCAL%"
    exit /b 1
)

if not exist "%DOWNLOADS%" mkdir "%DOWNLOADS%"
if errorlevel 1 (
    echo ERROR: cannot create downloads directory:
    echo   "%DOWNLOADS%"
    exit /b 1
)

if not exist "%RUNTIME%" mkdir "%RUNTIME%"
if errorlevel 1 (
    echo ERROR: cannot create runtime directory:
    echo   "%RUNTIME%"
    exit /b 1
)

echo [STEP] Ensuring Python NuGet package...
"%SYSTEM_POWERSHELL%" -NoProfile -ExecutionPolicy Bypass ^
  -File "%SETUP_DIR%\download-file.ps1" ^
  -Url "%PYTHON_URL%" ^
  -OutFile "%PYTHON_PACKAGE_PATH%" ^
  -HashAlgorithm "%PYTHON_HASH_ALGORITHM%" ^
  -HashEncoding "%PYTHON_HASH_ENCODING%" ^
  -ExpectedHash "%PYTHON_HASH%"
if errorlevel 1 (
    echo ERROR: Python NuGet package validation/download failed.
    exit /b 1
)

for %%F in ("%PYTHON_PACKAGE_PATH%") do echo [OK] Python package ready: %%~zF bytes

echo [STEP] Extracting Python NuGet package...

if exist "%PYTHON_EXTRACT%" rmdir /s /q "%PYTHON_EXTRACT%"
if exist "%PYTHON_EXTRACT%" (
    echo ERROR: cannot remove temporary extraction directory:
    echo   "%PYTHON_EXTRACT%"
    exit /b 1
)

"%SYSTEM_POWERSHELL%" -NoProfile -ExecutionPolicy Bypass ^
  -Command "$ErrorActionPreference='Stop'; Expand-Archive -LiteralPath '%PYTHON_PACKAGE_PATH%' -DestinationPath '%PYTHON_EXTRACT%' -Force"
if errorlevel 1 (
    echo ERROR: Python NuGet package extraction failed.
    exit /b 1
)

if not exist "%PYTHON_EXTRACT%\tools\python.exe" (
    echo ERROR: extracted NuGet package does not contain:
    echo   "%PYTHON_EXTRACT%\tools\python.exe"
    exit /b 1
)

echo [STEP] Verifying extracted Python package...

"%PYTHON_EXTRACT%\tools\python.exe" -c "import platform, sys; print(sys.version); raise SystemExit(0 if platform.python_version() == '%PYTHON_VERSION%' else 1)"
if errorlevel 1 (
    echo ERROR: extracted Python version check failed.
    exit /b 1
)

"%PYTHON_EXTRACT%\tools\python.exe" -m pip --version
if errorlevel 1 (
    echo ERROR: pip is not available in the extracted Python package.
    exit /b 1
)

"%PYTHON_EXTRACT%\tools\python.exe" -c "import venv"
if errorlevel 1 (
    echo ERROR: venv module is not available in the extracted Python package.
    exit /b 1
)

echo [STEP] Installing portable Python into:
echo        "%PYTHON_HOME%"

if exist "%PYTHON_HOME%" rmdir /s /q "%PYTHON_HOME%"
if exist "%PYTHON_HOME%" (
    echo ERROR: cannot remove existing Python directory:
    echo   "%PYTHON_HOME%"
    exit /b 1
)

mkdir "%PYTHON_HOME%"
if errorlevel 1 (
    echo ERROR: cannot create Python directory:
    echo   "%PYTHON_HOME%"
    exit /b 1
)

xcopy "%PYTHON_EXTRACT%\tools\*" "%PYTHON_HOME%\" /E /I /Y >nul
if errorlevel 1 (
    echo ERROR: cannot copy portable Python into:
    echo   "%PYTHON_HOME%"
    exit /b 1
)

rmdir /s /q "%PYTHON_EXTRACT%" >nul 2>&1

echo [STEP] Verifying installed Python...

"%PYTHON_HOME%\python.exe" -c "import platform, sys; print(sys.version); raise SystemExit(0 if platform.python_version() == '%PYTHON_VERSION%' else 1)"
if errorlevel 1 (
    echo ERROR: installed Python version check failed.
    exit /b 1
)

"%PYTHON_HOME%\python.exe" -m pip --version
if errorlevel 1 (
    echo ERROR: installed Python pip check failed.
    exit /b 1
)

"%PYTHON_HOME%\python.exe" -c "import venv"
if errorlevel 1 (
    echo ERROR: installed Python venv check failed.
    exit /b 1
)

echo [OK] Python %PYTHON_VERSION% portable
exit /b 0
