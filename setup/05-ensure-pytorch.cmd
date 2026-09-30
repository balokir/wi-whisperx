@echo off
setlocal
call "%~dp0config.cmd"
call "%SCRIPTS_DIR%\env.cmd"

set "PY=%VENV%\Scripts\python.exe"

if not exist "%PY%" exit /b 1

rem Validate the complete PyTorch stack as one compatibility unit.
"%PY%" -c "import torch, torchaudio, torchvision; ok=(torch.__version__=='%PYTORCH_PACKAGE_VERSION%' and torchaudio.__version__=='%TORCHAUDIO_PACKAGE_VERSION%' and torchvision.__version__=='%TORCHVISION_PACKAGE_VERSION%' and str(torch.version.cuda)=='%CUDA_RUNTIME_VERSION%'); raise SystemExit(0 if ok else 1)" >nul 2>&1
if errorlevel 1 goto :fix_stack

echo [OK] torch %PYTORCH_PACKAGE_VERSION%
echo [OK] torchaudio %TORCHAUDIO_PACKAGE_VERSION%
echo [OK] torchvision %TORCHVISION_PACKAGE_VERSION%
goto :check_cuda

:fix_stack
echo [FIX] PyTorch CUDA stack
echo       torch %PYTORCH_PACKAGE_VERSION%
echo       torchaudio %TORCHAUDIO_PACKAGE_VERSION%
echo       torchvision %TORCHVISION_PACKAGE_VERSION%

rem Install the three mutually compatible packages in one resolver transaction.
rem This avoids installing torch first and then reinstalling it again while
rem resolving torchvision dependencies.
"%PY%" -m pip install --upgrade --force-reinstall ^
  "torch==%PYTORCH_PACKAGE_VERSION%" ^
  "torchaudio==%TORCHAUDIO_PACKAGE_VERSION%" ^
  "torchvision==%TORCHVISION_PACKAGE_VERSION%" ^
  --index-url https://download.pytorch.org/whl/%CUDA_WHEEL%
if errorlevel 1 exit /b 1

rem Verify exact versions and the expected CUDA runtime after installation.
"%PY%" -c "import torch, torchaudio, torchvision; ok=(torch.__version__=='%PYTORCH_PACKAGE_VERSION%' and torchaudio.__version__=='%TORCHAUDIO_PACKAGE_VERSION%' and torchvision.__version__=='%TORCHVISION_PACKAGE_VERSION%' and str(torch.version.cuda)=='%CUDA_RUNTIME_VERSION%'); raise SystemExit(0 if ok else 1)" >nul 2>&1
if errorlevel 1 (
    echo ERROR: installed PyTorch stack does not match the configured versions.
    exit /b 1
)

echo [OK] torch %PYTORCH_PACKAGE_VERSION%
echo [OK] torchaudio %TORCHAUDIO_PACKAGE_VERSION%
echo [OK] torchvision %TORCHVISION_PACKAGE_VERSION%

:check_cuda
"%PY%" -c "import torch; raise SystemExit(0 if torch.cuda.is_available() else 1)" >nul 2>&1
if errorlevel 1 (
    echo ERROR: CUDA PyTorch is installed but no CUDA GPU is available.
    exit /b 1
)

echo [OK] CUDA GPU available
exit /b 0
