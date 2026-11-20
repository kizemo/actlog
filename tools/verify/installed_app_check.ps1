# installed_app_check.ps1 -- triage of an installed / built actlog.
#
# Question it answers: the user reports "after closing the window there is no
# tray icon left". That has three very different causes and needs three very
# different fixes, so this script separates them from evidence only:
#
#   (a) PROCESS GONE      the app quit on close instead of hiding -> the
#                         close-to-tray / prevent-close chain did not take hold
#   (b) ICON ALIVE, HIDDEN the process is up, the log says 'tray ready', and no
#                         top-level window is visible -> the icon exists but is
#                         folded into the notification-area overflow flyout
#   (c) PROCESS ALIVE, NO IICON the log has 'tray FAIL' or never reached
#                         'tray ready' -> Shell_NotifyIcon really did not add it
#
# HOW FAR IT GOES (D7, Task 47 W1b round 2 -- report section F.2): for an
# INSTALLED target it runs one bounded close probe -- start the exe, wait for its
# main window, post WM_CLOSE, then POLL the process for AliveTimeoutSec (>= 8 s
# by default). That probe is the only honest way to answer "did close quit the
# app or hide it": the earlier version answered it from "does an actlog process
# exist right now", which is also false when the app was simply never started,
# and it printed a product FAIL for that (contradicting exe_smoke on the same
# build). "process is gone" is now only produced after an observed close.
# -SkipCloseProbe restores the old pure read-only mode (no start, no close).
# No mouse, no keyboard, no input injection of any kind.
#
# RENAME (PractiLog -> actlog): every lookup is done with BOTH the current and
# the legacy spelling, so the triage still finds a not-yet-migrated install.
#
# Deliberately NOT used: EnumWindows to find the tray callback window. That
# window is message-only (parented to HWND_MESSAGE as NativeApiHostWindow) and
# cannot be enumerated from another process -- established for this project.
# Tray liveness is therefore judged from "process alive + log markers".
#
# Usage:
#   pwsh -NoProfile -ExecutionPolicy Bypass -File tools/verify/installed_app_check.ps1
#   pwsh -File tools/verify/installed_app_check.ps1 -ExePath 'D:\Program Files\actlog\actlog.exe'
#
# Output: console plus .superpowers/installed_app_check.txt. ASCII only.

[CmdletBinding()]
param(
    [string]$ExePath = '',
    # D6 (Task 47 W1b): the report used to land in the planning folder
    # (.superpowers). Callers pass the evidence directory instead; the old
    # location stays the default so existing invocations keep working.
    [string]$ReportDir = 'F:\soft\00selfmade\practilog\.superpowers',
    [string]$Report = '',
    # ------------------------------------------------ D7 close probe (F.2)
    # -SkipCloseProbe: keep the old purely read-only behaviour (nothing is
    # started, nothing is closed, and the "quit on close" question is then
    # reported as NOT JUDGED instead of being guessed from a process snapshot).
    [switch]$SkipCloseProbe,
    [int]$StartupWaitSec = 20,
    # The tray icon and the prevent-close flag only exist after the first frame;
    # closing earlier would quit the app for a reason unrelated to the test.
    [int]$PreCloseSettleSec = 8,
    # Poll budget after WM_CLOSE. The contract requires >= 8 s; 10 s is used so
    # a slow tray teardown can never be mistaken for a quit.
    [int]$AliveTimeoutSec = 10,
    [int]$AlivePollMs = 250,
    # SELF-TEST ONLY (control C14). When set, the probe does not start $ExePath:
    # it starts a fresh pwsh running this fixture script, so the SAME close
    # criterion is pointed at a target that really quits on close. Kept as
    # separate parameters on purpose -- a single "-LaunchArgs '-NoProfile ...'"
    # string cannot survive a script parameter binder (the leading dash is read
    # as a parameter name: "parameter 'LaunchArgs' is missing an argument").
    [string]$ProbeFixture = '',
    [ValidateSet('exit-on-close', 'hold')]
    [string]$ProbeFixtureMode = 'exit-on-close',
    [string]$ProbeFixtureTitle = 'actlog scratch window'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'data_location.ps1')

if ([string]::IsNullOrWhiteSpace($Report)) {
    $Report = Join-Path $ReportDir 'installed_app_check.txt'
}
if (-not (Test-Path -LiteralPath $ReportDir)) {
    [void](New-Item -ItemType Directory -Path $ReportDir -Force)
}

$lines = New-Object 'System.Collections.Generic.List[string]'
function Say([string]$s) { $lines.Add($s); Write-Host $s }

Say '=== actlog installed-app tray triage (one bounded close probe; -SkipCloseProbe for read-only) ==='
Say ("time      : " + (Get-Date).ToString('s'))
Say ("powershell: " + $PSVersionTable.PSVersion.ToString())

# ---------------------------------------------------------------- 1. which exe
Say ''
Say '--- 1. actlog.exe / practilog.exe copies on disk ---'
$installed = @()
$regInstall = @()
foreach ($k in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )) {
    $items = Get-ItemProperty $k -ErrorAction SilentlyContinue
    foreach ($it in @($items)) {
        if ($it -and ($it.DisplayName -match '(?i)(actlog|practilog)')) {
            $regInstall += ("{0} | version={1} | location=[{2}] | uninst=[{3}]" -f `
                    $it.DisplayName, $it.DisplayVersion, $it.InstallLocation, $it.UninstallString)
        }
    }
}
if ($regInstall.Count) { $regInstall | ForEach-Object { Say ("  registry: " + $_) } }
else { Say '  registry: no uninstall entry mentions actlog or practilog (not installed machine-wide)' }

$candidates = @()
if ($ExePath) { $candidates += $ExePath }
$dirs = @(
    'D:\Program Files\actlog',
    'C:\Program Files\actlog',
    'C:\Program Files (x86)\actlog',
    'D:\Program Files\practilog',
    'C:\Program Files\practilog',
    'F:\soft\00selfmade\practilog\release',
    (Get-ActLogDevReleaseDir)
)
if ($env:LOCALAPPDATA) {
    $dirs += [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Programs\actlog')
    $dirs += [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Programs\PractiLog')
    $dirs += [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Programs\practilog')
}
foreach ($d in $dirs) {
    # Combine/File/Directory instead of Join-Path/Test-Path: those resolve drives,
    # so an unmounted D: would abort this triage instead of reporting "absent".
    if (-not $d) { continue }
    foreach ($n in (Get-ActLogExeNames)) {
        $candidates += [System.IO.Path]::Combine($d, $n)
    }
}
foreach ($c in ($candidates | Where-Object { $_ } | Select-Object -Unique)) {
    if ([System.IO.File]::Exists($c)) {
        $i = Get-Item -LiteralPath $c
        $installed += $c
        Say ("  FOUND  {0}  {1} bytes  built {2:s}" -f $c, $i.Length, $i.LastWriteTime)
    } else {
        Say ("  absent " + $c)
    }
}

# ------------------------------------------------- D2. which target is judged
# D2 (Task 47 W1b): without this block a run with no -ExePath silently resolved
# the BUILD TREE (apps\desktop\build\...\Release\userdata), read an old log
# there and printed a green verdict about nothing. Every run now states which
# target it judged, and a build-tree target carries a loud warning.
Say ''
Say '--- 1b. judged target (D2, Task 47 W1b) ---'
$TargetSource = if ([string]::IsNullOrWhiteSpace($ExePath)) { 'auto' } else { 'explicit' }
if ($TargetSource -eq 'auto') {
    # Same resolver the other devices use. Only the CALLER behaviour changes
    # here; Resolve-ActLogExePath itself is untouched.
    $ExePath = Resolve-ActLogExePath
}
$TargetKind = 'none'
if (-not [string]::IsNullOrWhiteSpace($ExePath)) {
    if ($ExePath -match '(?i)[\\/]build[\\/]') { $TargetKind = 'buildtree' } else { $TargetKind = 'installed' }
}
if ($TargetSource -eq 'auto') {
    $TargetSource = if ($TargetKind -eq 'buildtree') { 'auto-buildtree' } else { 'auto-installed' }
}
$TargetExeText = if ([string]::IsNullOrWhiteSpace($ExePath)) { '(none resolved)' } else { $ExePath }
Say ("  TARGET_SOURCE = " + $TargetSource)
Say ("  TARGET_KIND   = " + $TargetKind)
Say ("  TARGET_EXE    = " + $TargetExeText)
if ($TargetKind -eq 'buildtree') {
    Say '[WARN] target is the BUILD TREE, not an installed app -- a green run here says nothing about the installed copy'
}
if ($TargetKind -eq 'none') {
    Say '[WARN] no target exe resolved: the data dir below is a folder-only guess'
}

# ---------------------------------------------------- 1c. close probe (F.2)
# D7 (Task 47 W1b round 2): "does closing the window quit the app" is answered
# by ONE bounded observation, never by a process snapshot:
#   start -> wait for the main window -> settle -> WM_CLOSE -> poll
#   AliveTimeoutSec -> PROCESS_GONE | HIDDEN_TO_TRAY | STILL_VISIBLE.
# The probe kills nothing itself; the pid it started is stopped in section 7 so
# that sections 3-6 can still report the post-close state (alive, no window).
Say ''
Say '--- 1c. close probe: does closing the window quit the app? (D7) ---'

if (-not ('PLCloseWin32' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class PLCloseWin32 {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowTextW(IntPtr hWnd, System.Text.StringBuilder text, int maxCount);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", SetLastError = true)] public static extern bool SetProcessDpiAwarenessContext(IntPtr ctx);

    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int L; public int T; public int R; public int B; }

    // Same rule as exe_smoke.ps1: Process.MainWindowHandle can stay Zero for a
    // freshly started Flutter app, so take the visible window with the largest
    // area among the pid's own top-level windows.
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
}
'@
}

function Get-PLWindowTitle {
    param([IntPtr]$Hwnd)
    if ($Hwnd -eq [IntPtr]::Zero) { return '' }
    $sb = New-Object System.Text.StringBuilder(512)
    [void][PLCloseWin32]::GetWindowTextW($Hwnd, $sb, 512)
    return $sb.ToString()
}

function Invoke-ActLogCloseProbe {
    param([string]$Exe, [string[]]$ArgList)
    $o = [pscustomobject]@{
        Outcome       = 'NOT_RUN'
        Pid           = 0
        Hwnd          = [IntPtr]::Zero
        Title         = ''
        ForegroundOk  = $false
        VisibleBefore = $false
        VisibleAfter  = $false
        WaitMs        = -1
        Note          = ''
    }
    $argList = @($ArgList)
    try {
        if ($argList.Count -gt 0) {
            $proc = Start-Process -FilePath $Exe -ArgumentList $argList -PassThru
        } else {
            $proc = Start-Process -FilePath $Exe -PassThru
        }
    } catch {
        $o.Outcome = 'START_FAILED'
        $o.Note = $_.Exception.Message
        return $o
    }
    $o.Pid = $proc.Id
    # A per-monitor-unaware caller sees virtualised rects; ask for per-monitor
    # v2 first so FindMainWindow picks the real window. Failure is harmless.
    [void][PLCloseWin32]::SetProcessDpiAwarenessContext([IntPtr](-4))

    # Two-layer wait, and the ORDER matters. Layer 1 (any visible window) can be
    # satisfied by the runner's pre-first-frame window, which has NO title and is
    # NOT the window the user closes. Measured on the installed build: the probe
    # posted WM_CLOSE to that titleless window, the app hid it, and the real
    # titled window stayed on screen -- i.e. "hidden to tray" for the wrong
    # window. So keep waiting until the window carries a title (the app sets it
    # after the first frame) and only fall back to a titleless window when the
    # startup budget runs out (noted in the report, never silent).
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $hwnd = [IntPtr]::Zero
    $titleNow = ''
    while ($sw.Elapsed.TotalSeconds -lt $StartupWaitSec) {
        if ($proc.HasExited) { break }
        $h = [PLCloseWin32]::FindMainWindow([uint32]$proc.Id)
        if ($h -ne [IntPtr]::Zero) {
            $hwnd = $h
            $titleNow = Get-PLWindowTitle -Hwnd $h
            if ($titleNow -ne '') { break }
        }
        Start-Sleep -Milliseconds 250
    }
    if ($proc.HasExited) { $o.Outcome = 'PRECONDITION_EXITED_EARLY'; return $o }
    if ($hwnd -eq [IntPtr]::Zero) { $o.Outcome = 'PRECONDITION_NO_WINDOW'; return $o }
    if ($titleNow -eq '') { $o.Note = 'window title stayed empty within the startup budget' }
    $o.Hwnd = $hwnd
    $o.Title = $titleNow

    # Foreground is RECORDED ONLY: a background window still receives WM_CLOSE,
    # so this never becomes a pass/fail criterion (the interaction devices in
    # this folder do need it; this triage does not).
    [void][PLCloseWin32]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 250
    $o.ForegroundOk = ([PLCloseWin32]::GetForegroundWindow() -eq $hwnd)

    # The tray icon and the prevent-close flag only exist after the first frame.
    Start-Sleep -Seconds $PreCloseSettleSec
    if ($proc.HasExited) { $o.Outcome = 'PRECONDITION_EXITED_EARLY'; return $o }
    # The target may have replaced its window during the settle time; close the
    # window that is actually on screen NOW, not the one seen at startup.
    $hNow = [PLCloseWin32]::FindMainWindow([uint32]$proc.Id)
    if ($hNow -ne [IntPtr]::Zero) {
        $hwnd = $hNow
        $o.Hwnd = $hwnd
        $tNow = Get-PLWindowTitle -Hwnd $hwnd
        if ($tNow -ne '') { $o.Title = $tNow }
    }
    $o.VisibleBefore = [PLCloseWin32]::IsWindowVisible($hwnd)

    [void][PLCloseWin32]::PostMessage($hwnd, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)

    $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
    $gone = $false
    while ($sw2.Elapsed.TotalMilliseconds -lt ($AliveTimeoutSec * 1000)) {
        if ($proc.HasExited) { $gone = $true; break }
        Start-Sleep -Milliseconds $AlivePollMs
    }
    if (-not $gone) { $gone = $proc.HasExited }
    $o.WaitMs = [int][Math]::Round($sw2.Elapsed.TotalMilliseconds)
    # Visibility is judged by RE-SCANNING every top-level window of the pid, not
    # by asking the single hwnd that was closed: a target that closes one window
    # and keeps another (or re-creates it) would otherwise be called hidden while
    # it is plainly on screen.
    if ($gone) {
        $o.VisibleAfter = $false
    } else {
        $hAfter = [PLCloseWin32]::FindMainWindow([uint32]$proc.Id)
        $o.VisibleAfter = ($hAfter -ne [IntPtr]::Zero)
        if ($o.VisibleAfter) { $o.Hwnd = $hAfter }
    }

    if ($gone) { $o.Outcome = 'PROCESS_GONE' }
    elseif ($o.VisibleAfter) { $o.Outcome = 'STILL_VISIBLE' }
    else { $o.Outcome = 'HIDDEN_TO_TRAY' }
    return $o
}

$probeOutcome = 'NOT_RUN'
$probePid = 0
$probeReason = ''
$targetIsActLog = ($ExePath -match '(?i)(actlog|practilog)\.exe$')
$actlogBefore = @(Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue)
if ($SkipCloseProbe) {
    $probeReason = '-SkipCloseProbe given: read-only mode, the quit-on-close question is NOT judged'
} elseif ($TargetKind -ne 'installed') {
    $probeReason = "target kind is '" + $TargetKind + "', not 'installed': no close probe"
} elseif (-not [System.IO.File]::Exists($ExePath)) {
    $probeReason = 'target exe does not exist: no close probe'
} elseif ($targetIsActLog -and -not $ProbeFixture -and $actlogBefore.Count -gt 0) {
    $probeReason = 'actlog is already running: refusing to close a live user session'
}

$probe = $null
if (-not $probeReason) {
    $probeExe = $ExePath
    $probeArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($ProbeFixture)) {
        # SELF-TEST ONLY: run the fixture inside a fresh pwsh, so the close
        # criterion is applied to a target whose "close == quit" behaviour is
        # known in advance (control C14). Start-Process takes an ARRAY here, so
        # a dash-leading element is not a problem the way a script parameter is.
        $probeExe = [System.IO.Path]::Combine($PSHOME, 'pwsh.exe')
        $probeArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ProbeFixture,
            '-Mode', $ProbeFixtureMode, '-WindowTitle', $ProbeFixtureTitle)
        Say ("  CLOSE_PROBE_TARGET_OVERRIDE = fresh pwsh running fixture [" +
            $ProbeFixture + "] mode=" + $ProbeFixtureMode)
    }
    $probe = Invoke-ActLogCloseProbe -Exe $probeExe -ArgList $probeArgs
    $probeOutcome = $probe.Outcome
    $probePid = $probe.Pid
    Say ("  CLOSE_PROBE                = " + $probe.Outcome)
    Say ("  CLOSE_PROBE_PID            = " + $probe.Pid)
    Say ("  CLOSE_PROBE_HWND           = 0x" + $probe.Hwnd.ToInt64().ToString('X'))
    Say ("  CLOSE_PROBE_TITLE          = [" + $probe.Title + "]")
    Say ("  CLOSE_PROBE_FOREGROUND_OK  = " + $probe.ForegroundOk)
    Say ("  CLOSE_PROBE_VISIBLE_BEFORE = " + $probe.VisibleBefore)
    Say ("  CLOSE_PROBE_VISIBLE_AFTER  = " + $probe.VisibleAfter)
    Say ("  CLOSE_PROBE_WAIT_MS        = " + $probe.WaitMs)
    Say ("  CLOSE_PROBE_SETTLE_SEC/ALIVE_TIMEOUT_SEC/POLL_MS = {0}/{1}/{2}" -f `
            $PreCloseSettleSec, $AliveTimeoutSec, $AlivePollMs)
    if ($probe.Note) { Say ("  CLOSE_PROBE_NOTE           = " + $probe.Note) }
    switch ($probe.Outcome) {
        'PROCESS_GONE' {
            Say ("  process is gone: close quit the app instead of hiding it (exited {0} ms after WM_CLOSE)" -f $probe.WaitMs)
        }
        'HIDDEN_TO_TRAY' {
            Say ("  [ OK ] app survives the window close (hidden to tray instead of quitting); still alive {0} ms after WM_CLOSE" -f $probe.WaitMs)
        }
        'STILL_VISIBLE' {
            Say '  [WARN] process is alive but its window is still visible after WM_CLOSE'
        }
        'PRECONDITION_EXITED_EARLY' {
            Say '  [WARN] target exited before the close could be posted: NOT judged'
        }
        'PRECONDITION_NO_WINDOW' {
            Say '  [WARN] no visible top-level window appeared within the startup budget: NOT judged'
        }
        default {
            Say ("  [WARN] probe outcome " + $probe.Outcome + ": NOT judged")
        }
    }
} else {
    Say ("  CLOSE_PROBE                = SKIPPED (" + $probeReason + ")")
}

# ---------------------------------------------------------------- 2. data dir
Say ''
Say '--- 2. data dir (userdata, then ProgramData/Local fallbacks, then legacy %APPDATA%) ---'
$data = Resolve-ActLogDataDir -ExePath $ExePath
Say ("  DATA_DIR      = " + $data.Path)
Say ("  DATA_DIR_KIND = " + $data.Kind)
Say ("  resolved : {0}  kind={1} exists={2}" -f $data.Path, $data.Kind, $data.Exists)
foreach ($c in $data.Candidates) { Say ("  cand     : [{0}] exists={1} {2}" -f $c.Kind, $c.Exists, $c.Path) }
Say ("  note     : <exe dir>\data\flutter_assets is Flutter's own assets, never app data")

# Path.Combine / File::Exists, not Join-Path / Test-Path: a candidate dir can sit
# on a drive PowerShell has not mounted, and Test-Path throws "drive not found".
$logFile = Resolve-ActLogLogFile -FileName 'actlog_startup.log' -ExePath $ExePath
Say ("  startup log: " + $logFile)
$logText = ''
$lastRun = ''
if ([System.IO.File]::Exists($logFile)) {
    $li = Get-Item -LiteralPath $logFile
    Say ("    size={0} bytes  last write {1:s}" -f $li.Length, $li.LastWriteTime)
    # FileShare ReadWrite: the app may be holding the append handle right now.
    $fs = [System.IO.File]::Open($logFile, 'Open', 'Read', [System.IO.FileShare]::ReadWrite)
    try {
        $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::UTF8)
        try { $logText = $sr.ReadToEnd() } finally { $sr.Dispose() }
    } finally { $fs.Dispose() }
    $all = @($logText -split "`r?`n" | Where-Object { $_ -match 'shell\.start' })
    if ($all.Count) {
        $idx = $logText.LastIndexOf($all[-1])
        $lastRun = $logText.Substring($idx)
        Say ("    {0} shell.start line(s) total; using the last one as this run's segment" -f $all.Count)
    } else {
        $lastRun = $logText
        Say '    no shell.start marker found: using the whole file'
    }
} else {
    Say '    ABSENT - this data dir has no startup log, so the app never wrote here'
}
Say '    ---- last run segment (verbatim, max 40 lines) ----'
if ($lastRun) {
    (@($lastRun -split "`r?`n") | Select-Object -Last 40) | ForEach-Object { Say ("    | " + $_) }
} else { Say '    | (empty)' }

# main.dart logs 'data.layout=<layout> dir=<path> notes=...' as the first line of
# every run, i.e. BEFORE shell.start, so it is not part of the segment above.
# This is the app's own declaration of where it wrote -- stronger evidence than
# any guess this script can make.
Say '    ---- data dir declared by the app itself ----'
$lay = @($logText -split "`r?`n" | Where-Object { $_ -match 'data\.layout=' })
if ($lay.Count) {
    Say ("    last declaration: " + $lay[-1])
    # dir= is followed by " notes=..." on the same line, and the path itself can
    # contain a space ("D:\Program Files\actlog\userdata"). The old \S+ stopped at
    # the first space and reported a false MISMATCH against the resolved path.
    if ($lay[-1] -match 'dir=(.+?)(?:\s+notes=|\s*$)') {
        $declared = $matches[1]
        if ($declared -ne $data.Path) {
            Say ("    MISMATCH: the app wrote to " + $declared + " but this script resolved " + $data.Path)
            Say '    -> read the log from the declared dir; the resolver only sees dirs that exist'
        } else {
            Say '    agrees with the path resolved above'
        }
    }
} else {
    Say '    no data.layout= line: this log predates that marker (pre-migration build)'
}

# ---------------------------------------------------------------- 3. processes
Say ''
Say '--- 3. running processes (looked at, never touched) ---'
$procs = @(Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue)
if ($procs.Count -eq 0) {
    Say '  no actlog process is running'
} else {
    foreach ($pr in $procs) {
        $mod = '(unknown)'
        try {
            $m = @($pr.Modules | Where-Object { $_.ModuleName -match '(?i)cnativeapi' })
            $mod = if ($m.Count) { 'LOADED -> tray native path executed' } else { 'NOT LOADED' }
        } catch { $mod = 'access denied (bitness or elevation mismatch)' }
        Say ("  pid={0} start={1:s} mainWindowTitle=[{2}] cnativeapi.dll={3}" -f `
                $pr.Id, $pr.StartTime, $pr.MainWindowTitle, $mod)
    }
}

# ---------------------------------------------------------------- 4. windows
Say ''
Say '--- 4. visible top-level windows carrying the app title ---'
if (-not ('PLWin32.Native' -as [type])) {
    Add-Type -Namespace PLWin32 -Name Native -MemberDefinition @'
public delegate bool EnumProc(System.IntPtr hWnd, System.IntPtr lParam);

[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool EnumWindows(EnumProc cb, System.IntPtr lParam);

[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool IsWindowVisible(System.IntPtr hWnd);

[System.Runtime.InteropServices.DllImport("user32.dll", CharSet=System.Runtime.InteropServices.CharSet.Unicode)]
public static extern int GetWindowText(System.IntPtr hWnd, System.Text.StringBuilder s, int max);

[System.Runtime.InteropServices.DllImport("user32.dll", CharSet=System.Runtime.InteropServices.CharSet.Unicode)]
public static extern int GetWindowTextLength(System.IntPtr hWnd);
'@
}
$script:winHits = New-Object 'System.Collections.Generic.List[string]'
$titleRegex = Get-ActLogTitleRegex
$cb = [PLWin32.Native+EnumProc] {
    param($h, $l)
    if ([PLWin32.Native]::IsWindowVisible($h)) {
        $n = [PLWin32.Native]::GetWindowTextLength($h)
        if ($n -gt 0) {
            $sb = New-Object System.Text.StringBuilder($n + 2)
            [void][PLWin32.Native]::GetWindowText($h, $sb, $sb.Capacity)
            $t = $sb.ToString()
            if ($t -match $titleRegex) {
                [void]$script:winHits.Add("hwnd=$h title=[$t]")
            }
        }
    }
    return $true
}
[void][PLWin32.Native]::EnumWindows($cb, [IntPtr]::Zero)
if ($script:winHits.Count) { $script:winHits | ForEach-Object { Say ("  " + $_) } }
else { Say '  none -> no visible app window (consistent with "hidden to tray")' }
Say '  (a message-only tray window is invisible to this scan by design)'

# ---------------------------------------------------------------- 5. shell icon state
Say ''
Say '--- 5. Shell_NotifyIcon registration history (HKCU NotifyIconSettings) ---'
$nk = 'HKCU:\Control Panel\NotifyIconSettings'
if (Test-Path $nk) {
    $hits = 0
    foreach ($x in @(Get-ChildItem $nk -ErrorAction SilentlyContinue)) {
        $p = Get-ItemProperty $x.PSPath -ErrorAction SilentlyContinue
        if ($p -and ($p.ExecutablePath -match '(?i)(actlog|practilog)')) {
            $hits++
            # IconSnapshot is a few hundred bytes of PNG -- never printed.
            $hid = if ($p.PSObject.Properties.Name -contains 'IsHidden') { $p.IsHidden } else { '(no value)' }
            $pro = if ($p.PSObject.Properties.Name -contains 'IsPromoted') { $p.IsPromoted } else { '(no value)' }
            Say ("  uid={0} exe={1} IsHidden={2} IsPromoted={3}" -f $x.PSChildName, $p.ExecutablePath, $hid, $pro)
        }
    }
    if ($hits -eq 0) { Say '  no actlog notify-icon setting recorded' }
    else { Say '  note: proves an icon was registered at some point, NOT that it is live now' }
} else {
    Say '  key absent (older Windows build?)'
}

# ---------------------------------------------------------------- 6. verdict
Say ''
Say '--- 6. verdict ---'
$seg = $lastRun
$hasReady = $seg -match 'tray ready'
$hasFail  = $seg -match 'tray FAIL'
$armed    = $seg -match 'hide on close armed'
$pcOn     = $seg -match 'preventClose on'
Say ("  markers in last run: tray ready={0} tray FAIL={1} hide on close armed={2} preventClose on={3}" -f `
        $hasReady, $hasFail, $armed, $pcOn)

$appRunningNow = ($procs.Count -gt 0)
Say ("  actlog process alive at this moment: " + $appRunningNow)
Say ("  close probe outcome: " + $probeOutcome)

# D7: only an OBSERVED close may claim "process is gone". A snapshot that shows
# no process is not evidence of a quit -- it is the normal state before any
# launch, and that is exactly the confusion that produced a false product fail.
$verdict = ''
$why = ''
if ($probeOutcome -eq 'PROCESS_GONE') {
    $verdict = 'a'
    $why = 'process is gone: close quit the app instead of hiding it. Look at the ' +
        'close/prevent-close chain (desktop_shell.dart), not the icon code. The ' +
        'icon disappearing with the process is expected Windows behaviour.'
} elseif ($probeOutcome -like 'PRECONDITION_*' -or $probeOutcome -eq 'START_FAILED') {
    $verdict = 'not-judged'
    $why = 'the close probe never reached the close step (' + $probeOutcome +
        '), so whether the app quits on close is NOT judged. Nothing here says the tray is broken.'
} elseif (-not $appRunningNow) {
    $verdict = 'not-running'
    $why = 'no actlog process is running and no close was observed, so the quit-on-close ' +
        'question is NOT judged (it is not a product failure). Start the app, or let the ' +
        'close probe run, and repeat.'
} elseif ($hasFail -or -not $hasReady) {
    $verdict = 'c'
    $why = 'process is alive but the last run did not report "tray ready"' +
        $(if ($hasFail) { ' and logged "tray FAIL"' } else { '' }) +
        ' -> the notification-area icon really was not added.'
} elseif ($script:winHits.Count -gt 0) {
    $verdict = 'b-window-visible'
    $why = 'tray is ready but a top-level window is still visible: the app is ' +
        'both on screen and in the tray. The icon exists; it is most likely ' +
        'folded into the overflow flyout.'
} else {
    $verdict = 'b'
    $why = 'process alive, "tray ready" logged, no visible window -> the icon ' +
        'is there but hidden behind the notification-area overflow chevron ' +
        '(Show hidden icons). Check the flyout, and/or drag the icon onto the ' +
        'taskbar in Settings > Personalization > Taskbar > Other system tray ' +
        'icons, before concluding it is missing.'
}
Say ("  VERDICT ({0}) [target={1}/{2}]: {3}" -f $verdict, $TargetSource, $TargetKind, $why)
Say '  cross-checks: run tray_alive_check.ps1 (keeps the app alive and opens the'
Say '  flyout through UIA) for visual proof; run tray_interaction_check.ps1 for a'
Say '  real click. Both start the app, so do NOT run them as part of this triage.'

if ($verdict -eq 'a' -and $hasReady) {
    Say '  extra: this run logged "tray ready" yet the process exited on close -> the'
    Say '  icon went away when the process did, i.e. cause (a), not a tray bug.'
}

# ---------------------------------------------------------------- 7. cleanup
# The probe started this pid, so the probe stops it. Nothing that was already
# running before this script is touched, and no other process is ever killed.
Say ''
Say '--- 7. cleanup of the probe process ---'
if ($probePid -gt 0) {
    $left = Get-Process -Id $probePid -ErrorAction SilentlyContinue
    if ($left) {
        try { Stop-Process -Id $probePid -Force -ErrorAction Stop } catch { }
        try { [void]$left.WaitForExit(3000) } catch { }
        $still = Get-Process -Id $probePid -ErrorAction SilentlyContinue
        if ($still) { Say ("  [WARN] probe pid " + $probePid + " is still alive") }
        else { Say ("  stopped probe pid " + $probePid + " (started by this script)") }
    } else {
        Say ("  probe pid " + $probePid + " already gone (nothing to stop)")
    }
} else {
    Say '  no probe process was started'
}
$actlogLeft = @(Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue)
if ($actlogLeft.Count) {
    foreach ($p in $actlogLeft) {
        Say ("  [NOTE] actlog process still running (pre-existing, left untouched): pid=" + $p.Id)
    }
} else {
    Say '  no actlog process remains'
}

# ---------------------------------------------------------------- report
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Report, (($lines -join "`r`n") + "`r`n"), $utf8)
$written = -1
try { $written = (Get-Item -LiteralPath $Report).Length } catch { $written = -1 }
Write-Host ''
Write-Host "report written: $Report ($written bytes)"
Write-Host "VERDICT=$verdict TARGET_SOURCE=$TargetSource TARGET_KIND=$TargetKind CLOSE_PROBE=$probeOutcome"
if ($verdict -eq 'a') { exit 1 }
exit 0
