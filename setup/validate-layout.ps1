$ErrorActionPreference = "Stop"

function Full([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Path value is empty."
    }
    return [IO.Path]::GetFullPath($Path).TrimEnd('\')
}

function Assert-EqualPath([string]$Name, [string]$Actual, [string]$Expected) {
    if ([string]::IsNullOrWhiteSpace($Actual)) {
        throw "$Name is empty."
    }

    if ((Full $Actual) -ine (Full $Expected)) {
        throw "$Name path mismatch. Actual='$Actual' Expected='$Expected'"
    }
}

$actualSetupDir = Full $PSScriptRoot
$actualRoot = Full (Split-Path -Parent $actualSetupDir)

Assert-EqualPath "ROOT"          $env:ROOT          $actualRoot
Assert-EqualPath "SETUP_DIR"     $env:SETUP_DIR     $actualSetupDir
Assert-EqualPath "SCRIPTS_DIR"   $env:SCRIPTS_DIR   (Join-Path $actualRoot "scripts")

Assert-EqualPath "LOCAL"         $env:LOCAL         (Join-Path $actualRoot ".local")
Assert-EqualPath "RUNTIME"       $env:RUNTIME       (Join-Path $actualRoot ".local\runtime")
Assert-EqualPath "PYTHON_HOME"   $env:PYTHON_HOME   (Join-Path $actualRoot ".local\runtime\python")
Assert-EqualPath "FFMPEG_HOME"   $env:FFMPEG_HOME   (Join-Path $actualRoot ".local\runtime\ffmpeg")
Assert-EqualPath "VENV"          $env:VENV          (Join-Path $actualRoot ".local\runtime\venv")
Assert-EqualPath "CACHE"         $env:CACHE         (Join-Path $actualRoot ".local\cache")
Assert-EqualPath "DOWNLOADS"     $env:DOWNLOADS     (Join-Path $actualRoot ".local\downloads")
Assert-EqualPath "MODELS"        $env:MODELS        (Join-Path $actualRoot ".local\models")
Assert-EqualPath "LOGS"          $env:LOGS          (Join-Path $actualRoot ".local\logs")

Assert-EqualPath "TRANSCRIPT"    $env:TRANSCRIPT    (Join-Path $actualRoot "transcript")
Assert-EqualPath "HF_TOKEN_FILE" $env:HF_TOKEN_FILE (Join-Path $actualRoot "hf-token.cmd")

$required = @(
    "install.cmd",
    "repair.cmd",
    "verify.cmd",
    "measure.cmd",
    "transcribe.bat",
    "transcribe-diarize.bat",
    "transcribe-diarize-speakers.bat",

    "scripts\env.cmd",
    "scripts\whisperx.cmd",
    "scripts\require-hf-token.cmd",
    "scripts\transcribe-common.cmd",
    "scripts\run-with-log.ps1",
    "scripts\measure.ps1",

    "setup\config.cmd",
    "setup\00-validate-layout.cmd",
    "setup\ensure-all.cmd",
    "setup\ensure-hf-token-example.cmd",
    "setup\install-main.cmd",
    "setup\repair-main.cmd",
    "setup\01-ensure-python.cmd",
    "setup\02-ensure-ffmpeg.cmd",
    "setup\03-ensure-venv.cmd",
    "setup\04-ensure-runtime.cmd",
    "setup\runtime-layout.cmd",
    "setup\05-ensure-pytorch.cmd",
    "setup\06-ensure-whisperx.cmd",
    "setup\07-ensure-pyannote-patch.cmd",
    "setup\08-ensure-runtime-smoke.cmd",
    "setup\09-ensure-checkpoint.cmd",
    "setup\10-verify.cmd",
    "setup\rebuild-venv.cmd",
    "setup\download-file.ps1",
    "setup\sitecustomize.py",
    "setup\functional_smoke.py",
    "setup\check_checkpoint.py",
    "setup\upgrade_checkpoint.py",
    "setup\patch_pyannote_pooling.py"
)

foreach ($relative in $required) {
    $path = Join-Path $actualRoot $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required repository file is missing: $path"
    }
}

Write-Output "[OK] repository path contract"
exit 0
