# installed_app_check.ps1 -- READ-ONLY triage of an installed / built actlog.
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
# It never starts, stops, or injects into anything. No mouse, no keyboard, no
# Start-Process, no Stop-Process. Safe to run while the app is up.
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
    [string]$Report = 'F:\soft\00selfmade\practilog\.superpowers\installed_app_check.txt'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'data_location.ps1')

$lines = New-Object 'System.Collections.Generic.List[string]'
function Say([string]$s) { $lines.Add($s); Write-Host $s }

Say '=== actlog installed-app tray triage (read only) ==='
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

# ---------------------------------------------------------------- 2. data dir
Say ''
Say '--- 2. data dir (userdata, then ProgramData/Local fallbacks, then legacy %APPDATA%) ---'
$data = Resolve-ActLogDataDir -ExePath $ExePath
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
    if ($lay[-1] -match 'dir=(\S+)') {
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

$verdict = ''
$why = ''
if ($procs.Count -eq 0) {
    $verdict = 'a'
    $why = 'process is gone: close quit the app instead of hiding it. Look at the ' +
        'close/prevent-close chain (desktop_shell.dart), not the icon code. The ' +
        'icon disappearing with the process is expected Windows behaviour.'
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
Say ("  VERDICT ({0}): {1}" -f $verdict, $why)
Say '  cross-checks: run tray_alive_check.ps1 (keeps the app alive and opens the'
Say '  flyout through UIA) for visual proof; run tray_interaction_check.ps1 for a'
Say '  real click. Both start the app, so do NOT run them as part of this triage.'

if ($procs.Count -eq 0 -and $hasReady) {
    Say '  extra: this run logged "tray ready" yet no process remains -> the icon'
    Say '  went away when the process did, i.e. cause (a), not a tray bug.'
}

# ---------------------------------------------------------------- report
$lines | Set-Content -Path $Report -Encoding UTF8
Write-Host ''
Write-Host "report written: $Report"
exit 0
