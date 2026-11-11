# dump_host_window.ps1 -- diagnose the message-only tray host window.
#
# The tray callback goes to a message-only window (class "NativeApiHostWindow",
# parent HWND_MESSAGE). Message-only windows are invisible to EnumWindows and
# EnumChildWindows, so this script looks for it three ways and also checks the
# built binary for the literal class name.
#
# ASCII only.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'data_location.ps1')
$ExePath = Resolve-ActLogExePath
$out = New-Object System.Collections.Generic.List[string]
function Say([string]$s) { $script:out.Add($s); Write-Output $s }

if (-not ('TW.Win32' -as [type])) {
    Add-Type -Namespace TW -Name Win32 -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)]
public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr child, string cls, string win);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
[DllImport("user32.dll")] public static extern bool EnumThreadWindows(uint tid, EnumProc cb, IntPtr lParam);
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int max);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int max);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
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
function Get-Pid([IntPtr]$h) {
    $p = [uint32]0
    [void][TW.Win32]::GetWindowThreadProcessId($h, [ref]$p)
    return [int]$p
}

$proc = Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { Say 'actlog is not running'; exit 1 }
Say "pid = $($proc.Id)"

Say '--- 1. EnumThreadWindows over every thread of the process ---'
foreach ($th in $proc.Threads) {
    $script:rows = New-Object System.Collections.Generic.List[string]
    $cb = [TW.Win32+EnumProc] {
        param($hh, $ll)
        $script:rows.Add("      hwnd=$hh class='$(Get-Class $hh)' title='$(Get-Title $hh)' visible=$([TW.Win32]::IsWindowVisible($hh))")
        return $true
    }
    [void][TW.Win32]::EnumThreadWindows([uint32]$th.Id, $cb, [IntPtr]::Zero)
    Say "  tid=$($th.Id) windows=$($script:rows.Count)"
    foreach ($r in $script:rows) { Say $r }
}

Say '--- 2. FindWindowEx with HWND_MESSAGE parent (-3) ---'
foreach ($cls in @('NativeApiHostWindow', 'NativeApi Host', 'FLUTTER_RUNNER_WIN32_WINDOW')) {
    $h = [TW.Win32]::FindWindowEx([IntPtr](-3), [IntPtr]::Zero, $cls, $null)
    Say "  FindWindowEx(HWND_MESSAGE, '$cls') = $h"
    if ($h -ne [IntPtr]::Zero) { Say "    pid=$(Get-Pid $h) title='$(Get-Title $h)'" }
}
$h2 = [TW.Win32]::FindWindowEx([IntPtr]::Zero, [IntPtr]::Zero, 'NativeApiHostWindow', 'NativeApi Host')
Say "  FindWindowEx(NULL, 'NativeApiHostWindow', 'NativeApi Host') = $h2"

Say '--- 3. class name inside the built binary ---'
if (Test-Path $ExePath) {
    $bytes = [System.IO.File]::ReadAllBytes($ExePath)
    $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
    $uni = [System.Text.Encoding]::Unicode.GetString($bytes)
    foreach ($needle in @('NativeApiHostWindow', 'NativeAPITaskbarRestartWatcher', 'NativeApi Host')) {
        Say "  '$needle' : ascii=$($ascii.Contains($needle)) utf16=$($uni.Contains($needle))"
    }
}

Say '--- 4. all top-level windows of the process via EnumWindows ---'
$tops = New-Object System.Collections.Generic.List[IntPtr]
$cb2 = [TW.Win32+EnumProc] {
    param($hh, $ll)
    if ((Get-Pid $hh) -eq $script:proc.Id) { $script:tops.Add($hh) }
    return $true
}
[void][TW.Win32]::EnumWindows($cb2, [IntPtr]::Zero)
Say "  top-level count = $($tops.Count)"
foreach ($t in $tops) { Say "    hwnd=$t class='$(Get-Class $t)' title='$(Get-Title $t)'" }

$rep = 'F:\soft\00selfmade\practilog\.superpowers\dump_host_window.txt'
$out | Set-Content -Path $rep -Encoding UTF8
Say "report = $rep"
