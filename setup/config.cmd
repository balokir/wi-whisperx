@echo off

rem Canonical repository paths.
rem IMPORTANT: directory variables do NOT end with a backslash.
for %%I in ("%~dp0.") do set "SETUP_DIR=%%~fI"
for %%I in ("%SETUP_DIR%\..") do set "ROOT=%%~fI"

set "SCRIPTS_DIR=%ROOT%\scripts"

set "PYTHON_VERSION=3.11.9"

set "PYTORCH_PACKAGE_VERSION=2.8.0+cu128"
set "TORCHAUDIO_PACKAGE_VERSION=2.8.0+cu128"
set "TORCHVISION_PACKAGE_VERSION=0.23.0+cu128"
set "CUDA_WHEEL=cu128"
set "CUDA_RUNTIME_VERSION=12.8"

set "WHISPERX_VERSION=3.8.6"

rem Compatibility-critical WhisperX dependency versions validated together.
set "PYANNOTE_AUDIO_VERSION=4.0.7"
set "LIGHTNING_VERSION=2.6.6"
set "TORCHCODEC_VERSION=0.7.0"
set "CTRANSLATE2_VERSION=4.8.2"
set "FASTER_WHISPER_VERSION=1.2.1"
set "HUGGINGFACE_HUB_VERSION=0.36.2"
set "HF_XET_VERSION=1.6.0"

rem Canonical package/version contract used by setup\06-ensure-whisperx.cmd.
set "WHISPERX_COMPAT_REQUIREMENTS=whisperx==%WHISPERX_VERSION% pyannote-audio==%PYANNOTE_AUDIO_VERSION% lightning==%LIGHTNING_VERSION% torchcodec==%TORCHCODEC_VERSION% ctranslate2==%CTRANSLATE2_VERSION% faster-whisper==%FASTER_WHISPER_VERSION% huggingface-hub==%HUGGINGFACE_HUB_VERSION% hf-xet==%HF_XET_VERSION%"

set "FFMPEG_VERSION=7.1.1"

set "LOCAL=%ROOT%\.local"
set "RUNTIME=%LOCAL%\runtime"
set "PYTHON_HOME=%RUNTIME%\python"
set "FFMPEG_HOME=%RUNTIME%\ffmpeg"
set "VENV=%RUNTIME%\venv"

set "CACHE=%LOCAL%\cache"
set "DOWNLOADS=%LOCAL%\downloads"
set "MODELS=%LOCAL%\models"
set "LOGS=%LOCAL%\logs"

set "TRANSCRIPT=%ROOT%\transcript"
set "HF_TOKEN_FILE=%ROOT%\hf-token.cmd"

set "PYTHON_PACKAGE=python-%PYTHON_VERSION%-nuget.zip"
set "PYTHON_PACKAGE_PATH=%DOWNLOADS%\%PYTHON_PACKAGE%"
set "PYTHON_EXTRACT=%DOWNLOADS%\python-%PYTHON_VERSION%-nuget-extract"
set "PYTHON_URL=https://api.nuget.org/v3-flatcontainer/python/%PYTHON_VERSION%/python.%PYTHON_VERSION%.nupkg"
set "PYTHON_HASH_ALGORITHM=SHA512"
set "PYTHON_HASH_ENCODING=Base64"
set "PYTHON_HASH=41On79FZ75irnOEBGFSjDV13j1nZb8m7EbB87SmQs1XwMEhrBwf3mMc8RCAXOrERh2qW6tWYFxi2BMTN1xxVjQ=="

set "FFMPEG_ARCHIVE=ffmpeg-%FFMPEG_VERSION%-full_build-shared.7z"
set "FFMPEG_ARCHIVE_PATH=%DOWNLOADS%\%FFMPEG_ARCHIVE%"
set "FFMPEG_URL=https://github.com/GyanD/codexffmpeg/releases/download/%FFMPEG_VERSION%/%FFMPEG_ARCHIVE%"
set "FFMPEG_HASH_ALGORITHM=SHA256"
set "FFMPEG_HASH_ENCODING=Hex"
set "FFMPEG_HASH=b73e7ed754d7aae42783bb3d768c33f0c8dbe53ed9859b7cf910a23d442780b3"

set "SEVENZIP_VERSION=26.03"
set "SEVENZIP_PACKAGE=7zr-%SEVENZIP_VERSION%.exe"
set "SEVENZIP_EXE=%DOWNLOADS%\%SEVENZIP_PACKAGE%"
set "SEVENZIP_URL=https://github.com/ip7z/7zip/releases/download/%SEVENZIP_VERSION%/7zr.exe"
set "SEVENZIP_HASH_ALGORITHM=SHA256"
set "SEVENZIP_HASH_ENCODING=Hex"
set "SEVENZIP_HASH=ad4c82fadcbdf93c03b4fc440f300509c7d60c5c2f4d183e35d9d70d6957037d"

set "SYSTEM_POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
