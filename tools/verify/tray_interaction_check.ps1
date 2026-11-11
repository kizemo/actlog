# tray_interaction_check.ps1 -- P1 section 16.5 items 1 & 2, real machine.
#
# The tray callback window is a message-only window and cannot be enumerated
# from another process (EnumChildWindows(HWND_MESSAGE) and
# FindWindowEx(HWND_MESSAGE, ...) both come back empty), so the only
# trustworthy check is a real mouse click on the real notification-area icon.
#
# Flow:
#   1. start the app, wait for "tray ready" in the startup log
#   2. open the notification-area overflow flyout (the chevron is a UIA button)
#   3. find the actlog icon in the flyout by its tooltip
#   4. LEFT click it   -> the window must hide
#   5. RIGHT click it  -> the context menu (#32768) must appear with
#                         "show window" / "hide to tray" / "quit"
#   6. click "show window" with the mouse -> the hidden window must come back
#
# ASCII only. Chinese literals are built from char codes.

param(
    [string]$ExePath = '',
    [int]$WaitSec = 40
)

$ErrorActionPreference = 'Stop'

$ReportDir = 'F:\soft\00selfmade\practilog\.superpowers'
$Report = Join-Path $ReportDir 'tray_interaction_report.txt'
. (Join-Path $PSScriptRoot 'data_location.ps1')   # new userdata first, legacy %APPDATA% fallback
if ([string]::IsNullOrWhiteSpace($ExePath)) {
    $ExePath = Resolve-ActLogExePath
}
$LogFile = Resolve-ActLogLogFile -FileName 'actlog_startup.log' -ExePath $ExePath
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

$lines = New-Object System.Collections.Generic.List[string]
function Say([string]$s) {
    $script:lines.Add($s)
    Write-Output $s
}

# ---- constants ----
$MN_GETHMENU = 0x01E1
$MF_BYPOSITION = 0x0400
$MENU_CLASS = '#32768'
$FLUTTER_CLASS = 'FLUTTER_RUNNER_WIN32_WINDOW'
$MOUSEEVENTF_LEFTDOWN = 0x0002
$MOUSEEVENTF_LEFTUP = 0x0004
$MOUSEEVENTF_RIGHTDOWN = 0x0008
$MOUSEEVENTF_RIGHTUP = 0x0010

# tooltip / menu labels from lib/src/desktop_shell.dart
$TIP = [string]([char]0x77E5) + [char]0x884C + [char]0x65E5 + [char]0x5FD7                  # zhi xing ri zhi
$LABEL_SHOW = [string]([char]0x663E) + [char]0x793A + [char]0x7A97 + [char]0x53E3          # xian shi chuang kou
$LABEL_HIDE = [string]([char]0x9690) + [char]0x85CF + [char]0x5230 + [char]0x6258 + [char]0x76D5
$LABEL_QUIT = [string]([char]0x9000) + [char]0x51FA                                        # tui chu
$CHEVRON_RE = '(\u663E\u793A\u9690\u85CF)|(hidden)|(\u5D4C\u85CF)'
$TITLE_RE = Get-ActLogTitleRegex

if (-not ('TW.Win32' -as [type])) {
    Add-Type -Namespace TW -Name Win32 -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)]
public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string win);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int max);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int max);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
[DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern int GetMenuItemCount(IntPtr menu);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetMenuStringW(IntPtr menu, uint item, System.Text.StringBuilder s, int max, uint flags);
[DllImport("user32.dll")] public static extern bool GetMenuItemRect(IntPtr menu, uint item, out RECT r);
[DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
[DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr extra);
[DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr h);
[DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr ctx);
[DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
[DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
'@
}

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
try { [void][TW.Win32]::SetProcessDpiAwarenessContext([IntPtr](-4)) } catch { }

$auto = [System.Windows.Automation.AutomationElement]
$trueCond = [System.Windows.Automation.Condition]::TrueCondition

function Get-Class([IntPtr]$h) {
    $sb = New-Object System.Text.StringBuilder 256
    [void][TW.Win32]::GetClassName($h, $sb, 256)
    return $sb.ToString()
}
function Get-Title([IntPtr]$h) {
    $sb = New-Object System.Text.StringBuilder 256
    [void][TW.Win32]::GetWindowText($h, $sb, 256)
    return $sb.ToString()
}
function Get-Pid([IntPtr]$h) {
    $p = [uint32]0
    [void][TW.Win32]::GetWindowThreadProcessId($h, [ref]$p)
    return [int]$p
}
function Get-Visible([IntPtr]$h) {
    if ($h -eq [IntPtr]::Zero) { return $false }
    return [bool][TW.Win32]::IsWindowVisible($h)
}
function Get-VisibleTops {
    # The delegate body runs outside the function scope, so the accumulator has
    # to live in the script scope. A local variable is invisible there and
    # "$null.Add(...)" throws "cannot call a method on a null-valued expression".
    $script:visibleTops = New-Object System.Collections.Generic.List[IntPtr]
    $cb = [TW.Win32+EnumProc] {
        param($hh, $ll)
        if ([TW.Win32]::IsWindowVisible($hh)) { $script:visibleTops.Add($hh) }
        return [bool]$true
    }
    [void][TW.Win32]::EnumWindows($cb, [IntPtr]::Zero)
    return $script:visibleTops
}
function Click-Point([int]$x, [int]$y, [bool]$right = $false) {
    [void][TW.Win32]::SetCursorPos($x, $y)
    Start-Sleep -Milliseconds 150
    if ($right) {
        [TW.Win32]::mouse_event($MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, [IntPtr]::Zero)
        Start-Sleep -Milliseconds 60
        [TW.Win32]::mouse_event($MOUSEEVENTF_RIGHTUP, 0, 0, 0, [IntPtr]::Zero)
    } else {
        [TW.Win32]::mouse_event($MOUSEEVENTF_LEFTDOWN, 0, 0, 0, [IntPtr]::Zero)
        Start-Sleep -Milliseconds 60
        [TW.Win32]::mouse_event($MOUSEEVENTF_LEFTUP, 0, 0, 0, [IntPtr]::Zero)
    }
}

# Locate the actlog notification-area icon by its tooltip.
# The Flutter main window carries the very same title, so a match is only
# accepted when the element sits in the notification area (AutomationId) and
# does not overlap that window.
function Find-TrayIcon([string]$name, [IntPtr]$appWin) {
    $aL = 0.0; $aT = 0.0; $aR = 0.0; $aB = 0.0
    if ($appWin -ne [IntPtr]::Zero) {
        $ar = New-Object TW.Win32+RECT
        if ([TW.Win32]::GetWindowRect($appWin, [ref]$ar)) {
            $aL = [double]$ar.Left; $aT = [double]$ar.Top
            $aR = [double]$ar.Right; $aB = [double]$ar.Bottom
        }
    }
    $roots = New-Object 'System.Collections.Generic.List[System.Windows.Automation.AutomationElement]'
    foreach ($h in (Get-VisibleTops)) {
        try { $roots.Add($auto::FromHandle($h)) } catch { }
    }
    try {
        $hTray = [TW.Win32]::FindWindow('Shell_TrayWnd', $null)
        if ($hTray -ne [IntPtr]::Zero) { $roots.Add($auto::FromHandle($hTray)) }
    } catch { }
    foreach ($el in $roots) {
        try {
            $kids = $el.FindAll([System.Windows.Automation.TreeScope]::Descendants, $trueCond)
            foreach ($k in $kids) {
                $n = $k.Current.Name
                if (-not $n) { continue }
                # Accepted tooltip spellings: Chinese product title / actlog /
                # legacy practilog (see Get-ActLogTitleCandidates).
                if (-not (Test-ActLogTitle $n)) { continue }
                $aid = $k.Current.AutomationId
                $rc = $k.Current.BoundingRectangle
                $l = [double]$rc.X; $ty = [double]$rc.Y
                $r = $l + [double]$rc.Width; $b = $ty + [double]$rc.Height
                if ($l -lt $aR -and $r -gt $aL -and $ty -lt $aB -and $b -gt $aT) { continue }
                if ($aid -match 'NotifyItemIcon' -or $aid -eq 'SystemTrayIcon') { return $k }
            }
        } catch { }
    }
    return $null
}

# Fast watcher for the Win32 menu window. Enumerating every top-level window
# from PowerShell costs tens of milliseconds per poll, which is far too slow to
# catch a menu that only lives for a few milliseconds; asking Win32 for the
# menu class directly costs a single call per poll.
# Returns: Hwnd / AppearedAt(ms) / GoneAt(ms) / LifetimeMs(-1 = still open) / Polls
function Measure-Menu([int]$targetPid, [int]$appearMs = 3000, [int]$holdMs = 2500) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $h = [IntPtr]::Zero
    $appearAt = -1
    $goneAt = -1
    $polls = 0
    while ($sw.ElapsedMilliseconds -lt $appearMs) {
        $polls++
        $c = [TW.Win32]::FindWindow($MENU_CLASS, $null)
        if ($c -ne [IntPtr]::Zero -and (Get-Pid $c) -eq $targetPid) {
            $h = $c
            $appearAt = $sw.ElapsedMilliseconds
            break
        }
        Start-Sleep -Milliseconds 2
    }
    if ($h -ne [IntPtr]::Zero) {
        while ($sw.ElapsedMilliseconds -lt ($appearAt + $holdMs)) {
            $polls++
            if (-not [TW.Win32]::IsWindow($h)) { $goneAt = $sw.ElapsedMilliseconds; break }
            Start-Sleep -Milliseconds 2
        }
    }
    $life = -1
    if ($h -ne [IntPtr]::Zero -and $goneAt -ge 0) { $life = $goneAt - $appearAt }
    return [pscustomobject]@{ Hwnd = $h; AppearedAt = $appearAt; GoneAt = $goneAt; LifetimeMs = $life; Polls = $polls }
}

# Locate the tray icon and return its click point, opening the overflow
# flyout when the icon is not in the visible notification area.
function Get-TrayIconPoint {
    $el = Find-TrayIcon $TIP $flutterHwnd
    if ($null -eq $el) {
        [void](Open-Flyout)
        Start-Sleep -Milliseconds 800
        $el = Find-TrayIcon $TIP $flutterHwnd
    }
    if ($null -eq $el) { return $null }
    $r = $el.Current.BoundingRectangle
    return @{ X = [int]($r.X + $r.Width / 2); Y = [int]($r.Y + $r.Height / 2); Name = $el.Current.Name.Trim() }
}

# ---- 0. locked-session guard ----
if (Get-Process LogonUI -ErrorAction SilentlyContinue) {
    Say 'VERDICT = INCONCLUSIVE (session locked: input injection and screen capture are refused)'
    $lines | Set-Content -Path $Report -Encoding UTF8
    return
}
if (-not (Test-Path $ExePath)) {
    Say "VERDICT = FAIL (exe not found: $ExePath)"
    $lines | Set-Content -Path $Report -Encoding UTF8
    return
}

# ---- 1. deterministic start ----
try {
    Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 900
} catch {
    Say "cleanup WARN: $_"
}
$offsetBefore = 0L
if (Test-Path $LogFile) { $offsetBefore = (Get-Item $LogFile).Length }
$proc = Start-Process -FilePath $ExePath -PassThru
Say "app_pid = $($proc.Id)"

function Read-NewLog([int64]$from) {
    if (-not (Test-Path $LogFile)) { return '' }
    $fs = [System.IO.File]::Open($LogFile, [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $null = $fs.Seek($from, [System.IO.SeekOrigin]::Begin)
        $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::UTF8)
        return $sr.ReadToEnd()
    } finally { $fs.Dispose() }
}

$seg = ''
$deadline = (Get-Date).AddSeconds($WaitSec)
while ((Get-Date) -lt $deadline) {
    try { $seg = Read-NewLog $offsetBefore } catch { $seg = '' }
    if ($seg -match 'tray ready' -or $seg -match 'tray FAIL') { break }
    Start-Sleep -Milliseconds 250
}
Say "tray_ready = $($seg -match 'tray ready')"
if ($seg -notmatch 'tray ready') {
    Say "startup segment =`n$($seg.Trim())"
    Say 'VERDICT = FAIL (tray never became ready)'
    $lines | Set-Content -Path $Report -Encoding UTF8
    return
}

# ---- 2. the app's Flutter window ----
$flutterHwnd = [IntPtr]::Zero
foreach ($t in (Get-VisibleTops)) {
    if ((Get-Pid $t) -eq $proc.Id -and (Get-Class $t) -eq $FLUTTER_CLASS) { $flutterHwnd = $t; break }
}
Say "flutter_hwnd = $flutterHwnd title = '$(if ($flutterHwnd -ne [IntPtr]::Zero) { Get-Title $flutterHwnd })'"
if ($flutterHwnd -eq [IntPtr]::Zero) {
    Say 'VERDICT = FAIL (Flutter top-level window not found)'
    $lines | Set-Content -Path $Report -Encoding UTF8
    return
}
$baselineVisible = Get-Visible $flutterHwnd
Say "baseline_visible = $baselineVisible"

# ---- 3. open the notification-area overflow flyout ----
function Open-Flyout {
    $hTray = [TW.Win32]::FindWindow('Shell_TrayWnd', $null)
    if ($hTray -eq [IntPtr]::Zero) { return $null }
    $el = $auto::FromHandle($hTray)
    $btns = $el.FindAll([System.Windows.Automation.TreeScope]::Descendants, $trueCond)
    foreach ($b in $btns) {
        $n = $b.Current.Name
        $aid = $b.Current.AutomationId
        if ($n -and $aid -eq 'SystemTrayIcon' -and $n -match $CHEVRON_RE) {
            $r = $b.Current.BoundingRectangle
            Click-Point ([int]($r.X + $r.Width / 2)) ([int]($r.Y + $r.Height / 2))
            Start-Sleep -Milliseconds 900
            return $b.Current.AutomationId
        }
    }
    return $null
}

$iconEl = Find-TrayIcon $TIP $flutterHwnd
if ($null -eq $iconEl) {
    Say 'tray icon is not in the visible notification area; opening the overflow flyout'
    $chevId = Open-Flyout
    Say "overflow chevron = $chevId"
    $iconEl = Find-TrayIcon $TIP $flutterHwnd
}
if ($null -eq $iconEl) {
    Say '--- overflow panel contents (for diagnosis) ---'
    foreach ($t in (Get-VisibleTops)) {
        try {
            $el = $auto::FromHandle($t)
            $kids = $el.FindAll([System.Windows.Automation.TreeScope]::Descendants, $trueCond)
            foreach ($k in $kids) {
                $n = $k.Current.Name
                $aid = $k.Current.AutomationId
                if ($n -and ($aid -match 'NotifyItemIcon' -or $n -match $TITLE_RE)) {
                    $r = $k.Current.BoundingRectangle
                    Say ("  id='{0}' rect=({1},{2},{3},{4}) name='{5}'" -f $aid,
                        [int]$r.X, [int]$r.Y, [int]$r.Width, [int]$r.Height, $n.Trim())
                }
            }
        } catch { }
    }
    Say "VERDICT = FAIL (the actlog icon was not found in the notification area)"
    $lines | Set-Content -Path $Report -Encoding UTF8
    return
}
$iconRect = $iconEl.Current.BoundingRectangle
$ix = [int]($iconRect.X + $iconRect.Width / 2)
$iy = [int]($iconRect.Y + $iconRect.Height / 2)
Say "tray_icon = '$($iconEl.Current.Name.Trim())' point = $ix,$iy"

# ---- 4. CONTROL EXPERIMENT: right click while the main window is visible ----
# The native side opens the menu from a message-only host window, and
# SetForegroundWindow() cannot promote such a window, so the system may
# dismiss the menu immediately. This control run tells the two causes apart.
Say '--- step 4: right click with the main window still visible (control) ---'
$ctlP = Get-TrayIconPoint
if ($null -eq $ctlP) {
    Say 'VERDICT = FAIL (tray icon not found for the control right click)'
    $lines | Set-Content -Path $Report -Encoding UTF8
    Say 'RESULT = FAIL'
    return
}
Say "control_icon = '$($ctlP.Name)' point = $($ctlP.X),$($ctlP.Y)"
Click-Point $ctlP.X $ctlP.Y $true
$ctl = Measure-Menu $proc.Id 3000 2500
Say "control_menu = hwnd=$($ctl.Hwnd) appeared_at=$($ctl.AppearedAt)ms lifetime=$($ctl.LifetimeMs)ms polls=$($ctl.Polls)"
if ($ctl.Hwnd -ne [IntPtr]::Zero) {
    [void][TW.Win32]::PostMessage($ctl.Hwnd, 0x0100, [IntPtr]0x1B, [IntPtr]::Zero)
    [void][TW.Win32]::PostMessage($ctl.Hwnd, 0x0101, [IntPtr]0x1B, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 900
    Say "control_menu_closed = $(-not [TW.Win32]::IsWindow($ctl.Hwnd))"
}

# ---- 5. LEFT CLICK on the real icon ----
Say '--- step 5: left click on the tray icon ---'
$lp = Get-TrayIconPoint
if ($null -eq $lp) {
    Say 'VERDICT = FAIL (tray icon not found for the left click)'
    $lines | Set-Content -Path $Report -Encoding UTF8
    Say 'RESULT = FAIL'
    return
}
$logMark = (Get-Item $LogFile).Length
Click-Point $lp.X $lp.Y $false
$hidden = $false
$end = (Get-Date).AddSeconds(8)
while ((Get-Date) -lt $end) {
    if (-not (Get-Visible $flutterHwnd)) { $hidden = $true; break }
    Start-Sleep -Milliseconds 50
}
$segAfter = Read-NewLog $logMark
Say "left_click_hidden = $hidden (visible now = $(Get-Visible $flutterHwnd))"
Say "left_click_log = $(($segAfter -split "`n" | Where-Object { $_ -match 'tray' }) -join ' | ')"
if (-not $hidden) {
    Say 'VERDICT = FAIL (left click on the tray icon did not hide the window)'
    $lines | Set-Content -Path $Report -Encoding UTF8
    Say 'RESULT = FAIL'
    return
}

# ---- 6. RIGHT CLICK on the real icon (main window hidden): the menu must appear ----
Say '--- step 6: right click on the tray icon (window hidden) ---'
$rp = Get-TrayIconPoint
if ($null -eq $rp) {
    Say 'VERDICT = FAIL (the tray icon disappeared before the right click)'
    $lines | Set-Content -Path $Report -Encoding UTF8
    Say 'RESULT = FAIL'
    return
}
$logMark = (Get-Item $LogFile).Length
Click-Point $rp.X $rp.Y $true

$meas = Measure-Menu $proc.Id 3000 2500
$menuWnd = $meas.Hwnd
$menuHits = New-Object System.Collections.Generic.List[string]
if ($menuWnd -ne [IntPtr]::Zero) { $menuHits.Add("h$menuWnd") }
Say "menu_window = $menuWnd appeared_at=$($meas.AppearedAt)ms lifetime=$($meas.LifetimeMs)ms polls=$($meas.Polls)"
if ($menuWnd -eq [IntPtr]::Zero) {
    Say "VERDICT = FAIL (no context menu window (#32768) appeared after the right click)"
    $lines | Set-Content -Path $Report -Encoding UTF8
    Say 'RESULT = FAIL'
    return
}

$hMenu = [TW.Win32]::SendMessage($menuWnd, $MN_GETHMENU, [IntPtr]::Zero, [IntPtr]::Zero)
$itemCount = [TW.Win32]::GetMenuItemCount($hMenu)
Say "hmenu = $hMenu items = $itemCount"
$showIndex = -1
$labels = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $itemCount; $i++) {
    $sb = New-Object System.Text.StringBuilder 256
    [void][TW.Win32]::GetMenuStringW($hMenu, [uint32]$i, $sb, 256, $MF_BYPOSITION)
    $label = $sb.ToString()
    $labels.Add($label)
    if ($label.Trim() -eq $LABEL_SHOW) { $showIndex = $i }
}
if ($showIndex -lt 0) {
    Say "VERDICT = FAIL (the context menu has no '$LABEL_SHOW' item)"
    $lines | Set-Content -Path $Report -Encoding UTF8
    Say 'RESULT = FAIL'
    return
}
for ($i = 0; $i -lt $itemCount; $i++) { Say "  item[$i] = '$($labels[$i])'" }

# ---- 7. click 'show window' -> the hidden window must come back ----
# GetMenuItemRect() with an HMENU returns an all-zero rectangle for a popup
# menu, so the item position is resolved in three steps: the menu window
# handle, then UIA on the menu window, then a geometric estimate.
$rcMenu = New-Object TW.Win32+RECT
[void][TW.Win32]::GetWindowRect($menuWnd, [ref]$rcMenu)
$rcItem = New-Object TW.Win32+RECT
[void][TW.Win32]::GetMenuItemRect($menuWnd, [uint32]$showIndex, [ref]$rcItem)
$kind = 'GetMenuItemRect(menuWnd)'
if ($rcItem.Right -le $rcItem.Left -or $rcItem.Bottom -le $rcItem.Top) {
    $kind = 'uia'
    try {
        $mel = $auto::FromHandle($menuWnd)
        $mkids = $mel.FindAll([System.Windows.Automation.TreeScope]::Descendants, $trueCond)
        foreach ($k in $mkids) {
            $kn = $k.Current.Name
            if ($kn -and $kn.Trim() -eq $LABEL_SHOW) {
                $br = $k.Current.BoundingRectangle
                $rcItem.Left = [int]$br.X
                $rcItem.Top = [int]$br.Y
                $rcItem.Right = [int]($br.X + $br.Width)
                $rcItem.Bottom = [int]($br.Y + $br.Height)
                break
            }
        }
    } catch { }
}
if ($rcItem.Right -le $rcItem.Left -or $rcItem.Bottom -le $rcItem.Top) {
    $kind = 'geometric'
    $ih = ($rcMenu.Bottom - $rcMenu.Top) / [double]$itemCount
    $rcItem.Left = $rcMenu.Left
    $rcItem.Right = $rcMenu.Right
    $rcItem.Top = [int]($rcMenu.Top + $ih * $showIndex)
    $rcItem.Bottom = [int]($rcMenu.Top + $ih * ($showIndex + 1))
}
$pickX = [int](($rcItem.Left + $rcItem.Right) / 2)
$pickY = [int](($rcItem.Top + $rcItem.Bottom) / 2)
Say "menu_rect = $($rcMenu.Left),$($rcMenu.Top),$($rcMenu.Right),$($rcMenu.Bottom) item_rect = $($rcItem.Left),$($rcItem.Top),$($rcItem.Right),$($rcItem.Bottom) click = $pickX,$pickY ($kind)"
Click-Point $pickX $pickY $false

$restored = $false
$end = (Get-Date).AddSeconds(10)
while ((Get-Date) -lt $end) {
    if (Get-Visible $flutterHwnd) { $restored = $true; break }
    Start-Sleep -Milliseconds 50
}
$segAfter = Read-NewLog $logMark
Say "show_window_restored = $restored (visible now = $(Get-Visible $flutterHwnd))"
Say "menu_log = $(($segAfter -split "`n" | Where-Object { $_ -match 'tray' }) -join ' | ')"

# ---- 7. did a second menu pop up after the first closed? ----
Start-Sleep -Milliseconds 2000
$late = 0
foreach ($t in (Get-VisibleTops)) {
    if ((Get-Class $t) -eq $MENU_CLASS -and (Get-Pid $t) -eq $proc.Id) { $late++ }
}
Say "menu_windows_seen = $($menuHits.Count) still_open = $late"

$verdict = if ($restored) { 'PASS' } else { 'FAIL' }
Say "VERDICT = $verdict"
Say "RESULT = $verdict"
$lines | Set-Content -Path $Report -Encoding UTF8
Say "report = $Report"
