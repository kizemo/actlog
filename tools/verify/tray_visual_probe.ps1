# tray_visual_probe.ps1 - launch actlog, open Win11 tray overflow flyout, screenshot it.
# ASCII only. Evidence: does the tray icon exist and what does it look like.
$ErrorActionPreference = 'Continue'
$desk = 'F:\soft\00selfmade\practilog\apps\desktop'
. (Join-Path $PSScriptRoot 'data_location.ps1')   # new userdata first, legacy %APPDATA% fallback
$exe = Resolve-ActLogExePath
if (-not $exe) { $exe = Join-Path $desk 'build\windows\x64\runner\Release\actlog.exe' }
$log = Resolve-ActLogLogFile -FileName 'actlog_startup.log' -ExePath $exe
$shot = Join-Path $env:TEMP 'tray_flyout_shot.png'

if (Get-Process -Name LogonUI -ErrorAction SilentlyContinue) {
    Write-Output 'PROBE: SKIP - session locked, UI capture/injection silently fails'
    exit 2
}

# fresh process (current name and legacy name)
Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 300
$before = 0
if (Test-Path $log) { $before = (Get-Item $log).Length }
Start-Process -FilePath $exe | Out-Null

# wait for tray ready in the NEW part of the startup log
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 500
    if (Test-Path $log) {
        $fs = [System.IO.File]::Open($log, 'Open', 'Read', 'ReadWrite')
        try {
            $fs.Seek($before, [System.IO.SeekOrigin]::Begin) | Out-Null
            $sr = New-Object System.IO.StreamReader($fs)
            $tail = $sr.ReadToEnd()
            $sr.Dispose()
        } finally { $fs.Dispose() }
        if ($tail -match 'tray ready') { $ready = $true; break }
    }
}
Write-Output ("PROBE: tray ready = {0}" -f $ready)
if (-not $ready) { Write-Output ("PROBE: new log tail:`n{0}" -f $tail); }

# UIA: find the "show hidden icons" chevron and invoke it
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindow(string c, string n);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
    [StructLayout(LayoutKind.Sequential)] public struct R { public int L,T,Rt,B; }
}
"@
$btnCond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
    [System.Windows.Automation.ControlType]::Button)
$hTray = [W]::FindWindow('Shell_TrayWnd', $null)
if ($hTray -eq [IntPtr]::Zero) {
    Write-Output 'PROBE: FAIL - Shell_TrayWnd hwnd not found'
    Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue | Stop-Process -Force
    exit 1
}
$tray = [System.Windows.Automation.AutomationElement]::FromHandle($hTray)
if (-not $tray) {
    Write-Output 'PROBE: FAIL - UIA FromHandle returned null'
    Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue | Stop-Process -Force
    exit 1
}
$btns = $tray.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
$chev = $null
foreach ($b in $btns) {
    $n = $b.Current.Name
    if ($n -match 'B\)?\s*$' -or $n -match ([char]0x663E + '|' + [char]0x9690) -or $n -match 'hidden' -or $n -match 'chevron') {
        # localized names: zh contains the show/hide chevron wording; en contains hidden icons
        $chev = $b; break
    }
}
if (-not $chev) {
    # dump candidate button names for diagnosis
    $names = @($btns | ForEach-Object { $_.Current.Name }) -join ' | '
    Write-Output ("PROBE: chevron not matched. buttons: {0}" -f $names)
    exit 1
}
Write-Output ("PROBE: chevron = [{0}]" -f $chev.Current.Name)
try {
    $inv = $chev.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
    $inv.Invoke()
} catch {
    $rect = $chev.Current.BoundingRectangle
    Write-Output ("PROBE: invoke failed ({0}), clicking at {1},{2}" -f $_.Exception.Message, $rect.X + $rect.Width/2, $rect.Y + $rect.Height/2)
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point([int]($rect.X + $rect.Width/2), [int]($rect.Y + $rect.Height/2))
    Start-Sleep -Milliseconds 200
    [System.Windows.Forms.SendKeys]::SendWait(' ')
}
Start-Sleep -Milliseconds 800

# capture the overflow flyout window if present, else full virtual desktop
$hFly = [W]::FindWindow('TopLevelWindowForOverflowXamlIsland', $null)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width, [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$g.Dispose()
$bmp.Save($shot, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output ("PROBE: flyout hwnd = {0}; screenshot -> {1}" -f $hFly, $shot)

# close flyout then quit app
Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Output 'PROBE: DONE'
exit 0
