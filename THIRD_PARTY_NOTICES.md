# Third-party software and models

This repository contains original setup/repair/verification scripts and documentation.

It does **not** redistribute third-party binaries or model weights.

During installation or first use, the scripts may download software, Python packages, and model artifacts directly from their respective upstream sources.

Those third-party components are **not** covered by this repository's MIT License. They remain subject to their own licenses, terms, model cards, access conditions, and redistribution requirements.

## Main upstream dependencies

### Python / CPython

Project:

https://www.python.org/

The setup downloads the official CPython 3.11.9 NuGet package from nuget.org, verifies its pinned package hash, and extracts it into the local runtime directory.

Python is not redistributed by this repository and remains subject to the Python Software Foundation license and other applicable upstream terms.

### 7-Zip

Project:

https://www.7-zip.org/

The setup downloads the pinned `7zr.exe` extractor from the official 7-Zip GitHub release (`ip7z/7zip`) and uses it locally to unpack the FFmpeg archive.

7-Zip is not redistributed by this repository and remains subject to its own upstream license and terms.

### WhisperX

Project:

https://github.com/m-bain/whisperX

WhisperX is installed from its upstream package/source and remains subject to its upstream license and terms.

### PyTorch / torchaudio / torchvision

Project:

https://pytorch.org/

CUDA-enabled wheels are downloaded from the official PyTorch package index.

They remain subject to the PyTorch project's own license and terms.

### pyannote.audio

Project:

https://github.com/pyannote/pyannote-audio

pyannote.audio is used for VAD/diarization-related functionality and remains subject to its own license and terms.

### pyannote speaker-diarization-community-1 model

Model page:

https://huggingface.co/pyannote/speaker-diarization-community-1

At the time this repository was documented, the model card identifies the model as CC-BY-4.0 and requires users to accept access conditions/share requested contact information before downloading gated files.

The model is downloaded directly from Hugging Face and is not redistributed by this repository.

### Hugging Face Hub

Project/service:

https://huggingface.co/

Hugging Face is used to download hosted model artifacts.

Users are responsible for complying with the terms/access conditions of each downloaded model repository.

### faster-whisper

Project:

https://github.com/SYSTRAN/faster-whisper

Installed from upstream and subject to its upstream license.

### CTranslate2

Project:

https://github.com/OpenNMT/CTranslate2

Installed from upstream and subject to its upstream license.

### FFmpeg

Project:

https://ffmpeg.org/

A pinned full-shared Windows build is downloaded from the configured Gyan FFmpeg release source during setup and verified against its expected SHA-256 hash.

FFmpeg remains subject to its own licensing terms and to the licensing implications of the specific build configuration.

## Redistribution policy

This repository should remain source/scripts/documentation only.

Do not add third-party binaries or model weights to the Git repository or GitHub Releases without separately reviewing and satisfying the applicable licenses and redistribution terms.

The preferred design is:

1. keep only original scripts/documentation in this repository;
2. download third-party components directly from their upstream sources;
3. keep downloaded artifacts local to the user's installation directory.
