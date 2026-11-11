# tools/gates/g4_contrast.ps1
# G4 - visual and accessibility gate: checks Flutter token contrast ratios.
# ASCII only. CRLF line endings. No BOM.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$desktop = Join-Path $root 'apps\desktop'

if (-not (Test-Path $desktop)) {
    Write-Error "desktop app not found: $desktop"
}

function Reset-TestCache {
    # `flutter test` on Windows hangs forever when build\test_cache\build already
    # holds a dill (test_compiler.dart: OS Error 183). Moving it aside keeps this
    # gate repeatable across back-to-back runs.
    $cacheBuild = Join-Path $desktop 'build\test_cache\build'
    if (Test-Path -LiteralPath $cacheBuild) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
        $aside = Join-Path $desktop ('build\test_cache_stale_g4_' + $stamp)
        Move-Item -LiteralPath $cacheBuild -Destination $aside
        Write-Host ('G4 CACHE_RESET_OK ' + $aside)
    }
}

Push-Location $desktop
try {
    Reset-TestCache
    & 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact `
        test\theme_tokens_test.dart
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'G4 FAILED: contrast gate'
    }
    Reset-TestCache
    & 'F:\soft\flutter\flutter\bin\flutter.bat' test --reporter compact `
        test\app_theme_test.dart
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'G4 FAILED: theme gate'
    }
}
finally {
    Pop-Location
}

Write-Host 'G4 PASSED'
