# tools/gates/g4_contrast.ps1
# G4 - visual and accessibility gate: checks Flutter token contrast ratios.
#
# Task 41 expansion: this gate used to run 2 files (zero dark coverage). It now
# runs the 5 files named by the Task 41 design doc section 7.3.
#
#   theme_tokens_test.dart
#   timeline_contrast_test.dart   (new here; it is the four-state contrast gate)
#   app_theme_test.dart
#   theme_tokens_dark_test.dart   (new)
#   dark_color_scheme_test.dart   (new)
#
# `dark_theme_widget_test.dart` is deliberately NOT in this list: it is a
# rendering test, not a contrast gate. It still has to run in the full
# `flutter test` suite (G2 in reports/task41-gate.ps1).
#
# Behaviour: every listed file runs, a missing file is reported by name instead
# of aborting the run, and a failing file gets its `[E]` case lines printed one
# by one. Exit code is 0 only when all 5 files exist and all 5 pass.
#
# ASCII only. CRLF line endings. No BOM.
$ErrorActionPreference = 'Continue'

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$desktop = Join-Path $root 'apps\desktop'
$logDir = Join-Path $root 'reports\task41-g4'
$flutter = 'F:\soft\flutter\flutter\bin\flutter.bat'

# Mirror MUST be set in-process. Without it, `flutter test` triggers `pub get`
# and rewrites every `url:` in apps\desktop\pubspec.lock from
# https://pub.flutter-io.cn to https://pub.dev. pubspec.lock is a frozen file
# (forbidden check FROZEN_DIFFS): one G4 run would dirty the repository.
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'

if (-not (Test-Path -LiteralPath $desktop)) {
    [Console]::Out.WriteLine('G4_FATAL=DESKTOP_APP_NOT_FOUND')
    [Console]::Out.WriteLine('G4_VERDICT=FAIL')
    exit 1
}

New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$tracePath = Join-Path $logDir 'g4-trace.txt'
[System.IO.File]::WriteAllText($tracePath, '')
function Out-Line([string]$s) {
    [Console]::Out.WriteLine($s)
    [System.IO.File]::AppendAllText($tracePath, $s + "`r`n")
}

# Ordered as specified by the Task 41 design doc section 7.3.
$tests = @(
    'theme_tokens_test.dart',
    'timeline_contrast_test.dart',
    'app_theme_test.dart',
    'theme_tokens_dark_test.dart',
    'dark_color_scheme_test.dart'
)

function Reset-TestCache {
    # `flutter test` on Windows hangs forever when build\test_cache\build already
    # holds a dill (test_compiler.dart: OS Error 183). Moving it aside keeps this
    # gate repeatable across back-to-back runs.
    $cacheBuild = Join-Path $desktop 'build\test_cache\build'
    if (Test-Path -LiteralPath $cacheBuild) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
        $aside = Join-Path $desktop ('build\test_cache_stale_g4_' + $stamp)
        try {
            Move-Item -LiteralPath $cacheBuild -Destination $aside
            Out-Line ('G4 CACHE_RESET_OK ' + $aside)
        } catch {
            Out-Line ('G4 CACHE_RESET_FAIL ' + $_.Exception.Message)
        }
    }
}

$missing = 0
$failed = 0
$ran = 0

Push-Location $desktop
try {
    foreach ($t in $tests) {
        $rel = Join-Path 'test' $t
        $abs = Join-Path $desktop $rel
        if (-not (Test-Path -LiteralPath $abs)) {
            Out-Line ('G4_FILE_MISSING=' + $t)
            $missing++
            continue
        }
        Reset-TestCache
        $logName = ($t -replace '\.dart$', '') + '.txt'
        $out = Join-Path $logDir $logName
        Out-Line ('G4_RUN=' + $t)
        & $flutter test --reporter compact $rel *> $out
        $rc = $LASTEXITCODE
        $ran++
        if ($rc -ne 0) {
            $failed++
            Out-Line ('G4_FAIL=' + $t + '|EXIT=' + $rc)
            $txt = ''
            if (Test-Path -LiteralPath $out) {
                $txt = [System.IO.File]::ReadAllText($out)
            }
            $errLines = @($txt -split "`n" | Where-Object { $_ -match '\[E\]' } | Select-Object -First 20)
            foreach ($line in $errLines) {
                Out-Line ('G4_ERR=' + $t + '|' + $line.Trim())
            }
            if ($errLines.Count -eq 0) {
                Out-Line ('G4_ERR=' + $t + '|NO_CASE_LINE_CAPTURED')
            }
        } else {
            Out-Line ('G4_OK=' + $t)
        }
    }
} finally {
    Pop-Location
}

Out-Line ('G4_FILES=' + $tests.Count)
Out-Line ('G4_RAN=' + $ran)
Out-Line ('G4_MISSING=' + $missing)
Out-Line ('G4_FAILED=' + $failed)
if (($missing -eq 0) -and ($failed -eq 0)) {
    Out-Line 'G4_VERDICT=PASS'
    exit 0
}
Out-Line 'G4_VERDICT=FAIL'
exit 1