[CmdletBinding()]
param(
    [string]$Version = "latest",
    [string]$InstallDir = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$Repository = "balokir/wi-whisperx"

# Windows PowerShell 5.1 can otherwise negotiate an older TLS version.
[Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Join-Path (Get-Location).Path "wi-whisperx"
}

$InstallDir = [IO.Path]::GetFullPath($InstallDir)

if ($Version -eq "latest") {
    Write-Host "[RESOLVE] Latest wi-whisperx release..."

    $headers = @{
        "Accept"     = "application/vnd.github+json"
        "User-Agent" = "wi-whisperx-bootstrap"
    }

    $response = Invoke-WebRequest `
        -Uri "https://api.github.com/repos/$Repository/releases/latest" `
        -Headers $headers `
        -UseBasicParsing

    $release = $response.Content | ConvertFrom-Json
    $Tag = [string]$release.tag_name
} else {
    if ($Version.StartsWith("v")) {
        $Tag = $Version
    } else {
        $Tag = "v$Version"
    }
}

if ($Tag -notmatch '^v[0-9]+\.[0-9]+\.[0-9]+$') {
    throw "Unsupported release tag: $Tag"
}

$ZipName = "wi-whisperx-$Tag.zip"
$HashName = "$ZipName.sha256"
$ReleaseBase = "https://github.com/$Repository/releases/download/$Tag"

$WorkDir = Join-Path $env:TEMP ("wi-whisperx-bootstrap-" + [guid]::NewGuid().ToString("N"))
$ZipPath = Join-Path $WorkDir $ZipName
$HashPath = Join-Path $WorkDir $HashName
$ExtractDir = Join-Path $WorkDir "extract"

New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

try {
    Write-Host "[DOWNLOAD] $ZipName"
    Invoke-WebRequest `
        -Uri "$ReleaseBase/$ZipName" `
        -OutFile $ZipPath `
        -UseBasicParsing

    Write-Host "[DOWNLOAD] $HashName"
    Invoke-WebRequest `
        -Uri "$ReleaseBase/$HashName" `
        -OutFile $HashPath `
        -UseBasicParsing

    Write-Host "[CHECK] Release package SHA-256..."

    $hashText = (Get-Content -LiteralPath $HashPath -Raw).Trim()
    $expectedHash = ($hashText -split '\s+')[0].ToLowerInvariant()

    if ($expectedHash -notmatch '^[0-9a-f]{64}$') {
        throw "Invalid SHA-256 file for $ZipName"
    }

    $actualHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($actualHash -ne $expectedHash) {
        throw "Release package SHA-256 mismatch. Expected $expectedHash, got $actualHash"
    }

    Write-Host "[OK] Release package SHA-256 verified"

    if (Test-Path -LiteralPath $InstallDir) {
        $existing = @(Get-ChildItem -LiteralPath $InstallDir -Force)

        if ($existing.Count -gt 0) {
            throw "Install directory is not empty: $InstallDir"
        }

        Remove-Item -LiteralPath $InstallDir -Force
    }

    $parent = [IO.Directory]::GetParent($InstallDir)
    if ($null -eq $parent) {
        throw "Invalid install directory: $InstallDir"
    }

    New-Item -ItemType Directory -Path $parent.FullName -Force | Out-Null
    New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null

    Write-Host "[EXTRACT] $InstallDir"
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractDir -Force

    $SourceRoot = Join-Path $ExtractDir "wi-whisperx-$Tag"
    $InstallCmd = Join-Path $SourceRoot "install.cmd"

    if (-not (Test-Path -LiteralPath $InstallCmd -PathType Leaf)) {
        throw "Release package does not contain the expected install.cmd"
    }

    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

    Get-ChildItem -LiteralPath $SourceRoot -Force | ForEach-Object {
        Copy-Item `
            -LiteralPath $_.FullName `
            -Destination $InstallDir `
            -Recurse `
            -Force
    }

    Write-Host "[INSTALL] Running install.cmd..."

    Push-Location -LiteralPath $InstallDir
    try {
        & (Join-Path $InstallDir "install.cmd")
        $installExitCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }

    if ($installExitCode -ne 0) {
        throw "install.cmd failed with exit code $installExitCode. Installation files were kept at: $InstallDir"
    }

    Write-Host ""
    Write-Host "[OK] wi-whisperx $Tag installed successfully"
    Write-Host "     $InstallDir"
} finally {
    if (Test-Path -LiteralPath $WorkDir) {
        Remove-Item -LiteralPath $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
