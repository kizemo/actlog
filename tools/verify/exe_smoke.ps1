# --- actlog: release exe smoke test (real machine) --------------------------
#
# ASCII-only on purpose (this repo keeps tools/*.ps1 ASCII + UTF-8 no BOM).
#
# Verifies, against a real launch of the built release exe:
#   1. the process starts and stays alive
#   2. the window title is the app title (the UTF-8 Chinese product title, or
#      the ASCII product name; both are accepted so this script does not
#      depend on which spelling the build picked)
#   3. the tray native plugin (cnativeapi.dll) is loaded into the process,
#      i.e. the tray code path really executed
#   4. closing the window hides it instead of killing the app
#      (tray <-> window mutual exclusion: window close => hide to tray)
#
# The app is started without --selftest, so this also proves the default
# startup does NOT run any self-test logic.
#
# Usage:
#   pwsh -File tools/verify/exe_smoke.ps1
#   pwsh -File tools/verify/exe_smoke.ps1 -ExePath <path to actlog.exe>
#
# Exit code: 0 = all checks passed, 1 = at least one check failed.

[CmdletBinding()]
param(
    [string]$ExePath = '',
    [int]$StartupWaitSec = 12,
    [int]$PreCloseWaitSec = 8,
    [int]$CloseWaitSec = 6
)

$ErrorActionPreference = 'Stop'

# The data dir is not hard-coded here any more: it moved to <exe dir>\userdata
# and %APPDATA%\com.actlog\actlog is only a legacy fallback. All the
# resolution lives in data_location.ps1, dot-sourced from this script's folder.
. (Join-Path $PSScriptRoot 'data_location.ps1')

if ([string]::IsNullOrWhiteSpace($ExePath)) {
    $ExePath = Resolve-ActLogExePath
}
if (-not [System.IO.File]::Exists($ExePath)) {
    Write-Host "[FAIL] exe not found: $ExePath"
    exit 1
}

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class ActLogWin32 {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int GetWindowTextW(IntPtr hWnd, System.Text.StringBuilder text, int maxCount);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool IsWindowVisible(IntPtr hWnd);
}
'@

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

Write-Host "[INFO] exe: $ExePath"

# Capture the self-test report state BEFORE the launch: a normal start must
# not touch it (default startup runs no self-test at all).
$reportPath = Resolve-ActLogLogFile -FileName 'actlog_selftest.log' -ExePath $ExePath
$reportBefore = if (Test-Path $reportPath) { (Get-Item $reportPath).LastWriteTimeUtc } else { [datetime]::MinValue }
Write-Host "[INFO] selftest report timestamp before launch: $reportBefore"

$startupLog = Resolve-ActLogLogFile -FileName 'actlog_startup.log' -ExePath $ExePath
$startupLogBefore = if (Test-Path $startupLog) { (Get-Item $startupLog).Length } else { 0 }

$dataDir = Resolve-ActLogDataDir -ExePath $ExePath
Write-Host "[INFO] data dir: $($dataDir.Kind) -> $($dataDir.Path)"

$proc = Start-Process -FilePath $ExePath -PassThru

try {
    # --- 1. alive ------------------------------------------------------------
    $handle = [IntPtr]::Zero
    $deadline = (Get-Date).AddSeconds($StartupWaitSec)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        if ($proc.HasExited) { break }
        $proc.Refresh()
        if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
            $handle = $proc.MainWindowHandle
            break
        }
    }
    Assert-True (-not $proc.HasExited) "process started and is alive (pid=$($proc.Id))"
    if ($proc.HasExited) {
        Write-Host "[FAIL] process exited early with code $($proc.ExitCode)"
        exit 1
    }

    # --- 2. window title ----------------------------------------------------
    $title = ''
    if ($handle -ne [IntPtr]::Zero) {
        $sb = New-Object System.Text.StringBuilder 512
        [void][ActLogWin32]::GetWindowTextW($handle, $sb, 512)
        $title = $sb.ToString()
    }
    $codes = ($title.ToCharArray() | ForEach-Object { 'U+{0:X4}' -f [int]$_ }) -join ' '
    Write-Host "[INFO] window title code points: $codes"
    Assert-True (Test-ActLogTitle $title) "window title is the app title (Chinese product title or actlog)"

    # --- 3. tray native plugin loaded ---------------------------------------
    $modules = @()
    try {
        $modules = (Get-Process -Id $proc.Id).Modules | ForEach-Object { $_.ModuleName }
    } catch {
        Write-Host "[INFO] module list unavailable: $($_.Exception.Message)"
    }
    $trayLoaded = $modules -contains 'cnativeapi.dll'
    Assert-True $trayLoaded "tray native plugin cnativeapi.dll is loaded into the process"

    # --- 4. close => hide, not quit ------------------------------------------
    # Give the app time to finish its startup callback: the tray icon and the
    # "prevent close" flag are only installed after the first frame is
    # rendered. Closing earlier would quit the app by default and would look
    # like a broken tray.
    Start-Sleep -Seconds $PreCloseWaitSec
    $proc.Refresh()
    Assert-True (-not $proc.HasExited) "app is still alive after the startup settle time"
    $visibleBefore = [ActLogWin32]::IsWindowVisible($handle)
    [void][ActLogWin32]::PostMessage($handle, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)  # WM_CLOSE
    Start-Sleep -Seconds $CloseWaitSec
    $proc.Refresh()
    $stillAlive = -not $proc.HasExited
    $visibleAfter = if ($handle -ne [IntPtr]::Zero) { [ActLogWin32]::IsWindowVisible($handle) } else { $false }
    Write-Host "[INFO] visible before close=$visibleBefore, after close=$visibleAfter, alive=$stillAlive"
    Assert-True $stillAlive "app survives the window close (hidden to tray instead of quitting)"
    Assert-True (-not $visibleAfter) "window is hidden after close"

    # The app must not have run the self-test on a normal start.
    $reportAfter = if (Test-Path $reportPath) { (Get-Item $reportPath).LastWriteTimeUtc } else { [datetime]::MinValue }
    Assert-True ($reportAfter -eq $reportBefore) "normal start did not run the self-test (report file untouched)"

    # The startup log is the only visible trace of the startup chain in a GUI
    # app: it says whether the tray really came up and whether the
    # "prevent close" flag was really set. Only the part appended by THIS
    # launch counts - the log is cumulative across runs.
    # Same path as the pre-launch check above; resolving it twice could make the
    # before-offset and the after-tail point at different data dirs.
    $logText = ''
    if (Test-Path $startupLog) {
        $all = [System.IO.File]::ReadAllText($startupLog)
        if ($all.Length -ge $startupLogBefore) {
            $logText = $all.Substring($startupLogBefore)
        }
    }
    Write-Host "[INFO] startup log (this launch):`n$logText"
    Assert-True ($logText -match 'tray ready') "startup log says the tray icon was created"
    Assert-True ($logText -match 'hide on close armed') "startup log says the runner hides the window on close"
    Assert-True ($logText -match 'preventClose on') "startup log says prevent-close was enabled"
} finally {
    if (-not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
if ($failures.Count -eq 0) {
    Write-Host 'EXE_SMOKE: PASS (all checks passed)'
    exit 0
}
Write-Host "EXE_SMOKE: FAIL ($($failures.Count) failed)"
foreach ($f in $failures) { Write-Host "  - $f" }
exit 1
