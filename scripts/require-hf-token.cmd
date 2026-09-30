@echo off

if defined HF_TOKEN exit /b 0

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"
for %%I in ("%SCRIPT_DIR%\..") do set "ROOT=%%~fI"

if not exist "%ROOT%\setup\config.cmd" (
    echo ERROR: path configuration is missing:
    echo   "%ROOT%\setup\config.cmd"
    exit /b 1
)

call "%ROOT%\setup\config.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

if exist "%HF_TOKEN_FILE%" (
    call "%HF_TOKEN_FILE%"
)

if defined HF_TOKEN exit /b 0

if not exist "%ROOT%\hf-token.cmd.example" (
    echo ERROR: Hugging Face token example is missing.
    echo Run repair.cmd to restore:
    echo   "%ROOT%\hf-token.cmd.example"
    exit /b 1
)

echo ERROR: Hugging Face token is required for diarization.
echo.
echo Copy:
echo   hf-token.cmd.example
echo to:
echo   hf-token.cmd
echo.
echo Then replace hf_XXX with a Hugging Face read token.
exit /b 1
