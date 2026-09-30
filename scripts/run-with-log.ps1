param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Script
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $repoRoot ".local\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = Join-Path $logDir "$Name-$timestamp.log"
$pipLogPath = Join-Path $logDir "$Name-$timestamp-pip.log"

function Write-LogLine([string]$Text) {
    $Text | Tee-Object -FilePath $logPath -Append
}

Write-LogLine "========================================"
Write-LogLine "wi-whisperx $Name"
Write-LogLine "========================================"
Write-LogLine "Started:          $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
Write-LogLine "Repository root:  $repoRoot"
Write-LogLine "Working dir:      $(Get-Location)"
Write-LogLine "Script:           $Script"
Write-LogLine "Windows:          $([Environment]::OSVersion.VersionString)"
Write-LogLine "PowerShell:       $($PSVersionTable.PSVersion)"
Write-LogLine "ComSpec:          $env:ComSpec"

try {
    $nvidia = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if ($null -ne $nvidia) {
        Write-LogLine "nvidia-smi:       $($nvidia.Source)"
    } else {
        Write-LogLine "nvidia-smi:       NOT FOUND"
    }
} catch {
    Write-LogLine "nvidia-smi:       CHECK FAILED: $($_.Exception.Message)"
}

Write-LogLine "Run log:          $logPath"
Write-LogLine "pip log:          $pipLogPath"
Write-LogLine ""

if (-not (Test-Path -LiteralPath $Script -PathType Leaf)) {
    Write-LogLine "ERROR: target script does not exist:"
    Write-LogLine "  $Script"
    Write-LogLine ""
    Write-LogLine "Exit code: 1"
    exit 1
}

# IMPORTANT:
# Do not pipe native child output through Tee-Object.
# pip's live progress bar uses carriage-return updates and PowerShell's
# object pipeline destroys that terminal behavior.
#
# Instead:
#   1. run cmd.exe directly against the inherited console;
#   2. let pip write its own detailed diagnostic log through PIP_LOG;
#   3. keep this run log for invocation metadata and the final exit code.
#
# Do not dump the complete environment: it may contain HF_TOKEN or secrets.

$command = 'call "' + $Script + '"'
Write-LogLine "Command:          $env:ComSpec /d /s /c $command"
Write-LogLine ""

$hadPipLog = Test-Path Env:PIP_LOG
$previousPipLog = $env:PIP_LOG
$env:PIP_LOG = $pipLogPath

try {
    & $env:ComSpec /d /s /c $command
    $exitCode = $LASTEXITCODE
}
finally {
    if ($hadPipLog) {
        $env:PIP_LOG = $previousPipLog
    } else {
        Remove-Item Env:PIP_LOG -ErrorAction SilentlyContinue
    }
}

Write-LogLine ""
Write-LogLine "Finished:         $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
Write-LogLine "Exit code:        $exitCode"
Write-LogLine "Run log:          $logPath"

if (Test-Path -LiteralPath $pipLogPath -PathType Leaf) {
    Write-LogLine "pip log:          $pipLogPath"
} else {
    Write-LogLine "pip log:          not created (no pip operation logged)"
}

exit $exitCode
