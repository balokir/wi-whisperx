param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command,

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$CommandArgs
)

$ErrorActionPreference = "Stop"

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$rc = 1

try {
    # Resolve explicit/relative paths first, while still allowing commands from PATH.
    if (Test-Path -LiteralPath $Command -PathType Leaf) {
        $resolvedCommand = (Resolve-Path -LiteralPath $Command).Path
    } else {
        $resolvedCommand = $Command
    }

    & $resolvedCommand @CommandArgs
    $rc = $LASTEXITCODE

    # PowerShell-native commands may not set LASTEXITCODE.
    if ($null -eq $rc) {
        $rc = 0
    }
}
catch {
    Write-Error $_
    $rc = 1
}
finally {
    $sw.Stop()

    Write-Host
    Write-Host "========================================"
    Write-Host ("Elapsed:   {0}" -f $sw.Elapsed.ToString("hh\:mm\:ss\.fff"))
    Write-Host ("Exit code: {0}" -f $rc)
    Write-Host "========================================"
}

exit $rc
