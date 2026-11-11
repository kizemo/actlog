<#
.SYNOPSIS
    G2 - unit test gate (blocking).

.DESCRIPTION
    WHAT THIS GATE CHECKS
      * every gated Dart package under packages/ resolves its dependencies
        (dart pub get must succeed), and
      * `dart test` passes completely for that package.  The gate prints the
        number of passed and failed test cases.
      * the root workspace context is tested as well when it resolves.  A
        root-level failure is reported as WARN and does not block by
        default (the root directory owns no test/ directory of its own);
        use -StrictRoot to make it blocking.

    HOW TO HANDLE A FAILURE
      The gate prints the failing test names and the tail of the test
      output to stderr.  Fix the failing test, then re-run:
          pwsh -File tools/gates/g2_unittest.ps1

    NOT COVERED YET
      The coverage threshold (>= 70%) from the development plan is not
      enforced here: it needs the `coverage` package, which is not
      installed on this machine.  It is tracked as a P0 follow-up.

    EXIT CODE
      0 = pass, 1 = fail.  CI depends on the exit code.

.NOTES
      This file is UTF-8 without BOM and ASCII only, so Windows
      PowerShell 5.1 (which decodes BOM-less files with the system ANSI
      code page) can never mis-decode it into a parse error.
#>
[CmdletBinding()]
param(
    # Optional comma separated SUBSET of packages under packages/.
    # Empty (the default) means auto-discover: every directory under
    # packages/ that ships a pubspec.yaml is gated. A hard-coded
    # whitelist used to silently skip newly added packages while the
    # gate still reported PASS - exactly the failure this gate exists
    # to prevent.
    [string]$Packages = '',
    # Explicit dart executable; auto-detected when empty.
    [string]$DartExe = '',
    # Flutter SDK root, used to locate the bundled Dart SDK.
    [string]$FlutterRoot = '',
    # Promote root-context failures into blocking failures.
    [switch]$StrictRoot,
    # Repository root override (defaults to the parent of tools/gates).
    [string]$RepoRoot = ''
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
if (-not $Packages) {
    $auto = @()
    $pkgRoot = Join-Path $RepoRoot 'packages'
    if (Test-Path -LiteralPath $pkgRoot) {
        foreach ($d in (Get-ChildItem -LiteralPath $pkgRoot -Directory)) {
            if (Test-Path -LiteralPath (Join-Path $d.FullName 'pubspec.yaml')) { $auto += $d.Name }
        }
    }
    $Packages = ($auto -join ',')
    Write-Host ('[g2] gated packages (auto-discovered): ' + $Packages)
}


function Write-Err {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
}

# --- China mirrors (process scope; caller values win) ---
# Measured on this machine: direct pub.dev / storage.googleapis.com runs at
# 28 KB/s, so `dart pub get` sits in "resolving dependencies" for a very long
# time. The gate then looks hung instead of failing, which is easy to
# misread as a broken script.
if (-not $env:PUB_HOSTED_URL) { $env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn' }
if (-not $env:FLUTTER_STORAGE_BASE_URL) { $env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn' }

function Resolve-Dart {
    param([string]$Explicit, [string]$FlutterRootHint)
    if ($Explicit) {
        if (Test-Path -LiteralPath $Explicit) { return $Explicit }
        throw "dart executable not found: $Explicit"
    }
    $onPath = Get-Command dart -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }

    $roots = @()
    if ($FlutterRootHint) { $roots += $FlutterRootHint }
    $roots += 'F:\soft\flutter'
    foreach ($root in $roots) {
        foreach ($relative in @(
                (Join-Path 'flutter' (Join-Path 'bin' (Join-Path 'cache' (Join-Path 'dart-sdk' (Join-Path 'bin' 'dart.exe'))))),
                (Join-Path 'bin' (Join-Path 'cache' (Join-Path 'dart-sdk' (Join-Path 'bin' 'dart.exe')))))) {
            $candidate = Join-Path $root $relative
            if (Test-Path -LiteralPath $candidate) { return $candidate }
        }
    }
    throw 'dart not found. Put dart on PATH, or pass -DartExe <path> / -FlutterRoot <path>.'
}

function Invoke-Tool {
    # Runs a native tool and returns @{ Output = <string>; ExitCode = <int> }.
    # Native stderr is captured, never thrown: under $ErrorActionPreference
    # = 'Stop' Windows PowerShell 5.1 turns native stderr into a
    # terminating error.
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

function Get-TestCounts {
    # Parses the `dart test` reporter output into
    # @{ Passed = <int>; Failed = <int> }.
    param([string]$Output)
    $passed = 0
    $failed = 0
    foreach ($line in ($Output -split "`r?`n")) {
        if ($line -match '^\s*\d\d:\d\d \+(\d+)') {
            $value = [int]$matches[1]
            if ($value -gt $passed) { $passed = $value }
        }
        if ($line -match '^\s*\d\d:\d\d \+(\d+) -(\d+)') {
            $value = [int]$matches[2]
            if ($value -gt $failed) { $failed = $value }
        }
    }
    return @{ Passed = $passed; Failed = $failed }
}

try {
    $dart = Resolve-Dart $DartExe $FlutterRoot
}
catch {
    Write-Err ('[g2] FAILED: ' + $_.Exception.Message)
    exit 1
}
Write-Host '== G2 unit tests =='
Write-Host ('[g2] dart: ' + $dart)

$failures = @()
$warnings = @()
$totalPassed = 0
$totalFailed = 0

# ---------------------------------------------------------------------------
# Step 1: try to resolve the workspace root (best effort)
# ---------------------------------------------------------------------------
Write-Host '[g2] resolving workspace root dependencies'
$rootGet = Invoke-Tool -Exe $dart -ToolArgs @('pub', 'get') -WorkingDirectory $RepoRoot
$rootResolved = ($rootGet.ExitCode -eq 0)
if ($rootResolved) { Write-Host '[g2] root workspace resolved' }
else { Write-Host ('[g2] root workspace NOT resolved (exit ' + $rootGet.ExitCode + ')') }

# ---------------------------------------------------------------------------
# Step 2: run the test suite of every gated package
# ---------------------------------------------------------------------------
foreach ($pkgName in ($Packages -split ',')) {
    $pkgName = $pkgName.Trim()
    if ($pkgName.Length -eq 0) { continue }
    $pkgDir = Join-Path (Join-Path $RepoRoot 'packages') $pkgName
    Write-Host ('[g2] package: packages/' + $pkgName)

    if (-not (Test-Path -LiteralPath (Join-Path $pkgDir 'pubspec.yaml'))) {
        Write-Err ('[g2] FAILED: packages/' + $pkgName + '/pubspec.yaml not found')
        $failures += ('packages/' + $pkgName + ': pubspec.yaml not found')
        continue
    }

    if (-not (Test-Path -LiteralPath (Join-Path $pkgDir 'test'))) {
        Write-Host ('[g2]   SKIP: packages/' + $pkgName + ' has no test/ directory')
        continue
    }

    $pkgConfig = Join-Path $pkgDir (Join-Path '.dart_tool' 'package_config.json')
    if (-not $rootResolved -or -not (Test-Path -LiteralPath $pkgConfig)) {
        $pkgGet = Invoke-Tool -Exe $dart -ToolArgs @('pub', 'get') -WorkingDirectory $pkgDir
        if ($pkgGet.ExitCode -ne 0) {
            Write-Err ('[g2] FAILED: dependency resolution failed for packages/' + $pkgName)
            Write-Err ($pkgGet.Output.Trim())
            $failures += ('packages/' + $pkgName + ': pub get failed')
            continue
        }
    }

    $run = Invoke-Tool -Exe $dart -ToolArgs @('test') -WorkingDirectory $pkgDir
    $counts = Get-TestCounts $run.Output
    $totalPassed += $counts.Passed
    $totalFailed += $counts.Failed
    Write-Host ('[g2]   passed=' + $counts.Passed + ' failed=' + $counts.Failed + ' exit=' + $run.ExitCode)

    if ($run.ExitCode -ne 0 -or $counts.Failed -gt 0) {
        Write-Err ('[g2] FAILED: packages/' + $pkgName + ' has failing tests')
        $outputLines = $run.Output -split "`r?`n"
        $interesting = @($outputLines | Where-Object { $_ -match '\[E\]|Expected:|Actual:|failed|Error:|error:' })
        if ($interesting.Count -eq 0) { $interesting = $outputLines }
        $shown = 0
        foreach ($line in $interesting) {
            if ($shown -ge 30) { break }
            if ($line.Trim().Length -gt 0) { Write-Err ('  ' + $line.Trim()); $shown++ }
        }
        $failures += ('packages/' + $pkgName + ': ' + $counts.Failed + ' failing test(s)')
    }
    else {
        Write-Host ('[g2]   OK: packages/' + $pkgName + ' all tests passed')
    }
}

# ---------------------------------------------------------------------------
# Step 3: root workspace context
# ---------------------------------------------------------------------------
if ($rootResolved -and (Test-Path -LiteralPath (Join-Path $RepoRoot 'test'))) {
    Write-Host '[g2] running root workspace tests'
    $rootRun = Invoke-Tool -Exe $dart -ToolArgs @('test') -WorkingDirectory $RepoRoot
    $rootCounts = Get-TestCounts $rootRun.Output
    $totalPassed += $rootCounts.Passed
    $totalFailed += $rootCounts.Failed
    Write-Host ('[g2]   root passed=' + $rootCounts.Passed + ' failed=' + $rootCounts.Failed)
    if ($rootRun.ExitCode -ne 0 -or $rootCounts.Failed -gt 0) {
        Write-Err '[g2] FAILED: root workspace tests failed'
        Write-Err ($rootRun.Output.Trim())
        $failures += 'root workspace: failing tests'
    }
}
elseif (-not $rootResolved) {
    Write-Err '[g2] WARN: root workspace could not be resolved, root-context tests skipped.'
    foreach ($line in (($rootGet.Output -split "`r?`n") | Where-Object { $_.Trim().Length -gt 0 })) {
        Write-Err ('        ' + $line.Trim())
    }
    if ($StrictRoot) { $failures += 'root workspace: pub get failed' }
    else { $warnings += 'root workspace: pub get failed (root-context tests skipped)' }
}

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
Write-Host ('[g2] totals: passed=' + $totalPassed + ' failed=' + $totalFailed)
foreach ($warning in $warnings) {
    Write-Err ('[g2] WARN: ' + $warning)
}

if ($failures.Count -gt 0) {
    Write-Err '[g2] RESULT: FAIL'
    foreach ($failure in $failures) {
        Write-Err ('[g2]   - ' + $failure)
    }
    Write-Err '[g2] fix the failing tests above, then re-run: pwsh -File tools/gates/g2_unittest.ps1'
    exit 1
}

Write-Host '[g2] RESULT: PASS'
exit 0
