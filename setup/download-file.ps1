param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Url,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutFile,

    [Parameter(Mandatory = $true)]
    [ValidateSet("SHA256", "SHA512")]
    [string]$HashAlgorithm,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Hex", "Base64")]
    [string]$HashEncoding,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedHash
)

$ErrorActionPreference = "Stop"

function Get-EncodedHash([string]$Path) {
    $stream = [System.IO.File]::OpenRead($Path)

    try {
        switch ($HashAlgorithm) {
            "SHA256" { $hasher = [System.Security.Cryptography.SHA256]::Create() }
            "SHA512" { $hasher = [System.Security.Cryptography.SHA512]::Create() }
            default  { throw "Unsupported hash algorithm: $HashAlgorithm" }
        }

        try {
            [byte[]]$bytes = $hasher.ComputeHash($stream)
        }
        finally {
            $hasher.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }

    switch ($HashEncoding) {
        "Hex" {
            return ([BitConverter]::ToString($bytes)).Replace("-", "").ToLowerInvariant()
        }
        "Base64" {
            return [Convert]::ToBase64String($bytes)
        }
        default {
            throw "Unsupported hash encoding: $HashEncoding"
        }
    }
}

function Test-ExpectedHash([string]$Path) {
    $actual = Get-EncodedHash $Path

    if ($HashEncoding -eq "Hex") {
        $matches = $actual.Equals($ExpectedHash, [StringComparison]::OrdinalIgnoreCase)
    } else {
        $matches = $actual.Equals($ExpectedHash, [StringComparison]::Ordinal)
    }

    return @{
        Matches = $matches
        Actual  = $actual
    }
}

try {
    $parent = Split-Path -Parent $OutFile
    if ([string]::IsNullOrWhiteSpace($parent)) {
        throw "Output file has no parent directory: $OutFile"
    }

    New-Item -ItemType Directory -Path $parent -Force | Out-Null

    Write-Output "[ARTIFACT] URL:  $Url"
    Write-Output "[ARTIFACT] FILE: $OutFile"
    Write-Output "[ARTIFACT] HASH: $HashAlgorithm/$HashEncoding"

    # A cached file is trusted only after verifying its pinned hash.
    if (Test-Path -LiteralPath $OutFile -PathType Leaf) {
        Write-Output "[CHECK] Cached artifact hash..."

        $cached = Test-ExpectedHash $OutFile
        if ($cached.Matches) {
            $item = Get-Item -LiteralPath $OutFile
            Write-Output "[OK] Cached artifact hash verified: $($item.Length) bytes"
            exit 0
        }

        Write-Output "[INVALID] Cached artifact hash mismatch"
        Write-Output "          expected: $ExpectedHash"
        Write-Output "          actual:   $($cached.Actual)"
        Write-Output "          deleting: $OutFile"
        Remove-Item -LiteralPath $OutFile -Force
    }

    $tmp = "$OutFile.part"
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue

    Write-Output "[DOWNLOAD] Downloading artifact..."

    [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    Invoke-WebRequest `
        -UseBasicParsing `
        -Uri $Url `
        -OutFile $tmp

    if (-not (Test-Path -LiteralPath $tmp -PathType Leaf)) {
        throw "Invoke-WebRequest completed but temporary file does not exist: $tmp"
    }

    $item = Get-Item -LiteralPath $tmp
    if ($item.Length -le 0) {
        throw "Downloaded file is empty: $tmp"
    }

    Write-Output "[CHECK] Downloaded artifact hash..."
    $downloaded = Test-ExpectedHash $tmp

    if (-not $downloaded.Matches) {
        Write-Output "[ERROR] Downloaded artifact hash mismatch"
        Write-Output "        expected: $ExpectedHash"
        Write-Output "        actual:   $($downloaded.Actual)"
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        exit 1
    }

    Move-Item -LiteralPath $tmp -Destination $OutFile -Force

    $final = Get-Item -LiteralPath $OutFile
    Write-Output "[OK] Downloaded artifact hash verified: $($final.Length) bytes"
    exit 0
}
catch {
    Write-Output "[DOWNLOAD] FAILED"
    Write-Output "[DOWNLOAD] Type: $($_.Exception.GetType().FullName)"
    Write-Output "[DOWNLOAD] Message: $($_.Exception.Message)"
    if ($_.Exception.InnerException) {
        Write-Output "[DOWNLOAD] Inner: $($_.Exception.InnerException.Message)"
    }

    Remove-Item -LiteralPath "$OutFile.part" -Force -ErrorAction SilentlyContinue
    exit 1
}
