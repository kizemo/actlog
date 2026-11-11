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

. (Join-Path $PSScriptRoot 'data_location.ps1')

$Target = [string]([char]0x77E5) + [char]0x884C + [char]0x65E5 + [char]0x5FD7   # zhi xing ri zhi
Say "target tooltip = '$Target'"

$auto = [System.Windows.Automation.AutomationElement]
$trueCond = [System.Windows.Automation.Condition]::TrueCondition
# Any accepted title spelling counts as a hit.
$titleConds = New-Object 'System.Collections.Generic.List[System.Windows.Automation.Condition]'
foreach ($c in (Get-ActLogTitleCandidates)) {
    $titleConds.Add((New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::NameProperty, $c)))
}
$nameCond = New-Object System.Windows.Automation.OrCondition($titleConds.ToArray())

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
        Say ("    {0,-22} id='{1}' rect=({2},{3},{4},{5}) name='{6}'" -f `
            $e.Current.ControlType.ProgrammaticName.Replace('ControlType.', ''), `
            $e.Current.AutomationId, [int]$r.X, [int]$r.Y, [int]$r.Width, [int]$r.Height, $name)
        $n++
        if ($n -ge 60) { Say '    ... truncated'; break }
    }
    $hit = $el.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $nameCond)
    Say "  taskbar hit for tooltip = $(if ($hit) { $hit.Current.BoundingRectangle.ToString() } else { 'NOT FOUND' })"
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
        $hit = $el.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $nameCond)
        if ($hit) {
            $r = $hit.Current.BoundingRectangle
            Say "  HIT  hwnd=$t class='$cls' title='$ttl' rect=($([int]$r.X),$([int]$r.Y),$([int]$r.Width),$([int]$r.Height))"
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

$rep = 'F:\soft\00selfmade\practilog\.superpowers\uia_find_tray.txt'
$out | Set-Content -Path $rep -Encoding UTF8
Say "report = $rep"
