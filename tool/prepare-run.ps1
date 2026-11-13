# Pre-run preparation for Windows debug builds.
#
# Why this exists:
#  1) movies.exe may stay alive after its window closes (WebView2 / audio_service /
#     media_kit background threads). It keeps runner\Debug\WebView2Loader.dll
#     loaded, so the next MSBuild cannot overwrite it (MSB3027 / MSB3021).
#  2) A low-integrity terminal cannot write to the system %TEMP%, which makes
#     DevFS fail with PathAccessException. The workspace .tmp is used instead
#     (launch.json points TEMP/TMP there).
#
# ASCII only on purpose: Windows PowerShell 5.1 reads .ps1 as ANSI, so non-ASCII
# text without a BOM gets mangled and can break parsing.
#
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File tool\prepare-run.ps1

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot

# 1. Stop a lingering app instance.
$procs = @(Get-Process -Name movies -ErrorAction SilentlyContinue)
if ($procs.Count -gt 0) {
    $ids = ($procs | ForEach-Object { $_.Id }) -join ', '
    $procs | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 600
    $left = @(Get-Process -Name movies -ErrorAction SilentlyContinue)
    if ($left.Count -gt 0) {
        $leftIds = ($left | ForEach-Object { $_.Id }) -join ', '
        [Console]::Error.WriteLine("prepare-run: cannot stop movies.exe (PID $leftIds); close it manually and rebuild.")
        exit 1
    }
    Write-Host "prepare-run: stopped lingering movies.exe (PID $ids)"
} else {
    Write-Host "prepare-run: no lingering movies.exe"
}

# 2. Make sure the DevFS temp directory exists.
$tmp = Join-Path $root '.tmp'
if (-not (Test-Path $tmp)) {
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    Write-Host "prepare-run: created $tmp"
} else {
    Write-Host "prepare-run: .tmp already exists"
}

# 3. Verify it is really writable (fails loudly under low integrity).
$probe = Join-Path $tmp ('.probe-' + [guid]::NewGuid().ToString('N').Substring(0, 6))
try {
    New-Item -ItemType Directory -Path $probe -ErrorAction Stop | Out-Null
    Remove-Item $probe -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    [Console]::Error.WriteLine("prepare-run: .tmp is not writable: $($_.Exception.Message)")
    exit 1
}

exit 0
