@echo off
setlocal EnableExtensions

call "%~dp0config.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

set "HF_TOKEN_EXAMPLE_FILE=%ROOT%\hf-token.cmd.example"
set "HF_TOKEN_EXAMPLE_TMP=%HF_TOKEN_EXAMPLE_FILE%.tmp"

if exist "%HF_TOKEN_EXAMPLE_FILE%" (
    echo [OK] Hugging Face token example
    exit /b 0
)

echo [FIX] Hugging Face token example

if exist "%HF_TOKEN_EXAMPLE_TMP%" del /f /q "%HF_TOKEN_EXAMPLE_TMP%" >nul 2>&1

(
    echo @echo off
    echo set "HF_TOKEN=hf_XXX"
) > "%HF_TOKEN_EXAMPLE_TMP%"

if errorlevel 1 (
    echo ERROR: cannot create temporary Hugging Face token example:
    echo   "%HF_TOKEN_EXAMPLE_TMP%"
    exit /b 1
)

if not exist "%HF_TOKEN_EXAMPLE_TMP%" (
    echo ERROR: temporary Hugging Face token example was not created:
    echo   "%HF_TOKEN_EXAMPLE_TMP%"
    exit /b 1
)

move /y "%HF_TOKEN_EXAMPLE_TMP%" "%HF_TOKEN_EXAMPLE_FILE%" >nul
if errorlevel 1 (
    echo ERROR: cannot install Hugging Face token example:
    echo   "%HF_TOKEN_EXAMPLE_FILE%"
    exit /b 1
)

if not exist "%HF_TOKEN_EXAMPLE_FILE%" (
    echo ERROR: Hugging Face token example is still missing after creation:
    echo   "%HF_TOKEN_EXAMPLE_FILE%"
    exit /b 1
)

echo [OK] Hugging Face token example
exit /b 0
