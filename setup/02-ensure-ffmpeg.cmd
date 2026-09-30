@echo off
setlocal EnableExtensions
call "%~dp0config.cmd"

if exist "%FFMPEG_HOME%\bin\ffmpeg.exe" if exist "%FFMPEG_HOME%\bin\avcodec-61.dll" (
    "%FFMPEG_HOME%\bin\ffmpeg.exe" -version 2>nul | findstr /C:"ffmpeg version %FFMPEG_VERSION%-" >nul
    if not errorlevel 1 (
        echo [OK] FFmpeg %FFMPEG_VERSION% full shared
        exit /b 0
    )
)

echo [FIX] FFmpeg %FFMPEG_VERSION% full shared
echo       DOWNLOADS=%DOWNLOADS%
echo       FFMPEG_HOME=%FFMPEG_HOME%

if not exist "%SYSTEM_POWERSHELL%" (
    echo ERROR: Windows PowerShell executable not found:
    echo   "%SYSTEM_POWERSHELL%"
    exit /b 1
)

if not exist "%LOCAL%" mkdir "%LOCAL%"
if errorlevel 1 exit /b 1

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

echo [STEP] Ensuring 7-Zip extractor...
"%SYSTEM_POWERSHELL%" -NoProfile -ExecutionPolicy Bypass ^
  -File "%SETUP_DIR%\download-file.ps1" ^
  -Url "%SEVENZIP_URL%" ^
  -OutFile "%SEVENZIP_EXE%" ^
  -HashAlgorithm "%SEVENZIP_HASH_ALGORITHM%" ^
  -HashEncoding "%SEVENZIP_HASH_ENCODING%" ^
  -ExpectedHash "%SEVENZIP_HASH%"
if errorlevel 1 exit /b 1

echo [STEP] Ensuring FFmpeg archive...
"%SYSTEM_POWERSHELL%" -NoProfile -ExecutionPolicy Bypass ^
  -File "%SETUP_DIR%\download-file.ps1" ^
  -Url "%FFMPEG_URL%" ^
  -OutFile "%FFMPEG_ARCHIVE_PATH%" ^
  -HashAlgorithm "%FFMPEG_HASH_ALGORITHM%" ^
  -HashEncoding "%FFMPEG_HASH_ENCODING%" ^
  -ExpectedHash "%FFMPEG_HASH%"
if errorlevel 1 exit /b 1

set "EXTRACT=%DOWNLOADS%\ffmpeg-extract"
if exist "%EXTRACT%" rmdir /s /q "%EXTRACT%"
mkdir "%EXTRACT%" || exit /b 1

"%SEVENZIP_EXE%" x "%FFMPEG_ARCHIVE_PATH%" -o"%EXTRACT%" -y >nul
if errorlevel 1 exit /b 1

set "FOUND="
for /d %%D in ("%EXTRACT%\ffmpeg-%FFMPEG_VERSION%-full_build-shared*") do (
    set "FOUND=1"
    if exist "%FFMPEG_HOME%" rmdir /s /q "%FFMPEG_HOME%"
    mkdir "%FFMPEG_HOME%" || exit /b 1
    xcopy "%%D\*" "%FFMPEG_HOME%\" /E /I /Y >nul
    if errorlevel 1 exit /b 1
)

if not defined FOUND (
    echo ERROR: extracted FFmpeg directory was not found under:
    echo   "%EXTRACT%"
    exit /b 1
)

rmdir /s /q "%EXTRACT%" >nul 2>&1

if not exist "%FFMPEG_HOME%\bin\ffmpeg.exe" (
    echo ERROR: ffmpeg.exe missing after extraction:
    echo   "%FFMPEG_HOME%\bin\ffmpeg.exe"
    exit /b 1
)

if not exist "%FFMPEG_HOME%\bin\avcodec-61.dll" (
    echo ERROR: FFmpeg shared DLL missing after extraction:
    echo   "%FFMPEG_HOME%\bin\avcodec-61.dll"
    exit /b 1
)

echo [OK] FFmpeg %FFMPEG_VERSION% full shared
exit /b 0
