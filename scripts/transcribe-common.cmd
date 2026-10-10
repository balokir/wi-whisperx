@echo off
setlocal EnableExtensions

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"
for %%I in ("%SCRIPT_DIR%\..") do set "ROOT=%%~fI"

if not exist "%ROOT%\setup\config.cmd" (
    echo ERROR: path configuration is missing:
    echo   "%ROOT%\setup\config.cmd"
    exit /b 1
)

call "%ROOT%\setup\config.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

if "%~1"=="" (
    echo ERROR: Input file is not specified.
    exit /b 1
)

if not exist "%~1" (
    echo ERROR: Input file does not exist:
    echo   "%~1"
    exit /b 1
)

set "MODE=%~2"
if "%MODE%"=="" set "MODE=plain"

if not exist "%TRANSCRIPT%" mkdir "%TRANSCRIPT%"
if errorlevel 1 (
    echo ERROR: cannot create transcript directory:
    echo   "%TRANSCRIPT%"
    exit /b 1
)

for %%F in ("%~1") do set "base_name=%%~nF"

if /I "%MODE%"=="plain" goto :plain
if /I "%MODE%"=="diarize" goto :diarize
if /I "%MODE%"=="diarize-speakers" goto :diarize_speakers

echo ERROR: Unknown transcription mode: %MODE%
exit /b 1

:plain
call "%SCRIPTS_DIR%\whisperx.cmd" "%~1" ^
  --model large-v3-turbo ^
  --language ru ^
  --device cuda ^
  --compute_type int8 ^
  --output_dir "%TRANSCRIPT%" ^
  --output_format all ^
  --verbose False ^
  --print_progress True ^
  --log-level error
goto :after_run

:diarize
call "%SCRIPTS_DIR%\require-hf-token.cmd" || exit /b 1
rem Use inherited HF_TOKEN even when the caller disabled implicit Hub authentication.
set "HF_HUB_DISABLE_IMPLICIT_TOKEN=0"
call "%SCRIPTS_DIR%\whisperx.cmd" "%~1" ^
  --model large-v3-turbo ^
  --language ru ^
  --device cuda ^
  --compute_type int8 ^
  --output_dir "%TRANSCRIPT%" ^
  --output_format all ^
  --diarize ^
  --verbose False ^
  --print_progress True ^
  --log-level error
goto :after_run

:diarize_speakers
if "%~3"=="" (
    echo ERROR: Speaker count is not specified.
    exit /b 1
)

echo(%~3| findstr /r "^[1-9][0-9]*$" >nul
if errorlevel 1 (
    echo ERROR: Speaker count must be a positive integer: "%~3"
    exit /b 1
)

call "%SCRIPTS_DIR%\require-hf-token.cmd" || exit /b 1
rem Use inherited HF_TOKEN even when the caller disabled implicit Hub authentication.
set "HF_HUB_DISABLE_IMPLICIT_TOKEN=0"
call "%SCRIPTS_DIR%\whisperx.cmd" "%~1" ^
  --model large-v3-turbo ^
  --language ru ^
  --device cuda ^
  --compute_type int8 ^
  --output_dir "%TRANSCRIPT%" ^
  --output_format all ^
  --diarize ^
  --min_speakers %~3 ^
  --max_speakers %~3 ^
  --verbose False ^
  --print_progress True ^
  --log-level error
goto :after_run

:after_run
set "RUN_RC=%ERRORLEVEL%"
if not "%RUN_RC%"=="0" exit /b %RUN_RC%

rem WhisperX CLI can emit one format or all formats. Keep only TXT + SRT.
del "%TRANSCRIPT%\%base_name%.vtt" 2>nul
del "%TRANSCRIPT%\%base_name%.tsv" 2>nul
del "%TRANSCRIPT%\%base_name%.json" 2>nul
del "%TRANSCRIPT%\%base_name%.aud" 2>nul

echo.
echo Output:
echo   "%TRANSCRIPT%\%base_name%.txt"
echo   "%TRANSCRIPT%\%base_name%.srt"

exit /b 0
