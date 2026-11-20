# uia_find_tray.ps1 -- locate the actlog tray icon in the notification area.
#
# The tray callback window is message-only and cannot be enumerated from another
# process, so the only trustworthy check is a real mouse click on the real icon.
# This script maps the notification area with UI Automation and reports every
# named element it can see, so the click target can be derived from evidence.
#
# RENAME (PractiLog -> actlog): the tooltip is matched against every accepted
# spelling (Chinese product title / actlog / legacy practilog).
#
# ASCII only; the Chinese tooltip is built from char codes.

[CmdletBinding()]
param(
    # A3 (round 5): the probe used to depend on whatever actlog instance
    # happened to be running. With -ExePath it resolves, fingerprints and (if
    # nothing is running yet) STARTS that exact binary, so the evidence is tied
    # to a known build. Without -ExePath the old behaviour is unchanged, which
    # is what device self-test control C12 relies on.
    [string]$ExePath = '',
    # D6 (Task 47 W1b): the report used to be written into the planning folder
    # (.superpowers). Callers now pass the evidence directory. The old path
    # stays as the default so existing invocations keep working.
    [string]$ReportDir = 'F:\soft\00selfmade\practilog\.superpowers'
)

$ErrorActionPreference = 'Stop'
$out = New-Object System.Collections.Generic.List[string]
function Say([string]$s) { $script:out.Add($s); Write-Output $s }

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

if (-not ('TW.Win32' -as [type])) {
    Add-Type -Namespace TW -Name Win32 -MemberDefinition @'
public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string win);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int max);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int max);
'@
}

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
# D4 (Task 47 W1b): UIA returns an "infinite" rectangle (X/Y around
# -8.99E+307) for elements it cannot place on screen. Casting that to [int]
# threw InvalidArgument and killed the whole run. Every rect now goes through
# this formatter, which reports the literal word INFINITE instead of throwing,
# so control C12 (CONTROL_UIA_INFINITE_RECT) can grep a stable token.
function Format-Rect($r) {
    try {
        $x = [double]$r.X; $y = [double]$r.Y; $w = [double]$r.Width; $h = [double]$r.Height
        foreach ($v in @($x, $y, $w, $h)) {
            if ([double]::IsNaN($v) -or [double]::IsInfinity($v) -or [math]::Abs($v) -ge 1e9) {
                return 'INFINITE'
            }
        }
        return ('({0},{1},{2},{3})' -f [int]$x, [int]$y, [int]$w, [int]$h)
    } catch {
        return 'INFINITE'
    }
}

. (Join-Path $PSScriptRoot 'data_location.ps1')

$Target = [string]([char]0x77E5) + [char]0x884C + [char]0x65E5 + [char]0x5FD7   # zhi xing ri zhi
Say "target tooltip = '$Target'"

# ---- 0. optional: fingerprint (and start) the build under test --------------
$startedByUs = $false
$startedPid = 0
if (-not [string]::IsNullOrWhiteSpace($ExePath)) {
    if (-not [System.IO.File]::Exists($ExePath)) {
        Say "ERROR exe not found: $ExePath"
        exit 1
    }
    $fi = Get-Item -LiteralPath $ExePath
    $sha = (Get-FileHash -LiteralPath $ExePath -Algorithm SHA256).Hash
    Say "exe_path = $($fi.FullName)"
    Say "exe_size = $($fi.Length)"
    Say "exe_sha256 = $sha"
    Say "exe_sha256_16 = $($sha.Substring(0,16))"
    $alive = @(Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue)
    Say "actlog_pids_before = $(($alive | ForEach-Object { $_.Id }) -join ',')"
    if ($alive.Count -eq 0) {
        $sp = Start-Process -FilePath $fi.FullName -PassThru
        $startedByUs = $true
        $startedPid = $sp.Id
        Say "started_pid = $startedPid"
        # The shipped build shows its window ~0.3s after start and finishes the
        # tray setup right after; 5s covers that plus the title re-localization.
        Start-Sleep -Seconds 5
        $sp.Refresh()
        Say "started_alive = $(-not $sp.HasExited)"
    } else {
        Say 'reused a running instance (this probe never starts a second one)'
    }
}

$auto = [System.Windows.Automation.AutomationElement]
$trueCond = [System.Windows.Automation.Condition]::TrueCondition
# Any accepted title spelling counts as a hit, as a CONTAINS match.
# Task 47 W1b E.2B: UIA has no "Name contains" condition, and the hard
# NameProperty equality condition never matched the real notification-area
# button (observed name: "actlog - 1 running window(s)" in the zh locale), so
# containment is evaluated in PowerShell over the descendants the caller has
# already enumerated.
$titleNames = @(Get-ActLogTitleCandidates)
function Test-NameContains([string]$n) {
    if ([string]::IsNullOrWhiteSpace($n)) { return $false }
    $nn = $n.Trim()
    foreach ($c in $titleNames) {
        if (-not $c) { continue }
        if ($nn.IndexOf($c, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    }
    return $false
}
function Find-TitleHit($el) {
    try {
        $kids = $el.FindAll([System.Windows.Automation.TreeScope]::Descendants, $trueCond)
        foreach ($k in $kids) {
            if (Test-NameContains $k.Current.Name) { return $k }
        }
    } catch { }
    return $null
}
# A3 (round 5): a tray hit is only claimed for the shell surfaces that really
# host notification icons. Any other window that merely mentions the title is
# reported on a 'win' line instead of being called HIT, so the evidence cannot
# be mistaken for "the tray icon was found".
function Test-TrayClass([string]$c) {
    if ($c -eq 'Shell_TrayWnd') { return $true }
    if ($c -like 'TopLevelWindowForOverflowXamlIsland*') { return $true }
    if ($c -like '*NotifyIconOverflowWindow*') { return $true }
    return $false
}

# ---- 1. the taskbar itself ----
$hTray = [TW.Win32]::FindWindow('Shell_TrayWnd', $null)
Say "Shell_TrayWnd = $hTray"
if ($hTray -ne [IntPtr]::Zero) {
    $el = $auto::FromHandle($hTray)
    $all = $el.FindAll([System.Windows.Automation.TreeScope]::Descendants, $trueCond)
    Say "  taskbar descendants = $($all.Count)"
    $n = 0
    foreach ($e in $all) {
        $name = $e.Current.Name
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        $r = $e.Current.BoundingRectangle
        Say ("    {0,-22} id='{1}' rect={2} name='{3}'" -f `
            $e.Current.ControlType.ProgrammaticName.Replace('ControlType.', ''), `
            $e.Current.AutomationId, (Format-Rect $r), $name)
        $n++
        if ($n -ge 200) { Say '    ... truncated'; break }
    }
    # A3 (round 5): report EVERY named element whose name carries an accepted
    # title, with its AutomationId, instead of only the first hit. The taskbar
    # button used to be cut off by the 60-element cap.
    $hitCount = 0
    foreach ($e in $all) {
        if (-not (Test-NameContains $e.Current.Name)) { continue }
        $hitCount++
        Say ("  taskbar hit = name='{0}' automation_id='{1}' class='{2}' rect={3}" -f `
            $e.Current.Name, $e.Current.AutomationId, $e.Current.ClassName, (Format-Rect $e.Current.BoundingRectangle))
    }
    if ($hitCount -eq 0) { Say '  taskbar hit = NOT FOUND' }
}

# ---- 2. every visible top-level window, with its named descendants ----
Say '--- top-level windows (visible) ---'
$tops = New-Object System.Collections.Generic.List[IntPtr]
$cb = [TW.Win32+EnumProc] {
    param($hh, $ll)
    if ([TW.Win32]::IsWindowVisible($hh)) { $script:tops.Add($hh) }
    return $true
}
[void][TW.Win32]::EnumWindows($cb, [IntPtr]::Zero)
Say "  visible top-level count = $($tops.Count)"
foreach ($t in $tops) {
    $cls = Get-Class $t
    $ttl = Get-Title $t
    try {
        $el = $auto::FromHandle($t)
        $hit = Find-TitleHit $el
        if ($hit -and (Test-TrayClass $cls)) {
            Say ("  HIT  hwnd={0} class='{1}' title='{2}' name='{3}' automation_id='{4}' rect={5}" -f `
                $t, $cls, $ttl, $hit.Current.Name, $hit.Current.AutomationId, (Format-Rect $hit.Current.BoundingRectangle))
        } elseif ($hit) {
            Say "  win  hwnd=$t class='$cls' title='$ttl' hitname='$($hit.Current.Name)' (not a tray window class)"
        } else {
            $names = @()
            $kids = $el.FindAll([System.Windows.Automation.TreeScope]::Children, $trueCond)
            foreach ($k in $kids) { if ($k.Current.Name) { $names += $k.Current.Name } }
            if ($names.Count -gt 0) {
                Say "  win  hwnd=$t class='$cls' title='$ttl' children=[$($names -join '; ')]"
            }
        }
    } catch {
        Say "  win  hwnd=$t class='$cls' title='$ttl' (UIA error: $($_.Exception.Message))"
    }
}

if (-not (Test-Path -LiteralPath $ReportDir)) {
    [void](New-Item -ItemType Directory -Path $ReportDir -Force)
}
$rep = Join-Path $ReportDir 'uia_find_tray.txt'
# A3 (round 5): report bytes are written with WriteAllText (UTF-8, no BOM) and
# read back, so a silently truncated report cannot pass as evidence.
Say "report = $rep"
# A3 (round 5): only stop the instance this probe started itself.
if ($startedByUs -and $startedPid -gt 0) {
    try {
        [void](Get-Process -Id $startedPid -ErrorAction Stop)
        Stop-Process -Id $startedPid -Force
        Say "stopped_pid = $startedPid"
    } catch {
        Say "started instance already gone (pid=$startedPid)"
    }
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($rep, ($out -join "`r`n"), $utf8)
Write-Output ("report_bytes = {0}" -f (Get-Item -LiteralPath $rep).Length)
