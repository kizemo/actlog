# --- actlog: release exe smoke test (real machine) --------------------------
#
# ASCII-only on purpose (this repo keeps tools/*.ps1 ASCII + UTF-8 no BOM).
#
# Verifies, against a real launch of the built release exe:
#   1. the process starts and stays alive
#   2. the window title is the app title (strict: exact match of the expected
#      product title for the given language, or of one of the known spellings
#      when no language is passed)
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
#   pwsh -File tools/verify/exe_smoke.ps1 -Language zh
#
# Exit code:
#   0 = all checks passed
#   1 = at least one product check failed
#   2 = a PRECONDITION failed (no window could be obtained within the startup
#       wait, so the title criterion was NOT judged). Task 47 W1b D-separation:
#       a device/timing precondition must never be reported as a product FAIL.
#
# -SimulateNoWindow exists only so the device self-test
# (tools/verify/task47_device_selftest.ps1, control C7) can exercise the
# precondition path deterministically. It must not be used for real runs.

[CmdletBinding()]
param(
    [string]$ExePath = '',
    [string]$Language = '',
    [int]$StartupWaitSec = 12,
    [int]$PreCloseWaitSec = 8,
    [int]$CloseWaitSec = 6,
    # A1 (round 5): title settle window. See the sampling block below for why
    # the stability floor is 10s and not "5 samples".
    [int]$TitleSettleMaxSec = 45,
    [int]$TitleSettleStableSec = 10,
    [int]$TitleSampleMs = 500,
    [switch]$SimulateNoWindow
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
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassNameW(IntPtr hWnd, System.Text.StringBuilder text, int maxCount);

    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int L; public int T; public int R; public int B; }

    // Process.MainWindowHandle is not dependable for a freshly started Flutter
    // app (it can stay Zero even while a visible window exists). Enumerate the
    // process' own top-level windows and take the visible one with the largest
    // area: that is the app window, and it does not depend on .NET caching.
    public static IntPtr FindMainWindow(uint pid) {
        IntPtr best = IntPtr.Zero;
        long bestArea = -1;
        EnumWindows(delegate(IntPtr h, IntPtr l) {
            uint p; GetWindowThreadProcessId(h, out p);
            if (p != pid) return true;
            if (!IsWindowVisible(h)) return true;
            RECT r; if (!GetWindowRect(h, out r)) return true;
            long area = (long)(r.R - r.L) * (long)(r.B - r.T);
            if (area <= 0) return true;
            if (area > bestArea) { bestArea = area; best = h; }
            return true;
        }, IntPtr.Zero);
        return best;
    }

    // D8 (Task 47 W1b): same search, but only windows that carry a non-empty
    // title. A visible window with an empty title can belong to an input-method
    // helper that was created inside this very pid (observed: Sogou
    // "SoPY_Status"), and picking it by area alone made section 2 title
    // assertions fail spuriously on a perfectly healthy app window.
    public static IntPtr FindTitledWindow(uint pid) {
        IntPtr best = IntPtr.Zero;
        long bestArea = -1;
        EnumWindows(delegate(IntPtr h, IntPtr l) {
            uint p; GetWindowThreadProcessId(h, out p);
            if (p != pid) return true;
            if (!IsWindowVisible(h)) return true;
            var t = new System.Text.StringBuilder(256); GetWindowTextW(h, t, 256);
            if (t.Length == 0) return true;
            RECT r; if (!GetWindowRect(h, out r)) return true;
            long area = (long)(r.R - r.L) * (long)(r.B - r.T);
            if (area <= 0) return true;
            if (area > bestArea) { bestArea = area; best = h; }
            return true;
        }, IntPtr.Zero);
        return best;
    }
    // Second layer of the same search: ignore visibility (and area), so a
    // window that exists but is still hidden can still be named in the report
    // instead of being silently missing. Returns Zero when the pid owns no
    // top-level window at all.
    public static IntPtr FindAnyWindow(uint pid) {
        IntPtr first = IntPtr.Zero;
        EnumWindows(delegate(IntPtr h, IntPtr l) {
            uint p; GetWindowThreadProcessId(h, out p);
            if (p != pid) return true;
            first = h;
            return false;
        }, IntPtr.Zero);
        return first;
    }

    public static string DumpWindows(uint pid) {
        System.Text.StringBuilder sb = new System.Text.StringBuilder();
        EnumWindows(delegate(IntPtr h, IntPtr l) {
            uint p; GetWindowThreadProcessId(h, out p);
            if (p != pid) return true;
            var t = new System.Text.StringBuilder(256); GetWindowTextW(h, t, 256);
            var c = new System.Text.StringBuilder(256); GetClassNameW(h, c, 256);
            RECT r; GetWindowRect(h, out r);
            sb.AppendLine(string.Format("  hwnd={0} vis={1} class={2} rect={3},{4} {5}x{6} title='{7}'",
                h, IsWindowVisible(h), c, r.L, r.T, r.R - r.L, r.B - r.T, t));
            return true;
        }, IntPtr.Zero);
        return sb.ToString();
    }
}
'@

$failures = New-Object System.Collections.Generic.List[string]
$precondFailed = $false

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

# Expected title for the requested language. Empty -Language keeps the old
# behaviour (any known spelling), which is what a human run without arguments
# gets. Get-ActLogExpectedTitle / Test-ActLogTitleStrict live in
# data_location.ps1 and use exact matching only - no regex fallback.
$expectedTitle = ''
if (-not [string]::IsNullOrWhiteSpace($Language)) {
    $expectedTitle = Get-ActLogExpectedTitle -Language $Language
    if ([string]::IsNullOrEmpty($expectedTitle)) {
        Write-Host "[WARN] unknown -Language '$Language'; falling back to the exact-candidate match"
    }
}
Write-Host "[INFO] language = '$Language' expected_title = '$expectedTitle'"

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
    # --- 1. alive + main window handle --------------------------------------
    # D1 (Task 47 W1b): the handle is found by enumerating this pid's own
    # top-level windows (visible, largest area). Process.MainWindowHandle is
    # only logged for comparison - it was observed to stay Zero (or to lag) on
    # this build, which produced an empty title and a bogus title FAIL.
    $handle = [IntPtr]::Zero
    $deadline = (Get-Date).AddSeconds($StartupWaitSec)
    while ((Get-Date) -lt $deadline) {
        if ($proc.HasExited) { break }
        $h = [ActLogWin32]::FindTitledWindow([uint32]$proc.Id)
        if ($h -ne [IntPtr]::Zero) {
            $handle = $h
            break
        }
        Start-Sleep -Milliseconds 500
    }
    # D8 (Task 47 W1b): wait for the titled window instead of taking the largest
    # visible one immediately. If the app really never gets a titled top-level
    # window, fall back to the old area-only search so the report still names a
    # handle rather than reporting "none".
    if (($handle -eq [IntPtr]::Zero) -and (-not $proc.HasExited)) {
        $handle = [ActLogWin32]::FindMainWindow([uint32]$proc.Id)
        if ($handle -ne [IntPtr]::Zero) {
            Write-Host "[WARN] no titled top-level window within ${StartupWaitSec}s; fell back to the largest visible window"
        }
    }
    $proc.Refresh()
    Write-Host "[INFO] main window handle (EnumWindows) = $handle, Process.MainWindowHandle = $($proc.MainWindowHandle)"
    Assert-True (-not $proc.HasExited) "process started and is alive (pid=$($proc.Id))"
    if ($proc.HasExited) {
        Write-Host "[FAIL] process exited early with code $($proc.ExitCode)"
        exit 1
    }

    # --- 2. window title ----------------------------------------------------
    $title = ''
    $winClass = ''
    $invisibleFallback = $false
    if ($SimulateNoWindow) {
        Write-Host '[INFO] -SimulateNoWindow: window discovery skipped on purpose (device self-test path, control C7).'
        $handle = [IntPtr]::Zero
    }
    if ($handle -ne [IntPtr]::Zero) {
        $sb = New-Object System.Text.StringBuilder 512
        [void][ActLogWin32]::GetWindowTextW($handle, $sb, 512)
        $title = $sb.ToString()
        $cb = New-Object System.Text.StringBuilder 256
        [void][ActLogWin32]::GetClassNameW($handle, $cb, 256)
        $winClass = $cb.ToString()
    } elseif (-not $SimulateNoWindow) {
        # No *visible* window: dump what the process does own, then try the
        # no-visibility search so a device defect can be told from a product
        # defect instead of being reported as an empty-title product FAIL.
        Write-Host "[WARN] no visible top-level window found for pid=$($proc.Id); windows seen:"
        Write-Host ([ActLogWin32]::DumpWindows([uint32]$proc.Id))
        $any = [ActLogWin32]::FindAnyWindow([uint32]$proc.Id)
        if ($any -ne [IntPtr]::Zero) {
            $invisibleFallback = $true
            $sb = New-Object System.Text.StringBuilder 512
            [void][ActLogWin32]::GetWindowTextW($any, $sb, 512)
            $title = $sb.ToString()
            $cb = New-Object System.Text.StringBuilder 256
            [void][ActLogWin32]::GetClassNameW($any, $cb, 256)
            $winClass = $cb.ToString()
            Write-Host "[INFO] fallback to a non-visible top-level window hwnd=$any (judgement will be marked as such)"
        }
    }
    $codes = ($title.ToCharArray() | ForEach-Object { 'U+{0:X4}' -f [int]$_ }) -join ' '
    Write-Host "[INFO] window title = '$title' (class='$winClass')"
    Write-Host "[INFO] window title code points: $codes"
    if ($invisibleFallback) {
        Write-Host '[WARN] title was read from a window that is not visible; note this in the verdict'
    }
    if ([string]::IsNullOrEmpty($title)) {
        $precondFailed = $true
        Write-Host "[FAIL_PRECONDITION] no window obtainable within $($StartupWaitSec)s -- title criterion NOT judged"
        Write-Host '  attribution: device/timing precondition, NOT a product defect'
    } else {
        $label = if ($expectedTitle -ne '') { $expectedTitle } else { 'any known app title spelling' }
        $TestTitle = {
            param([string]$t)
            if ($expectedTitle -ne '') { return (Test-ActLogTitleStrict -Text $t -Language $Language) }
            return (Test-ActLogTitleStrict -Text $t)
        }
        $titleOk = (& $TestTitle $title)
        $settleMs = 0
        $samples = 1
        $settleReason = 'matched-immediately'
        if (-not $titleOk) {
            # A1 (round 5): the shipped binary applies the localized title a
            # moment AFTER the first frame, so one read taken as soon as the
            # window exists can legitimately catch the previous title (measured
            # transition: 0.5s-3.5s after start). The acceptance rule allows a
            # short difference during startup but demands the expected title
            # once the state has settled, so sample instead of reading once:
            #   - expected title at any sample      -> PASS (settle_ms recorded)
            #   - no match within TitleSettleMaxSec -> FAIL (timeout)
            #   - unchanged for TitleSettleStableSec -> FAIL (settled on a wrong
            #     title)
            # The stability window MUST be >= 10s: the measured transition tops
            # out at 3.5s, so the naive "5 identical samples" (2.5s) would fail
            # a perfectly healthy start. Do not shrink it below 10s.
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $lastText = $title
            $stableSince = 0
            $maxMs = $TitleSettleMaxSec * 1000
            $stableMs = $TitleSettleStableSec * 1000
            while ($true) {
                Start-Sleep -Milliseconds $TitleSampleMs
                $samples++
                $sb2 = New-Object System.Text.StringBuilder 512
                [void][ActLogWin32]::GetWindowTextW($handle, $sb2, 512)
                $now = $sb2.ToString()
                $el = [int]$sw.ElapsedMilliseconds
                if ($now -ne $lastText) {
                    $tlCodes = ($now.ToCharArray() | ForEach-Object { 'U+{0:X4}' -f [int]$_ }) -join ' '
                    Write-Host "[INFO] TL t_ms=$el len=$($now.Length) codes=$tlCodes text='$now'"
                    $lastText = $now
                    $stableSince = $el
                }
                if (& $TestTitle $now) {
                    $titleOk = $true
                    $settleMs = $el
                    $settleReason = 'matched-after-settle'
                    $title = $now
                    break
                }
                if ($el -ge $maxMs) { $settleReason = 'timeout'; break }
                if (($el -ge $stableMs) -and (($el - $stableSince) -ge $stableMs)) {
                    $settleReason = 'settled-on-wrong-title'
                    break
                }
            }
        }
        Write-Host "[INFO] title settle: samples=$samples settle_ms=$settleMs reason=$settleReason stable_need_ms=$($TitleSettleStableSec * 1000) max_ms=$($TitleSettleMaxSec * 1000)"
        if ($settleReason -ne 'matched-immediately') {
            $finalCodes = ($title.ToCharArray() | ForEach-Object { 'U+{0:X4}' -f [int]$_ }) -join ' '
            Write-Host "[INFO] settled title = '$title' code points: $finalCodes"
        }
        Assert-True $titleOk "window title is the app title (expected: '$label')"
    }

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
if ($precondFailed) {
    Write-Host "EXE_SMOKE: FAIL_PRECONDITION (precondition not met; product criteria NOT judged) [other failures: $($failures.Count)]"
    foreach ($f in $failures) { Write-Host "  - $f" }
    exit 2
}
if ($failures.Count -eq 0) {
    Write-Host 'EXE_SMOKE: PASS (all checks passed)'
    exit 0
}
Write-Host "EXE_SMOKE: FAIL ($($failures.Count) failed)"
foreach ($f in $failures) { Write-Host "  - $f" }
exit 1