<#
.SYNOPSIS
    ActLog environment bootstrap (idempotent, Windows-oriented).

.DESCRIPTION
    Prepares a developer machine for the ActLog workspace:
      1. locates the Flutter SDK (and the Dart SDK shipped inside it);
      2. exports the China pub mirrors into the CURRENT PROCESS only;
      3. runs `flutter doctor` (informational, never fails the script);
      4. runs `flutter pub get` for the workspace root;
         if the root workspace cannot be resolved, it falls back to
         resolving every package under packages/ one by one.

    Idempotency: running this script twice must not fail and must not
    damage the environment. `pub get` is idempotent, the mirror variables
    are process scoped, and nothing is deleted or rewritten here.

    ENCODING RULE (read before editing):
      This file is UTF-8 WITHOUT BOM and contains ASCII only.
      Windows PowerShell 5.1 decodes BOM-less files with the system ANSI
      code page, so a non-ASCII byte sequence may swallow the following
      newline and break parsing.  Chinese guidance text is therefore kept
      as base64 blobs and decoded at runtime (see Write-Zh).

.PARAMETER FlutterRoot
    Root directory that contains the Flutter SDK.  Both layouts work:
      <FlutterRoot>\flutter\bin\flutter.bat   (F:\soft\flutter)
      <FlutterRoot>\bin\flutter.bat            (F:\soft\flutter\flutter)

.PARAMETER SkipFlutterDoctor
    Skip the `flutter doctor` informational check (it is slow).

.PARAMETER SkipPubGet
    Skip dependency resolution entirely (for a pure environment check).

.EXAMPLE
    pwsh -File tools/bootstrap.ps1
    pwsh -File tools/bootstrap.ps1 -FlutterRoot F:\soft\flutter -SkipFlutterDoctor
#>
[CmdletBinding()]
param(
    [string]$FlutterRoot = 'F:\soft\flutter',
    [switch]$SkipFlutterDoctor,
    [switch]$SkipPubGet
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot

# Base64 of the Chinese "SDK not found" guidance (see .DESCRIPTION).
$ZH_MISSING_SDK = '5pyq5om+5YiwIEZsdXR0ZXIgU0RLIC8gRGFydCBTREvjgIIK6K+35oyJ5Lul5LiL5q2l6aqk5YeG5aSH546v5aKD77yaCjEuIOS4i+i9vSBGbHV0dGVyIDMuNDcuOe+8iERhcnQgMy4xMy4377yJ77yaaHR0cHM6Ly9kb2NzLmZsdXR0ZXIuZGV2L2dldC1zdGFydGVkL2luc3RhbGwvd2luZG93cwoyLiDop6PljovliLDkuIDkuKrlm7rlrprnm67lvZXvvIzkvovlpoIgRjpcc29mdFxmbHV0dGVyCjMuIOWbveWGhee9kee7nOW/hemhu+iuvue9rumVnOWDj+eOr+Wig+WPmOmHj++8iOWQpuWImSBwdWIg5p6B5oWi77yJ77yaCiAgIFBVQl9IT1NURURfVVJMPWh0dHBzOi8vcHViLmZsdXR0ZXItaW8uY24KICAgRkxVVFRFUl9TVE9SQUdFX0JBU0VfVVJMPWh0dHBzOi8vc3RvcmFnZS5mbHV0dGVyLWlvLmNuCjQuIOmHjeaWsOi/kOihjO+8mnB3c2ggLUZpbGUgdG9vbHMvYm9vdHN0cmFwLnBzMSAtRmx1dHRlclJvb3QgRjpcc29mdFxmbHV0dGVy'

# Base64 of the Chinese "root workspace cannot be resolved" warning.
$ZH_ROOT_RESOLVE = '6K2m5ZGK77ya5qC55bel5L2c5Yy66Kej5p6Q5aSx6LSl77yIZGFydCBwdWIgZ2V0IOaKpemUme+8ie+8jOW3suWbnumAgOS4uuOAjOmAkOWMheino+aekOOAjeOAggrlt7Lnn6Xljp/lm6DvvJrmoLkgcHVic3BlYy55YW1sIOaKiiBwYWNrYWdlcy9jb3JlX2RvbWFpbiDliJfkuLogd29ya3NwYWNlIOaIkOWRmO+8jArkvYbor6XmiJDlkZggcHVic3BlYy55YW1sIOe8uuWwkSByZXNvbHV0aW9uOiB3b3Jrc3BhY2Ug5LiA6KGM44CCCuS/ruWkjeaWueW8j++8muWcqCBwYWNrYWdlcy9jb3JlX2RvbWFpbi9wdWJzcGVjLnlhbWwg6aG26YOo5Yqg5YWlIHJlc29sdXRpb246IHdvcmtzcGFjZQrvvIjor6Xmlofku7bkuI3lnKjmnKzmrKHkuqTku5jojIPlm7TlhoXvvIzpnIDnlLHku5PlupPmiYDmnInogIXkv67mlLnvvInjgII='

function Write-Zh {
    param([string]$Base64)
    $text = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64))
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
    Write-Host $text
}

function Write-Err {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
}

function Invoke-Tool {
    # Runs a native tool, returns @{ Output = <string>; ExitCode = <int> }.
    # Native stderr is captured instead of thrown: under
    # $ErrorActionPreference = 'Stop' Windows PowerShell 5.1 would turn
    # any stderr line from a native command into a terminating error.
    param(
        [string]$Exe,
        [string[]]$ToolArgs,
        [string]$WorkingDirectory
    )
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    Push-Location $WorkingDirectory
    try {
        $output = & $Exe @ToolArgs 2>&1 | Out-String
        $code = $LASTEXITCODE
    }
    finally {
        Pop-Location
        $ErrorActionPreference = $prev
    }
    if ($null -eq $code) { $code = 0 }
    return @{ Output = $output; ExitCode = $code }
}

Write-Host '== ActLog bootstrap =='

# ---------------------------------------------------------------------------
# 1. Locate the Flutter SDK
# ---------------------------------------------------------------------------
$flutterExe = $null
$candidates = @(
    (Join-Path $FlutterRoot 'bin\flutter.bat'),
    (Join-Path $FlutterRoot 'flutter\bin\flutter.bat'),
    (Join-Path $FlutterRoot 'bin\flutter'),
    (Join-Path $FlutterRoot 'flutter\bin\flutter')
)
foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate) { $flutterExe = $candidate; break }
}
if (-not $flutterExe) {
    $onPath = Get-Command flutter -ErrorAction SilentlyContinue
    if ($onPath) { $flutterExe = $onPath.Source }
}

if (-not $flutterExe) {
    Write-Err '[bootstrap] FAILED: Flutter SDK not found.'
    Write-Err ("[bootstrap] Looked under: " + $FlutterRoot)
    Write-Zh $ZH_MISSING_SDK
    exit 2
}
Write-Host ("[bootstrap] flutter: " + $flutterExe)

$flutterDir = Split-Path -Parent (Split-Path -Parent $flutterExe)
$dartExe = Join-Path $flutterDir (Join-Path 'bin' (Join-Path 'cache' (Join-Path 'dart-sdk' (Join-Path 'bin' 'dart.exe'))))
if (-not (Test-Path -LiteralPath $dartExe)) {
    $onPath = Get-Command dart -ErrorAction SilentlyContinue
    if ($onPath) { $dartExe = $onPath.Source }
}
if (-not (Test-Path -LiteralPath $dartExe)) {
    Write-Err '[bootstrap] FAILED: Dart SDK not found next to the Flutter SDK.'
    Write-Err ("[bootstrap] Expected: " + $dartExe)
    Write-Zh $ZH_MISSING_SDK
    exit 2
}
Write-Host ("[bootstrap] dart: " + $dartExe)

# ---------------------------------------------------------------------------
# 2. China pub mirrors - current process only, nothing is persisted
# ---------------------------------------------------------------------------
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
Write-Host '[bootstrap] mirrors: PUB_HOSTED_URL / FLUTTER_STORAGE_BASE_URL -> China mirror (process scope only)'

# ---------------------------------------------------------------------------
# 3. Versions
# ---------------------------------------------------------------------------
$ver = Invoke-Tool -Exe $flutterExe -ToolArgs @('--version') -WorkingDirectory $RepoRoot
Write-Host ('[bootstrap] ' + ($ver.Output -replace "`r`n", ' '))

if (-not $SkipFlutterDoctor) {
    Write-Host '[bootstrap] running flutter doctor (informational only)'
    $doctor = Invoke-Tool -Exe $flutterExe -ToolArgs @('doctor', '-v') -WorkingDirectory $RepoRoot
    Write-Host $doctor.Output
    if ($doctor.ExitCode -ne 0) {
        Write-Host ('[bootstrap] NOTE: flutter doctor reported issues (exit ' + $doctor.ExitCode + '). This does NOT fail the bootstrap.')
    }
}
else {
    Write-Host '[bootstrap] flutter doctor skipped (-SkipFlutterDoctor)'
}

# ---------------------------------------------------------------------------
# 4. Dependency resolution
# ---------------------------------------------------------------------------
if ($SkipPubGet) {
    Write-Host '[bootstrap] pub get skipped (-SkipPubGet)'
    Write-Host '== bootstrap OK =='
    exit 0
}

Write-Host '[bootstrap] resolving workspace dependencies: flutter pub get'
$rootGet = Invoke-Tool -Exe $flutterExe -ToolArgs @('pub', 'get') -WorkingDirectory $RepoRoot
if ($rootGet.ExitCode -eq 0) {
    Write-Host $rootGet.Output
    Write-Host '== bootstrap OK =='
    exit 0
}

Write-Host $rootGet.Output
Write-Err ('[bootstrap] root `flutter pub get` failed with exit code ' + $rootGet.ExitCode)
Write-Zh $ZH_ROOT_RESOLVE

# Fallback: resolve every package under packages/ on its own.
$packagesRoot = Join-Path $RepoRoot 'packages'
$failed = @()
if (Test-Path -LiteralPath $packagesRoot) {
    $packageDirs = Get-ChildItem -LiteralPath $packagesRoot -Directory | Sort-Object Name
    foreach ($pkg in $packageDirs) {
        $pubspec = Join-Path $pkg.FullName 'pubspec.yaml'
        if (-not (Test-Path -LiteralPath $pubspec)) { continue }
        Write-Host ('[bootstrap] fallback: pub get in packages/' + $pkg.Name)
        $pkgGet = Invoke-Tool -Exe $dartExe -ToolArgs @('pub', 'get') -WorkingDirectory $pkg.FullName
        if ($pkgGet.ExitCode -ne 0) {
            $failed += $pkg.Name
            Write-Err ('[bootstrap]   FAILED ' + $pkg.Name + ':')
            Write-Err $pkgGet.Output
        }
        else {
            Write-Host ('[bootstrap]   OK ' + $pkg.Name)
        }
    }
}

if ($failed.Count -gt 0) {
    Write-Err ('[bootstrap] FAILED: could not resolve packages: ' + ($failed -join ', '))
    exit 3
}

Write-Host '== bootstrap OK (root workspace unresolved, packages resolved individually) =='
exit 0
