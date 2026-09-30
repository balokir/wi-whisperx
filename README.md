# Local WhisperX for Windows 11

A practical Windows 11 setup for running WhisperX locally, with explicit fixes for the Windows/runtime issues
encountered during a real installation.

The intent is deliberately simple:

- keep Python, FFmpeg, the Python environment, caches, and downloaded models inside the repository's generated `.local`
  directory;
- avoid depending on a pre-existing global Python or FFmpeg;
- avoid permanently modifying the system `PATH`;
- use CUDA-enabled PyTorch on NVIDIA GPUs;
- support WhisperX transcription, alignment, and speaker diarization;
- document and fix the compatibility problems that otherwise make a Windows setup surprisingly fragile;
- keep the repository itself source/scripts/documentation only.

This repository is **not** a fork of WhisperX and does **not** redistribute third-party binaries or model weights.

## Quick start

Install:

```cmd
install.cmd
```

Transcribe to `.txt` and `.srt`:

```cmd
transcribe.bat "C:\path\meeting.m4a"
```

Transcribe with speaker diarization:

```cmd
transcribe-diarize.bat "C:\path\meeting.m4a"
```

If the exact number of speakers is known:

```cmd
transcribe-diarize-speakers.bat "C:\path\meeting.m4a" 3
```

Measure execution time for any command:

```cmd
measure.cmd transcribe-diarize-speakers.bat "C:\path\meeting.m4a" 3
```

Results are written to:

```text
transcript\
```

## Repository layout

The repository contains only source, scripts, and documentation:

```text
wi-whisperx\
├── README.md
├── LICENSE
├── THIRD_PARTY_NOTICES.md
├── .gitignore
├── install.cmd
├── repair.cmd
├── verify.cmd
├── measure.cmd
│
├── transcribe.bat
├── transcribe-diarize.bat
├── transcribe-diarize-speakers.bat
│
├── scripts\
│   ├── env.cmd
│   ├── whisperx.cmd
│   ├── require-hf-token.cmd
│   ├── transcribe-common.cmd
│   ├── run-with-log.ps1
│   └── measure.ps1
│
└── setup\
    ├── config.cmd
    ├── ensure-all.cmd
    ├── 01-ensure-python.cmd
    ├── ...
    └── *.py
```

Installation creates a gitignored local state directory:

```text
.local\
├── runtime\
│   ├── python\
│   ├── ffmpeg\
│   └── venv\
├── cache\
│   ├── huggingface\
│   ├── pip\
│   ├── torch\
│   ├── nltk\
│   └── tmp\
├── models\
│   └── whisper\
└── downloads\
```

Path handling is centralized in `setup\config.cmd`. Canonical directory variables such as `SETUP_DIR`, `ROOT`,
`RUNTIME`, and `VENV` are normalized **without trailing backslashes**; child paths always add `\` explicitly. This
avoids Windows command-line quoting ambiguity for quoted paths ending in `\`. `install.cmd`/`repair.cmd` run a read-only
repository layout check before installation work begins.

This separation is intentional:

- `setup\` and `scripts\` are repository code;
- `.local\` is generated installation state;
- `transcript\` is user output;
- neither `.local\` nor `transcript\` should be committed.

## Tested configuration

**Last verified:** 2026-10-04

| Component                    | Tested configuration |
|------------------------------|----------------------|
| OS                           | Windows 11 x64       |
| GPU                          | NVIDIA Quadro T1000  |
| VRAM                         | 4 GB                 |
| NVIDIA driver                | 581.95               |
| Python                       | 3.11.9               |
| WhisperX                     | 3.8.6                |
| pyannote.audio               | 4.0.7                |
| Lightning                    | 2.6.6                |
| TorchCodec                   | 0.7.0                |
| CTranslate2                  | 4.8.2                |
| faster-whisper               | 1.2.1                |
| huggingface-hub              | 0.36.2               |
| hf-xet                       | 1.6.0                |
| PyTorch                      | 2.8.0+cu128          |
| torchaudio                   | 2.8.0+cu128          |
| torchvision                  | 0.23.0+cu128         |
| CUDA runtime used by PyTorch | 12.8                 |
| FFmpeg                       | 7.1.1 full shared    |
| Whisper model                | `large-v3-turbo`     |
| Compute type                 | `int8`               |
| Primary test language        | Russian              |

Other GPUs and versions may work, but this repository should be treated as **tested with the configuration above**, not
as a universal WhisperX installer.

## Observed performance

These are measurements from the machine above, not guaranteed performance figures.

| Audio duration | Diarization | Processing time |
|----------------|-------------|----------------:|
| ~10 min        | yes         |          ~3 min |
| ~60 min        | yes         |         ~20 min |
| ~60 min        | no          |         ~12 min |

The tests used `large-v3-turbo`, CUDA, and `int8`.

Actual performance depends on the audio, GPU, alignment model, diarization, speaker count, storage, and whether models
are already cached.

## Disk usage

After installation and the first real transcription/diarization runs, the generated `.local` state occupied
approximately:

```text
~20 GB
```

This is an observed value, not a fixed requirement.

The size depends on:

- Whisper models;
- alignment models;
- diarization models;
- Hugging Face cache;
- pip cache;
- model revisions;
- whether Windows can use symlinks for Hugging Face caching.

## What is installed locally

`install.cmd` creates the local runtime under `.local\`, including:

- portable Python 3.11.9 from the official CPython NuGet package;
- a Python virtual environment;
- FFmpeg 7.1.1 full shared build;
- PyTorch 2.8.0 CUDA 12.8 build;
- torchaudio;
- torchvision;
- WhisperX 3.8.6;
- the pinned WhisperX compatibility stack;
- local pip/Hugging Face/Torch cache directories.

Whisper, alignment, and diarization model files are downloaded on first use of the corresponding functionality and are
then reused from the local model/cache directories.

The scripts do **not** intentionally replace global Python/FFmpeg installations or permanently modify the system `PATH`.

Python is provisioned from the official CPython NuGet package rather than through the normal Windows Python installer.
The package is downloaded, extracted, verified for `python`, `pip`, and `venv`, and copied under
`.local\runtime\python`. This avoids registering the project Python as a machine/user Python installation and avoids
conflicts with stale Windows Python installer registrations.

### Pinned WhisperX compatibility stack

The following compatibility-sensitive packages are pinned to the versions validated together with this repository:

```text
whisperx==3.8.6
pyannote-audio==4.0.7
lightning==2.6.6
torchcodec==0.7.0
ctranslate2==4.8.2
faster-whisper==1.2.1
huggingface-hub==0.36.2
hf-xet==1.6.0
```

`setup\config.cmd` is the authoritative source for these versions. `install.cmd`/`repair.cmd` reconcile the environment
to this compatibility set and then reassert the separately pinned CUDA PyTorch stack.

The rest of the transitive Python dependency graph is intentionally resolver-managed rather than fully frozen.

### Download integrity

Downloaded executable/archive artifacts are pinned by versioned source plus expected cryptographic hash in
`setup\config.cmd`.

The installer verifies:

- CPython 3.11.9 NuGet package using the official NuGet `SHA512` package hash;
- 7-Zip 26.03 `7zr.exe` using `SHA256`;
- FFmpeg 7.1.1 full-shared archive using `SHA256`.

Cached artifacts are hash-checked before reuse. A cached file with the wrong hash is discarded and downloaded again. New
downloads are written to a temporary `.part` file and are promoted to the final cache path only after the expected hash
matches.

## System prerequisite: NVIDIA driver

The NVIDIA driver is outside the scope of this repository.

Download a current Windows driver from NVIDIA:

https://www.nvidia.com/Download/index.aspx

The tested machine used:

```text
NVIDIA driver 581.95
NVIDIA Quadro T1000
4 GB VRAM
```

The PyTorch stack is pinned to CUDA 12.8 wheels, so the installed NVIDIA driver must be new enough to support that
runtime.

Check the driver and GPU with:

```cmd
nvidia-smi
```

### CUDA Toolkit note

The scripts install CUDA-enabled PyTorch wheels locally.

They do **not** install or manage a global CUDA Toolkit.

The development machine used while building and testing this setup also had CUDA 12.8 installed system-wide. A
completely clean Windows machine with only the NVIDIA driver has not yet been validated as a separate test case.

## Installation

Clone or unpack the repository into the directory where it should live.

Then run:

```cmd
install.cmd
```

The installer ensures, in order:

1. hash-verified portable Python;
2. hash-verified local FFmpeg full-shared build and 7-Zip extractor;
3. local virtual environment;
4. local runtime/cache configuration;
5. pinned CUDA PyTorch stack;
6. pinned WhisperX compatibility stack plus a valid Python dependency closure;
7. required local compatibility fixes;
8. functional WhisperX runtime smoke test;
9. WhisperX/Lightning checkpoint compatibility.

A successful `install.cmd` is the end of installation.

**You should not need to run `repair.cmd` after a successful install.**

If `repair.cmd` changes something immediately after a successful install, treat that as an installer defect.

### Automatic logs

`install.cmd`, `repair.cmd`, and `verify.cmd` keep the child process attached directly to the console. This preserves
native terminal behavior such as the live `pip` download progress bar.

Each run writes a small run log under:

```text
.local\logs\
```

For example:

```text
.local\logs\install-20260930-164504.log
.local\logs\verify-20260930-171527.log
```

The run log contains non-secret invocation/diagnostic metadata:

- start/end time;
- repository root;
- working directory;
- target script;
- Windows version;
- PowerShell version;
- `ComSpec`;
- whether `nvidia-smi` is available;
- command;
- final exit code.

The full native console output is intentionally **not** piped through PowerShell logging because doing so breaks
interactive progress rendering.

When `pip` is used, the wrapper sets `PIP_LOG` for the child process and `pip` writes its own detailed diagnostic log,
for example:

```text
.local\logs\install-20260930-164504-pip.log
```

That pip log contains package resolution, download/install details, and pip errors.

The logger deliberately does **not** dump the full process environment because it may contain `HF_TOKEN` or other
secrets.

For troubleshooting, keep the console output and attach the relevant run log plus the corresponding `*-pip.log` when a
pip operation was involved.

## Verification

Run:

```cmd
verify.cmd
```

`verify.cmd` does not repair or modify the WhisperX runtime. It performs checks and may write diagnostic logs under
`.local\logs\`.

It validates:

- local Python version, `pip`, and `venv` support;
- local FFmpeg full-shared build;
- venv location;
- runtime environment/configuration;
- pinned CUDA PyTorch packages;
- pinned WhisperX compatibility stack;
- CUDA GPU availability;
- Python dependency metadata (`pip check`);
- actual WhisperX transcription/diarization import paths;
- TorchCodec + local FFmpeg integration;
- the local pyannote compatibility patch;
- WhisperX checkpoint format;
- generated local directories;
- generated `hf-token.cmd.example`.

## Repair

Run:

```cmd
repair.cmd
```

Small, well-defined problems are repaired in place.

If the **functional WhisperX runtime smoke test fails**, the Python environment is considered corrupted. Repair removes
only:

```text
.local\runtime\venv
```

and rebuilds it.

The following are preserved:

```text
.local\runtime\python
.local\runtime\ffmpeg
.local\cache
.local\models
.local\downloads
transcript
```

This preserves already downloaded multi-gigabyte models and caches.

## Moving the repository folder

Before installation, the repository can be moved freely.

After installation, the Windows virtual environment contains absolute references to its base Python location. Moving the
entire repository can therefore break:

```text
.local\runtime\venv
```

After moving the repository, run:

```cmd
repair.cmd
```

Repair should recreate the venv while preserving downloaded models, caches, local Python, local FFmpeg, and transcripts.

## First run

The first real transcription is slower because models must be downloaded.

Depending on enabled features, the first run may download:

- `large-v3-turbo`;
- a language-specific alignment model;
- pyannote diarization models;
- supporting Hugging Face assets.

Later runs should reuse `.local\cache` and `.local\models`.

## Local processing and network access

Speech recognition and diarization run locally on the machine.

This setup does not send the audio to an OpenAI transcription API.

Network access is still required to download:

- Python packages;
- Whisper models;
- alignment models;
- diarization models.

### pyannote telemetry

This setup disables pyannote usage telemetry by default:

```text
PYANNOTE_METRICS_ENABLED=0
```

This matches the local/private intent of the project. The setting is applied by `scripts\env.cmd` before
WhisperX/pyannote is started.

## Hugging Face and speaker diarization

WhisperX uses pyannote for speaker diarization.

Hugging Face is a model hosting platform. In this setup it is used to download the diarization model and other model
assets.

WhisperX currently uses:

```text
pyannote/speaker-diarization-community-1
```

for diarization by default.

Model page:

https://huggingface.co/pyannote/speaker-diarization-community-1

WhisperX:

https://github.com/m-bain/whisperX

### 1. Create a Hugging Face account

Create or log in to an account:

https://huggingface.co/

### 2. Accept the model access conditions

Open:

https://huggingface.co/pyannote/speaker-diarization-community-1

The model files are gated until the access conditions are accepted.

For **Company / university / organization** use truthful affiliation information:

- work-related usage: your actual company/organization;
- academic usage: your university/research organization;
- genuinely unaffiliated usage: `Independent` or `Personal` is reasonable if the form accepts it.

Do not invent a company affiliation.

### 3. Create a read token

Create a token:

https://huggingface.co/settings/tokens

For normal model download/inference, a token with **read** access is sufficient.

A write token is not required.

`install.cmd` creates `hf-token.cmd.example` in the project root. If it is deleted, `repair.cmd` restores it. The
generated example is gitignored and is intentionally not stored in the repository.

Copy:

```text
hf-token.cmd.example
```

to:

```text
hf-token.cmd
```

and replace the placeholder:

```bat
@echo off
set "HF_TOKEN=hf_xxxxxxxxxxxxxxxxx"
```

`hf-token.cmd.example` and `hf-token.cmd` are gitignored. The real `hf-token.cmd` contains the secret and must never be
committed.

The diarization wrappers also accept an already-defined `HF_TOKEN` environment variable.

## Windows Developer Mode and Hugging Face cache

Hugging Face normally uses symlinks to avoid duplicating large cached files.

On Windows, creating symlinks as a normal process generally requires Developer Mode (or elevated privileges).

Without Developer Mode:

- models still work;
- Hugging Face uses a degraded cache mode;
- some large files may be duplicated;
- disk usage can increase.

Microsoft documentation:

https://learn.microsoft.com/windows/apps/get-started/enable-your-device-for-development

Searching Windows Settings for **Developer Mode** is the safest way to find the setting across Windows 11 versions.

The setup suppresses the repetitive Hugging Face symlink warning. Suppressing the warning does **not** restore symlink
deduplication.

If disk usage matters, enable Developer Mode.

## Known Windows/runtime problems handled by this setup

### CUDA PyTorch accidentally replaced by a CPU build

The setup pins and reasserts:

```text
torch        2.8.0+cu128
torchaudio   2.8.0+cu128
torchvision  0.23.0+cu128
```

### TorchCodec and FFmpeg DLL discovery

TorchCodec needs FFmpeg shared DLLs on Windows.

The setup uses a local full-shared FFmpeg build under:

```text
.local\runtime\ffmpeg
```

and configures Python's DLL search path for that local runtime.

No global FFmpeg is required.

### WhisperX / Lightning legacy checkpoint

The setup checks the bundled WhisperX checkpoint, creates a one-time backup when migration is required, loads the
trusted local package asset with `weights_only=False`, applies Lightning migration, and saves it atomically.

### pyannote StatsPool single-frame warning / NaN

The setup applies a narrow compatibility patch for the one-frame case:

```python
if sequences.size(dim=-1) > 1:
    std = sequences.std(dim=-1, correction=1)
else:
    std = torch.zeros_like(mean)
```

The patch is idempotent and only applies to the exact expected upstream code shape.

### pyannote TF32 reproducibility warning

The local runtime configures the same TF32 mode pyannote expects before pyannote initializes, avoiding the repetitive
warning without changing its intended behavior.

### Corrupted Python environment after interrupted pip operations

`pip check` cannot detect every case where package metadata exists but actual package files are missing.

The setup therefore performs a functional WhisperX smoke test using the real transcription and diarization import paths.

If that smoke test fails, the whole `.local\runtime\venv` is rebuilt instead of performing increasingly fragile
package-by-package surgery.

## Transcription wrappers

### Plain transcription

```cmd
transcribe.bat "C:\path\meeting.m4a"
```

### Speaker diarization

```cmd
transcribe-diarize.bat "C:\path\meeting.m4a"
```

### Diarization with a known speaker count

```cmd
transcribe-diarize-speakers.bat "C:\path\meeting.m4a" 3
```

The wrappers use:

```text
large-v3-turbo
language=ru
device=cuda
compute_type=int8
```

and keep only:

```text
.txt
.srt
```

under:

```text
transcript\
```

For advanced/custom WhisperX arguments, use:

```cmd
scripts\whisperx.cmd ...
```

## Measuring execution time

`measure.cmd` can wrap any command and report both elapsed wall-clock time and the wrapped command's exit code.

Example:

```cmd
measure.cmd transcribe-diarize-speakers.bat "C:\path\meeting.m4a" 4
```

The wrapped command runs normally, then the wrapper prints:

```text
========================================
Elapsed:   00:19:42.817
Exit code: 0
========================================
```

This is useful for reproducing the performance measurements listed above.

## Known limitations

- NVIDIA/CUDA is the tested GPU path.
- AMD and Intel GPU acceleration are not covered.
- CPU-only operation is not the target configuration.
- The tested GPU has 4 GB VRAM, so `int8` is used with `large-v3-turbo`.
- The convenience wrappers currently default to Russian.
- **Hugging Face token exposure:** diarization currently passes `HF_TOKEN` to the WhisperX CLI through the `--hf_token` command-line argument. This means the token may be visible in the process command line to other processes/users with sufficient local privileges while diarization is running. The token is not intentionally written to this project's run logs, but users should treat the machine as a trusted environment and use a read-only Hugging Face token with the minimum required permissions.
- Diarization assigns speaker IDs; it does not know real speaker names.
- Overlapping speech and very short fragments can reduce diarization quality.
- Benchmarks are specific to the tested machine.
- Compatibility patches are version-sensitive and must be reviewed when upgrading WhisperX, pyannote, PyTorch, or
  related dependencies.
- Versions are intentionally pinned rather than automatically tracking latest upstream releases.

## Troubleshooting

Runtime diagnostics:

```cmd
verify.cmd
```

GPU/driver:

```cmd
nvidia-smi
```

Installation, repair, and verification metadata logs are written automatically to:

```text
.local\logs\
```

If the run invokes `pip`, a separate detailed `*-pip.log` is written there as well.

The full child-process output remains attached to the console so native progress indicators continue to work. For
non-pip failures, preserve/copy the console output together with the run log when reporting an issue.

For GPU/CUDA problems, also include `nvidia-smi` output.

The logging wrapper does not intentionally record `HF_TOKEN`, but still review logs before publishing them.

Do **not** include a real Hugging Face token in an issue.

## Uninstall

Delete:

```text
.local\
```

to remove the generated runtime/models/caches while keeping the repository.

Delete the whole repository directory to remove everything, including transcripts if they are inside it.

This does not uninstall the NVIDIA driver or independently installed global software.

## Distribution policy

This repository does **not** redistribute third-party binaries or model weights.

Required software and model artifacts are downloaded directly from their upstream sources during installation or first
use.

## License

Original code and documentation in this repository are licensed under the MIT License. See [LICENSE](LICENSE).

Third-party software and model weights remain subject to their own upstream licenses, terms, and access conditions.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Upstream projects

This setup builds on:

- WhisperX — https://github.com/m-bain/whisperX
- PyTorch — https://pytorch.org/
- pyannote.audio — https://github.com/pyannote/pyannote-audio
- Hugging Face — https://huggingface.co/
- faster-whisper — https://github.com/SYSTRAN/faster-whisper
- CTranslate2 — https://github.com/OpenNMT/CTranslate2
- FFmpeg — https://ffmpeg.org/
