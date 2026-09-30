@echo off
setlocal EnableExtensions
call "%~dp0config.cmd"

set "PY=%VENV%\Scripts\python.exe"
set "CHECKPOINT=%VENV%\Lib\site-packages\whisperx\assets\pytorch_model.bin"
set "CHECKER=%SETUP_DIR%\check_checkpoint.py"
set "SMOKE=%SETUP_DIR%\functional_smoke.py"
set "PYANNOTE_PATCHER=%SETUP_DIR%\patch_pyannote_pooling.py"
set "PYANNOTE_POOLING=%VENV%\Lib\site-packages\pyannote\audio\models\blocks\pooling.py"
set "FAILED=0"
set "RUNTIME_LAYOUT_OK=1"
set "ENV_OK=1"

call "%SETUP_DIR%\runtime-layout.cmd"
if errorlevel 1 (
    echo [BROKEN] runtime layout definition
    set "FAILED=1"
    set "RUNTIME_LAYOUT_OK=0"
)

echo [Verify] Checking installation...

call "%SETUP_DIR%\00-validate-layout.cmd"
if errorlevel 1 set "FAILED=1"

if not exist "%ROOT%\hf-token.cmd.example" (
    echo [BROKEN] Hugging Face token example missing
    set "FAILED=1"
) else (
    echo [OK] Hugging Face token example
)

rem Verify the actual runtime environment used by WhisperX.
call "%SCRIPTS_DIR%\env.cmd"
if errorlevel 1 (
    echo [BROKEN] runtime environment initialization
    set "FAILED=1"
    set "ENV_OK=0"
) else (
    call :check_env_value "HF_HOME" "%HF_HOME%" "%CACHE%\huggingface"
    call :check_env_value "HF_HUB_CACHE" "%HF_HUB_CACHE%" "%CACHE%\huggingface\hub"
    call :check_env_value "HF_XET_CACHE" "%HF_XET_CACHE%" "%CACHE%\huggingface\xet"
    call :check_env_value "TORCH_HOME" "%TORCH_HOME%" "%CACHE%\torch"
    call :check_env_value "PIP_CACHE_DIR" "%PIP_CACHE_DIR%" "%CACHE%\pip"
    call :check_env_value "NLTK_DATA" "%NLTK_DATA%" "%CACHE%\nltk"
    call :check_env_value "XDG_CACHE_HOME" "%XDG_CACHE_HOME%" "%CACHE%"
    call :check_env_value "TMP" "%TMP%" "%CACHE%\tmp"
    call :check_env_value "TEMP" "%TEMP%" "%CACHE%\tmp"
    call :check_env_value "WHISPERX_FFMPEG_BIN" "%WHISPERX_FFMPEG_BIN%" "%FFMPEG_HOME%\bin"
    call :check_env_value "PYANNOTE_METRICS_ENABLED" "%PYANNOTE_METRICS_ENABLED%" "0"
    call :check_env_value "WHISPERX_DISABLE_TF32" "%WHISPERX_DISABLE_TF32%" "1"
    call :check_env_value "HF_HUB_DISABLE_SYMLINKS_WARNING" "%HF_HUB_DISABLE_SYMLINKS_WARNING%" "1"
    call :check_env_value "PIP_DISABLE_PIP_VERSION_CHECK" "%PIP_DISABLE_PIP_VERSION_CHECK%" "1"

    if exist "%PYTHON_HOME%\python.exe" (
        "%PYTHON_HOME%\python.exe" -c "import os,sys; expected=os.path.normcase(os.path.abspath(sys.argv[1])); first=os.path.normcase(os.path.abspath(os.environ.get('PATH','').split(os.pathsep)[0])); raise SystemExit(0 if first == expected else 1)" "%FFMPEG_HOME%\bin" >nul 2>&1
        if errorlevel 1 (
            echo [BROKEN] runtime environment PATH does not start with local FFmpeg
            set "FAILED=1"
            set "ENV_OK=0"
        )
    )
)

if "%ENV_OK%"=="1" echo [OK] runtime environment

call :verify_base_python
if errorlevel 1 (
    set "FAILED=1"
) else (
    echo [OK] Python %PYTHON_VERSION%
)

if not exist "%FFMPEG_HOME%\bin\ffmpeg.exe" (
    echo [BROKEN] FFmpeg missing
    set "FAILED=1"
) else if not exist "%FFMPEG_HOME%\bin\avcodec-61.dll" (
    echo [BROKEN] FFmpeg shared DLLs missing
    set "FAILED=1"
) else (
    "%FFMPEG_HOME%\bin\ffmpeg.exe" -version 2>nul | findstr /C:"ffmpeg version %FFMPEG_VERSION%-" >nul
    if errorlevel 1 (
        echo [BROKEN] FFmpeg version
        set "FAILED=1"
    ) else (
        echo [OK] FFmpeg %FFMPEG_VERSION% full shared
    )
)

if not exist "%PY%" (
    echo [BROKEN] venv missing
    set "FAILED=1"
) else (
    "%PY%" -c "import os, sys; expected=os.path.normcase(os.path.abspath(sys.argv[1])); actual=os.path.normcase(os.path.abspath(sys._base_executable)); raise SystemExit(0 if actual == expected else 1)" "%PYTHON_HOME%\python.exe" >nul 2>&1
    if errorlevel 1 (
        echo [BROKEN] venv base Python path
        set "FAILED=1"
    ) else (
        echo [OK] venv
    )
)

if not exist "%VENV%\Lib\site-packages\sitecustomize.py" (
    echo [BROKEN] runtime sitecustomize.py missing
    set "FAILED=1"
) else (
    fc /b "%SETUP_DIR%\sitecustomize.py" "%VENV%\Lib\site-packages\sitecustomize.py" >nul 2>&1
    if errorlevel 1 (
        echo [BROKEN] runtime sitecustomize.py differs from expected
        set "FAILED=1"
    ) else (
        echo [OK] runtime configuration
    )
)

if exist "%PY%" (
    "%PY%" -c "import torch; ok=(torch.__version__=='%PYTORCH_PACKAGE_VERSION%' and str(torch.version.cuda)=='%CUDA_RUNTIME_VERSION%'); raise SystemExit(0 if ok else 1)" >nul 2>&1
    if errorlevel 1 (
        echo [BROKEN] torch %PYTORCH_PACKAGE_VERSION%
        set "FAILED=1"
    ) else (
        echo [OK] torch %PYTORCH_PACKAGE_VERSION%
    )

    "%PY%" -c "import torchaudio; raise SystemExit(0 if torchaudio.__version__=='%TORCHAUDIO_PACKAGE_VERSION%' else 1)" >nul 2>&1
    if errorlevel 1 (
        echo [BROKEN] torchaudio %TORCHAUDIO_PACKAGE_VERSION%
        set "FAILED=1"
    ) else (
        echo [OK] torchaudio %TORCHAUDIO_PACKAGE_VERSION%
    )

    "%PY%" -c "import torchvision; raise SystemExit(0 if torchvision.__version__=='%TORCHVISION_PACKAGE_VERSION%' else 1)" >nul 2>&1
    if errorlevel 1 (
        echo [BROKEN] torchvision %TORCHVISION_PACKAGE_VERSION%
        set "FAILED=1"
    ) else (
        echo [OK] torchvision %TORCHVISION_PACKAGE_VERSION%
    )

    "%PY%" -c "import torch; raise SystemExit(0 if torch.cuda.is_available() else 1)" >nul 2>&1
    if errorlevel 1 (
        echo [BROKEN] CUDA GPU unavailable
        set "FAILED=1"
    ) else (
        echo [OK] CUDA GPU available
    )

    "%PY%" -m pip check >nul 2>&1
    if errorlevel 1 (
        echo [BROKEN] Python dependency closure
        set "FAILED=1"
    ) else (
        echo [OK] Python dependency closure
    )

    if not exist "%SMOKE%" (
        echo [BROKEN] functional smoke helper missing
        set "FAILED=1"
    ) else (
        "%PY%" "%SMOKE%"
        if errorlevel 1 (
            echo [BROKEN] WhisperX functional runtime smoke
            set "FAILED=1"
        )
    )

    if not exist "%PYANNOTE_PATCHER%" (
        echo [BROKEN] pyannote patch helper missing
        set "FAILED=1"
    ) else (
        "%PY%" "%PYANNOTE_PATCHER%" --check "%PYANNOTE_POOLING%" >nul 2>&1
        if errorlevel 1 (
            echo [BROKEN] pyannote StatsPool single-frame fix
            set "FAILED=1"
        ) else (
            echo [OK] pyannote StatsPool single-frame fix
        )
    )

    "%PY%" -c "import importlib.metadata as m, sys; reqs=sys.argv[1:]; ok=True; exec('for r in reqs:\n n,v=r.split(\"==\",1)\n try:\n  actual=m.version(n)\n except m.PackageNotFoundError:\n  ok=False\n  continue\n if actual != v:\n  ok=False'); raise SystemExit(0 if ok else 1)" %WHISPERX_COMPAT_REQUIREMENTS% >nul 2>&1
    if errorlevel 1 (
        echo [BROKEN] WhisperX compatibility stack
        set "FAILED=1"
    ) else (
        echo [OK] WhisperX %WHISPERX_VERSION% compatibility stack
    )

    if not exist "%CHECKPOINT%" (
        echo [BROKEN] WhisperX checkpoint asset missing
        set "FAILED=1"
    ) else if not exist "%CHECKER%" (
        echo [BROKEN] checkpoint verifier missing
        set "FAILED=1"
    ) else (
        "%PY%" "%CHECKER%" "%CHECKPOINT%" >nul 2>&1
        if errorlevel 1 (
            echo [BROKEN] WhisperX checkpoint format
            set "FAILED=1"
        ) else (
            echo [OK] WhisperX checkpoint format
        )
    )
)

if "%RUNTIME_LAYOUT_OK%"=="1" (
    call :verify_runtime_dirs
    if errorlevel 1 set "FAILED=1"
)

if "%FAILED%"=="0" exit /b 0
exit /b 1

:verify_base_python
if not exist "%PYTHON_HOME%\python.exe" (
    echo [BROKEN] Python missing
    exit /b 1
)

"%PYTHON_HOME%\python.exe" -c "import platform; raise SystemExit(0 if platform.python_version() == '%PYTHON_VERSION%' else 1)" >nul 2>&1
if errorlevel 1 (
    echo [BROKEN] Python version
    exit /b 1
)

"%PYTHON_HOME%\python.exe" -m pip --version >nul 2>&1
if errorlevel 1 (
    echo [BROKEN] Python pip
    exit /b 1
)

"%PYTHON_HOME%\python.exe" -c "import venv" >nul 2>&1
if errorlevel 1 (
    echo [BROKEN] Python venv module
    exit /b 1
)

exit /b 0

:verify_runtime_dirs
set "RUNTIME_DIRS_OK=1"

for %%D in (%RUNTIME_REQUIRED_DIRS%) do (
    call :check_runtime_dir "%%~D"
)

if "%RUNTIME_DIRS_OK%"=="1" (
    echo [OK] local runtime directories
    exit /b 0
)

exit /b 1

:check_runtime_dir
if exist "%~1\" exit /b 0

echo [BROKEN] required runtime directory missing:
echo   "%~1"
set "RUNTIME_DIRS_OK=0"
exit /b 0

:check_env_value
if /I "%~2"=="%~3" exit /b 0

echo [BROKEN] runtime environment %~1
echo   actual:   "%~2"
echo   expected: "%~3"
set "FAILED=1"
set "ENV_OK=0"
exit /b 0
