# tray_alive_check.ps1 -- verify the tray icon is visible WHILE keeping the app alive.
# Unlike tray_visual_probe.ps1 this script does NOT kill the process at the end,
# because a killed process is exactly what makes the tray icon disappear.
#
# Usage:
#   pwsh -NoProfile -ExecutionPolicy Bypass -File tools/verify/tray_alive_check.ps1 [-ExePath <path>] [-Kill]
#
# Assertions produced (all written to .superpowers/tray_alive_check.txt):
#   A1 process alive after start
#   A2 'tray ready' present in the log segment created by THIS start
#   A3 overflow flyout contains an item whose UIA Name is the app title
#      (the Chinese product title, or the ASCII product name -- both accepted)
#   A4 screenshot evidence path
# ASCII only. Chinese literals are built from char codes to stay ASCII.

param(
    [string]$ExePath = '',
    [switch]$Kill
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'data_location.ps1')      # new userdata first, legacy %APPDATA% fallback

# The tooltip / app title candidates (Chinese product title, actlog, practilog).
$Target = [string]([char]0x77E5) + [char]0x884C + [char]0x65E5 + [char]0x5FD7   # zhi-xing-ri-zhi
$HiddenBtnRegex = '([char]0x663E)|([char]0x9690)|hidden'
$HiddenBtnRegex = "(?i)$([char]0x663E)|$([char]0x9690)|hidden"   # xian / yin / hidden

if ([string]::IsNullOrWhiteSpace($ExePath)) {
    $ExePath = Resolve-ActLogExePath
}
$LogDir = (Resolve-ActLogDataDir -ExePath $ExePath).Path
$LogFile = Resolve-ActLogLogFile -FileName 'actlog_startup.log' -ExePath $ExePath
$ReportDir = 'F:\soft\00selfmade\practilog\.superpowers'
$Shot = Join-Path $env:TEMP 'tray_alive_shot.png'
$Report = Join-Path $ReportDir 'tray_alive_check.txt'
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

$lines = @()
function Say([string]$s) {
    $script:lines += $s
    Write-Output $s
}

Say "target-name = $Target"
Say "exe         = $ExePath"

# ---- 0. locked-session guard: UI automation silently fails when LogonUI runs ----
$lock = Get-Process LogonUI -ErrorAction SilentlyContinue
if ($lock) {
    Say 'VERDICT = INCONCLUSIVE (session locked: input injection and screen capture are refused)'
    $lines | Set-Content -Path $Report -Encoding UTF8
    return
}
if (-not (Test-Path $ExePath)) {
    Say "VERDICT = FAIL (exe not found: $ExePath)"
    $lines | Set-Content -Path $Report -Encoding UTF8
    return
}

# ---- 1. remember the log size so we only judge THIS start ----
$offsetBefore = 0L
if (Test-Path $LogFile) { $offsetBefore = (Get-Item $LogFile).Length }
Say "log-offset-before = $offsetBefore"

# ---- 2. start the app ----
$proc = Start-Process -FilePath $ExePath -PassThru
Say "started-pid = $($proc.Id)"

# ---- 3. wait for 'tray ready' in the new segment ----
function Read-NewLog([int64]$from) {
    $fs = [System.IO.File]::Open($LogFile, [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $null = $fs.Seek($from, [System.IO.SeekOrigin]::Begin)
        $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::UTF8)
        return $sr.ReadToEnd()
    } finally { $fs.Dispose() }
}

$seg = ''
$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline) {
    if (Test-Path $LogFile) {
        try { $seg = Read-NewLog $offsetBefore } catch { $seg = '' }
        if ($seg -match 'tray ready' -or $seg -match 'tray FAIL') { break }
    }
    Start-Sleep -Milliseconds 250
}
$alive = Get-Process -Id $proc.Id -ErrorAction SilentlyContinue
Say "A1 process-alive = $([bool]$alive)"
Say "A2 new-segment-lines = $(($seg -split "`n" | Where-Object { $_.Trim() }).Count)"
if ($seg -match 'tray FAIL(.*)') { Say "A2 = FAIL  tray init error: $($matches[1].Trim())" }
elseif ($seg -match 'tray ready') { Say 'A2 = PASS  tray ready logged' }
else { Say 'A2 = UNKNOWN (no tray line within 30s)' }
Say "A2 segment =`n$($seg.Trim())"

# ---- 4. open the hidden-icons flyout through UI Automation ----
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
if (-not ('TW.Win32' -as [type])) {
    Add-Type -Namespace TW -Name Win32 -MemberDefinition @'
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern System.IntPtr FindWindow(string cls, string win);
public delegate bool EnumProc(System.IntPtr hWnd, System.IntPtr lParam);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, System.IntPtr lParam);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(System.IntPtr hWnd);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(System.IntPtr hWnd, System.Text.StringBuilder s, int max);
'@
}

$auto = [System.Windows.Automation.AutomationElement]
$condAll = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
    [System.Windows.Automation.ControlType]::Button)

$clicked = $false
$hTray = [TW.Win32]::FindWindow('Shell_TrayWnd', $null)
if ($hTray -ne [System.IntPtr]::Zero) {
    try {
        $trayEl = $auto::FromHandle($hTray)
        $btns = $trayEl.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condAll)
        foreach ($b in $btns) {
            if ($b.Current.Name -match $HiddenBtnRegex) {
                $pat = $b.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
                $pat.Invoke()
                $clicked = $true
                Say "overflow-button = '$($b.Current.Name)' invoked"
                break
            }
        }
    } catch { Say "overflow-button FAIL: $_" }
}
if (-not $clicked) { Say 'overflow-button = NOT FOUND (icon may already be pinned on the taskbar)' }
Start-Sleep -Milliseconds 1200

# ---- 5. look for the tooltip name inside any top-level window ----
$found = @()
$winCond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
    [System.Windows.Automation.ControlType]::Window)
# Any accepted title spelling counts: the Chinese product title, actlog, or the
# legacy practilog. One UIA OrCondition covers all three.
$titleConds = New-Object 'System.Collections.Generic.List[System.Windows.Automation.Condition]'
foreach ($c in (Get-ActLogTitleCandidates)) {
    $titleConds.Add((New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::NameProperty, $c)))
}
$nameCond = New-Object System.Windows.Automation.OrCondition($titleConds.ToArray())
$handles = New-Object System.Collections.Generic.List[System.IntPtr]
$cb = [TW.Win32+EnumProc] { param($h, $l) if ([TW.Win32]::IsWindowVisible($h)) { [void]$script:handles.Add($h) }; return $true }
[void][TW.Win32]::EnumWindows($cb, [IntPtr]::Zero)
Say "candidate-top-levels = $($handles.Count)"
foreach ($h in $handles) {
    try {
        $el = $auto::FromHandle($h)
        $hit = $el.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $nameCond)
        if ($null -ne $hit) {
            $cls = New-Object System.Text.StringBuilder 256
            [void][TW.Win32]::GetClassName($h, $cls, 256)
            $found += "$($cls.ToString()) | $($hit.Current.ControlType.ProgrammaticName) | '$($hit.Current.Name)'"
        }
    } catch { }
}
if ($found.Count -gt 0) {
    Say 'A3 = PASS  tray item found by UIA name'
    $found | ForEach-Object { Say "   hit: $_" }
} else {
    Say "A3 = NOT FOUND (no element named '$Target' / actlog / practilog in any visible top-level window)"
}

# ---- 6. screenshot the whole virtual desktop ----
$b = [System.Windows.Forms.SystemInformation]::VirtualScreen
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.X, $b.Y, 0, 0, $bmp.Size)
$bmp.Save($Shot, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Say "A4 screenshot = $Shot ($(Get-Item $Shot | Select-Object -Expand Length) bytes, $($b.Width)x$($b.Height))"

# ---- 7. leave the process running on purpose ----
$stillAlive = [bool](Get-Process -Id $proc.Id -ErrorAction SilentlyContinue)
if ($Kill) {
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    Say 'cleanup = process killed (as requested)'
} else {
    Say "cleanup = process LEFT RUNNING (pid $($proc.Id), alive=$stillAlive) so the user can look at the tray"
}

$verdict = if ($stillAlive -and ($seg -match 'tray ready') -and $found.Count -gt 0) { 'PASS' }
           elseif ($stillAlive -and ($seg -match 'tray ready')) { 'PARTIAL (tray ready + alive; UIA name not matched - check the screenshot)' }
           else { 'FAIL' }
Say "VERDICT = $verdict"
$lines | Set-Content -Path $Report -Encoding UTF8
Say "report = $Report"
