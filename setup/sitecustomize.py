import os
from pathlib import Path

# Installed location:
#   <repo>\.local\runtime\venv\Lib\site-packages\sitecustomize.py
#
# Therefore:
#   site_packages -> Lib -> venv -> runtime
_site_packages = Path(__file__).resolve().parent
_lib_dir = _site_packages.parent
_venv_dir = _lib_dir.parent
_runtime_dir = _venv_dir.parent
_ffmpeg_bin = _runtime_dir / "ffmpeg" / "bin"

_ffmpeg_dll_directory_handle = None

if _ffmpeg_bin.is_dir():
    _ffmpeg_dll_directory_handle = os.add_dll_directory(str(_ffmpeg_bin))
    os.environ["PATH"] = str(_ffmpeg_bin) + os.pathsep + os.environ.get("PATH", "")

if os.environ.get("WHISPERX_DISABLE_TF32") == "1":
    try:
        import torch

        torch.backends.cuda.matmul.allow_tf32 = False
        torch.backends.cudnn.allow_tf32 = False
    except ImportError:
        pass
