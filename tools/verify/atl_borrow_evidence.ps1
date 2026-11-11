# --- actlog: ATL borrow evidence -------------------------------------------
#
# Verifies that the ATL borrow patch (apps/desktop/windows/cmake/atl_borrow.cmake)
# really took effect. Four checks, all evidence-based:
#
#   1. stamp      the configure step wrote actlog_atl_borrow.txt into the
#                 build dir, naming the borrowed ATL root / header / lib.
#                 (the legacy practilog_atl_borrow.txt is accepted as a
#                 fallback, so a build configured before the rename still
#                 produces evidence)
#   2. files      the borrowed header and library really exist on disk.
#   3. artifact   the built plugin DLL exists AND contains the borrowed root
#                 path as a string (injected by PLOG_ATL_BORROW_ROOT), i.e. the
#                 product itself records which ATL it was compiled against.
#   4. uniqueness this machine has exactly ONE atlbase.h - the borrowed one.
#                 System-wide, that is why compiling the plugin at all proves
#                 the borrow worked (there is no other header to fall back on).
#
# Optional -Teeth runs the reverse check: rebuild with PLOG_ATL_BORROW_OFF=1
# (borrow deliberately disabled) and require the build to FAIL with C1083.
# That is the "the gate has teeth" proof. It destroys the good build output,
# so rebuild afterwards.
#
# Usage:
#   pwsh -File tools/verify/atl_borrow_evidence.ps1
#   pwsh -File tools/verify/atl_borrow_evidence.ps1 -Teeth
#
# Exit code: 0 = all checks passed, 1 = at least one check failed.

[CmdletBinding()]
param(
    [string]$RepoRoot = '',
    [string]$BuildDir = '',
    [string]$ReleaseDir = '',
    [switch]$Teeth
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
if ([string]::IsNullOrWhiteSpace($BuildDir)) {
    $BuildDir = Join-Path (Join-Path (Join-Path $RepoRoot 'apps') 'desktop') 'build\windows\x64'
}
if ([string]::IsNullOrWhiteSpace($ReleaseDir)) {
    $ReleaseDir = Join-Path $BuildDir 'runner\Release'
}

$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) {
        Write-Host "[ OK ] $Message"
    } else {
        Write-Host "[FAIL] $Message"
        $failures.Add($Message)
    }
}

# --- 1. stamp ---------------------------------------------------------------
$stampPath = Join-Path $BuildDir 'actlog_atl_borrow.txt'
$legacyStampPath = Join-Path $BuildDir 'practilog_atl_borrow.txt'
if (-not (Test-Path $stampPath) -and (Test-Path $legacyStampPath)) {
    Write-Host "[INFO] legacy stamp file used: $legacyStampPath"
    $stampPath = $legacyStampPath
}
$borrowedRoot = ''
$borrowedHeader = ''
$borrowedLib = ''

if (Test-Path $stampPath) {
    Write-Host "[ OK ] stamp file exists: $stampPath"
    foreach ($line in Get-Content $stampPath) {
        if ($line -match '^borrowed_root=(.*)$') { $borrowedRoot = $Matches[1].Trim() }
        if ($line -match '^header=(.*)$') { $borrowedHeader = $Matches[1].Trim() }
        if ($line -match '^lib=(.*)$') { $borrowedLib = $Matches[1].Trim() }
    }
} else {
    Write-Host "[FAIL] stamp file missing: $stampPath (was the project configured?)"
    $failures.Add("stamp file missing: $stampPath")
}

Assert-True (-not [string]::IsNullOrWhiteSpace($borrowedRoot)) "stamp records a borrowed ATL root: '$borrowedRoot'"

# --- 2. borrowed files exist ----------------------------------------------
if (-not [string]::IsNullOrWhiteSpace($borrowedHeader)) {
    Assert-True (Test-Path $borrowedHeader) "borrowed header exists: $borrowedHeader"
}
if (-not [string]::IsNullOrWhiteSpace($borrowedLib)) {
    Assert-True (Test-Path $borrowedLib) "borrowed library exists: $borrowedLib"
}

# --- 3. the artifact carries the borrowed path ------------------------------
$dllPath = Join-Path $ReleaseDir 'flutter_local_notifications_windows.dll'
if (Test-Path $dllPath) {
    Write-Host "[ OK ] plugin DLL exists: $dllPath"
    $bytes = [System.IO.File]::ReadAllBytes($dllPath)
    $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
    if ([string]::IsNullOrWhiteSpace($borrowedRoot)) {
        Assert-True $false "cannot search the DLL: no borrowed root known"
    } else {
        Assert-True ($ascii.Contains($borrowedRoot)) "DLL embeds the borrowed ATL root string"
    }
} else {
    Write-Host "[FAIL] plugin DLL missing: $dllPath (run 'flutter build windows --release' first)"
    $failures.Add("plugin DLL missing: $dllPath")
}

# --- 4. the borrowed header is the only one on this machine ---------------
$atlHeaders = New-Object System.Collections.Generic.List[string]
foreach ($root in @(
        'C:\Program Files (x86)\Microsoft Visual Studio',
        'C:\Program Files\Microsoft Visual Studio')) {
    if (Test-Path $root) {
        Get-ChildItem -Path $root -Recurse -Filter 'atlbase.h' -ErrorAction SilentlyContinue |
            ForEach-Object { $atlHeaders.Add($_.FullName) }
    }
}
Write-Host "[INFO] atlbase.h found on this machine: $($atlHeaders.Count)"
foreach ($h in $atlHeaders) { Write-Host "[INFO]   $h" }
Assert-True ($atlHeaders.Count -eq 1) "exactly one atlbase.h on this machine (no silent fallback)"
if ($atlHeaders.Count -eq 1 -and -not [string]::IsNullOrWhiteSpace($borrowedHeader)) {
    $same = [System.IO.Path]::GetFullPath($atlHeaders[0]) -eq [System.IO.Path]::GetFullPath($borrowedHeader)
    Assert-True $same "the only atlbase.h is the borrowed one"
}

# --- optional: the reverse check (the gate must have teeth) ----------------
if ($Teeth) {
    Write-Host "[INFO] running the reverse check: rebuild with the borrow disabled"
    $flutter = 'F:\soft\flutter\flutter\bin\flutter.bat'
    if (-not (Test-Path $flutter)) {
        $flutter = (Get-Command flutter.bat -ErrorAction SilentlyContinue).Source
    }
    if ([string]::IsNullOrWhiteSpace($flutter) -or -not (Test-Path $flutter)) {
        Assert-True $false "flutter not found, cannot run the reverse check"
    } else {
        # The reverse build is a full flutter build: it needs the CN mirrors,
        # otherwise pub get is painfully slow (or hangs on pub.dev).
        $env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
        $env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
        $env:PLOG_ATL_BORROW_OFF = '1'
        $log = Join-Path $env:TEMP 'actlog_atl_teeth.log'
        $err = Join-Path $env:TEMP 'actlog_atl_teeth.err.log'
        $desktop = Join-Path (Join-Path $RepoRoot 'apps') 'desktop'
        $code = -1
        try {
            # Use Start-Process with redirection: calling a .bat through "&" with
            # a pipeline loses the exit code and the output (it comes back as an
            # array / empty), which silently disables the whole reverse check.
            $proc = Start-Process -FilePath $flutter `
                -ArgumentList 'build', 'windows', '--release' `
                -WorkingDirectory $desktop `
                -RedirectStandardOutput $log -RedirectStandardError $err `
                -NoNewWindow -PassThru -Wait
            $code = $proc.ExitCode
        } catch {
            Write-Host "[INFO] reverse check could not start: $($_.Exception.Message)"
            $code = -1
        } finally {
            $env:PLOG_ATL_BORROW_OFF = $null
        }
        $text = ''
        if (Test-Path $log) { $text = [System.IO.File]::ReadAllText($log) }
        if (Test-Path $err) { $text += [System.IO.File]::ReadAllText($err) }
        Assert-True ($code -ne 0) "build fails when the borrow is disabled (exit $code)"
        # Which ATL error shows up depends on the incremental build state:
        #   C1083   the plugin does not compile at all (atlbase.h not found)
        #   LNK1104 the plugin object was still cached from an earlier good
        #           build, so only the link step runs and cannot find atls.lib
        # Both mean the same thing: without the borrow there is no usable ATL.
        $atlMissing = ($text -match 'C1083') -or ($text -match 'LNK1104')
        Assert-True ([bool]$atlMissing) "the failure is an ATL-missing error (C1083 atlbase.h / LNK1104 atls.lib)"
    }
}

Write-Host ''
if ($failures.Count -eq 0) {
    Write-Host 'ATL_BORROW_EVIDENCE: PASS (all checks passed)'
    exit 0
}
Write-Host "ATL_BORROW_EVIDENCE: FAIL ($($failures.Count) failed)"
foreach ($f in $failures) { Write-Host "  - $f" }
exit 1
