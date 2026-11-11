<#
.SYNOPSIS
    G1 - static analysis gate (blocking).

.DESCRIPTION
    WHAT THIS GATE CHECKS
      * every gated Dart package under packages/ resolves its dependencies
        (dart pub get must succeed), and
      * `dart analyze` reports ZERO issues for that package - error, warning
        and info alike.  analysis_options.yaml promotes unused_import /
        unused_local_variable / unused_field / dead_code to error, so a
        non-zero analyze exit code always means real breakage.
      * the root workspace context is analyzed as well.  Root-context
        diagnostics (analysis_options.yaml warnings, pubspec lint hints)
        are reported as WARN and do not block by default, because the root
        directory owns no Dart source of its own and those warnings are
        configuration defects owned by the repository root.  Use
        -StrictRoot to make them blocking.

    HOW TO HANDLE A FAILURE
      The gate prints the offending "severity code file:line:col message"
      lines to stderr.  Fix every reported line, then re-run:
          pwsh -File tools/gates/g1_analyze.ps1
      If the failure says "dependency resolution failed", run the
      bootstrap script first (tools/bootstrap.ps1) - it also prints the
      exact pub error.

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
    # Promote root-context warnings into blocking failures.
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
    Write-Host ('[g1] gated packages (auto-discovered): ' + $Packages)
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

function Get-AnalyzeIssues {
    # Runs `dart analyze --format machine` and returns
    # @{ ExitCode = <int>; Issues = <object[]>; Raw = <string> }.
    param([string]$Exe, [string]$WorkingDirectory)
    $run = Invoke-Tool -Exe $Exe -ToolArgs @('analyze', '--format', 'machine') -WorkingDirectory $WorkingDirectory
    $issues = @()
    foreach ($line in ($run.Output -split "`r?`n")) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0) { continue }
        if ($trimmed -notmatch '\|') { continue }
        $fields = $trimmed -split '\|'
        if ($fields.Count -lt 4) { continue }
        $severity = $fields[0].Trim()
        if ($severity -notmatch '^(ERROR|WARNING|INFO)$') { continue }
        $code = $fields[2].Trim()
        $file = $fields[3].Trim()
        $lineNo = $fields[4].Trim()
        $message = ''
        if ($fields.Count -ge 8) { $message = ($fields[7..($fields.Count - 1)] -join '|').Trim() }
        $issues += [PSCustomObject]@{
            Severity = $severity
            Code     = $code
            File     = $file
            Line     = $lineNo
            Message  = $message
        }
    }
    return @{ ExitCode = $run.ExitCode; Issues = $issues; Raw = $run.Output }
}

function Format-Issue {
    param($Issue)
    return ('  ' + $Issue.Severity + ' ' + $Issue.Code + ' ' + $Issue.File + ':' + $Issue.Line + ' - ' + $Issue.Message)
}

function Write-IssueBlock {
    param($Issues, [string]$Title, [int]$Max = 40)
    if ($Issues.Count -eq 0) { return }
    Write-Err $Title
    $shown = 0
    foreach ($issue in $Issues) {
        if ($shown -ge $Max) {
            Write-Err ('  ... ' + ($Issues.Count - $shown) + ' more issue(s) suppressed')
            break
        }
        Write-Err (Format-Issue $issue)
        $shown++
    }
}

try {
    $dart = Resolve-Dart $DartExe $FlutterRoot
}
catch {
    Write-Err ('[g1] FAILED: ' + $_.Exception.Message)
    exit 1
}
Write-Host ('== G1 static analysis ==')
Write-Host ('[g1] dart: ' + $dart)

$failures = @()
$warnings = @()

# ---------------------------------------------------------------------------
# Step 1: try to resolve the workspace root (best effort)
# ---------------------------------------------------------------------------
Write-Host '[g1] resolving workspace root dependencies'
$rootGet = Invoke-Tool -Exe $dart -ToolArgs @('pub', 'get') -WorkingDirectory $RepoRoot
$rootResolved = ($rootGet.ExitCode -eq 0)
if ($rootResolved) {
    Write-Host '[g1] root workspace resolved'
}
else {
    Write-Host ('[g1] root workspace NOT resolved (exit ' + $rootGet.ExitCode + ')')
}

# ---------------------------------------------------------------------------
# Step 2: analyze every gated package - zero issues required
# ---------------------------------------------------------------------------
foreach ($pkgName in ($Packages -split ',')) {
    $pkgName = $pkgName.Trim()
    if ($pkgName.Length -eq 0) { continue }
    $pkgDir = Join-Path (Join-Path $RepoRoot 'packages') $pkgName
    Write-Host ('[g1] package: packages/' + $pkgName)

    if (-not (Test-Path -LiteralPath (Join-Path $pkgDir 'pubspec.yaml'))) {
        Write-Err ('[g1] FAILED: packages/' + $pkgName + '/pubspec.yaml not found')
        $failures += ('packages/' + $pkgName + ': pubspec.yaml not found')
        continue
    }

    $pkgConfig = Join-Path $pkgDir (Join-Path '.dart_tool' 'package_config.json')
    if (-not $rootResolved -or -not (Test-Path -LiteralPath $pkgConfig)) {
        $pkgGet = Invoke-Tool -Exe $dart -ToolArgs @('pub', 'get') -WorkingDirectory $pkgDir
        if ($pkgGet.ExitCode -ne 0) {
            Write-Err ('[g1] FAILED: dependency resolution failed for packages/' + $pkgName)
            Write-Err ($pkgGet.Output.Trim())
            $failures += ('packages/' + $pkgName + ': pub get failed')
            continue
        }
    }

    $result = Get-AnalyzeIssues -Exe $dart -WorkingDirectory $pkgDir
    $errors = @($result.Issues | Where-Object { $_.Severity -eq 'ERROR' })
    $warns = @($result.Issues | Where-Object { $_.Severity -eq 'WARNING' })
    $infos = @($result.Issues | Where-Object { $_.Severity -eq 'INFO' })

    Write-Host ('[g1]   error=' + $errors.Count + ' warning=' + $warns.Count + ' info=' + $infos.Count)

    if ($result.Issues.Count -gt 0) {
        Write-IssueBlock -Issues $result.Issues -Title ('[g1] FAILED: packages/' + $pkgName + ' has ' + $result.Issues.Count + ' issue(s)')
        $failures += ('packages/' + $pkgName + ': ' + $result.Issues.Count + ' analyze issue(s)')
    }
    else {
        Write-Host ('[g1]   OK: packages/' + $pkgName + ' has zero issues')
    }
}

# ---------------------------------------------------------------------------
# Step 3: analyze the root workspace context
# ---------------------------------------------------------------------------
if ($rootResolved) {
    Write-Host '[g1] analyzing root workspace context'
    $rootResult = Get-AnalyzeIssues -Exe $dart -WorkingDirectory $RepoRoot
    $rootErrors = @($rootResult.Issues | Where-Object { $_.Severity -eq 'ERROR' })
    $rootOthers = @($rootResult.Issues | Where-Object { $_.Severity -ne 'ERROR' })
    Write-Host ('[g1]   root error=' + $rootErrors.Count + ' warning/info=' + $rootOthers.Count)

    if ($rootErrors.Count -gt 0) {
        Write-IssueBlock -Issues $rootErrors -Title '[g1] FAILED: root workspace has analyze errors'
        $failures += ('root workspace: ' + $rootErrors.Count + ' analyze error(s)')
    }
    elseif ($rootOthers.Count -gt 0) {
        Write-IssueBlock -Issues $rootOthers -Title ('[g1] WARN: root workspace has ' + $rootOthers.Count + ' warning/info issue(s)')
        if ($StrictRoot) {
            $failures += ('root workspace: ' + $rootOthers.Count + ' warning/info issue(s) (-StrictRoot)')
        }
        else {
            $warnings += ('root workspace: ' + $rootOthers.Count + ' warning/info issue(s)')
        }
    }
    else {
        Write-Host '[g1]   OK: root workspace has zero issues'
    }
}
else {
    Write-Err '[g1] WARN: root workspace could not be resolved, root-context analysis skipped.'
    Write-Err '[g1] WARN: the exact pub error was:'
    foreach ($line in (($rootGet.Output -split "`r?`n") | Where-Object { $_.Trim().Length -gt 0 })) {
        Write-Err ('        ' + $line.Trim())
    }
    if ($StrictRoot) {
        $failures += 'root workspace: pub get failed'
    }
    else {
        $warnings += 'root workspace: pub get failed (root-context analysis skipped)'
    }
}

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
foreach ($warning in $warnings) {
    Write-Err ('[g1] WARN: ' + $warning)
}

if ($failures.Count -gt 0) {
    Write-Err '[g1] RESULT: FAIL'
    foreach ($failure in $failures) {
        Write-Err ('[g1]   - ' + $failure)
    }
    Write-Err '[g1] fix the lines above, then re-run: pwsh -File tools/gates/g1_analyze.ps1'
    exit 1
}

Write-Host '[g1] RESULT: PASS'
exit 0
