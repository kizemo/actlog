# dump_host_window2.ps1 -- decisive probe for the message-only tray host window.
#
# 1. which binary carries the cnativeapi C++ (the class names are not in the exe)?
# 2. can message-only windows be enumerated at all from another process?
#
# ASCII only.

$ErrorActionPreference = 'Stop'
$ReleaseDir = 'F:\soft\00selfmade\practilog\apps\desktop\build\windows\x64\runner\Release'
. (Join-Path $PSScriptRoot 'data_location.ps1')
$out = New-Object System.Collections.Generic.List[string]
function Say([string]$s) { $script:out.Add($s); Write-Output $s }

if (-not ('TW.Win32' -as [type])) {
    Add-Type -Namespace TW -Name Win32 -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)]
public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr child, string cls, string win);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr parent, EnumProc cb, IntPtr lParam);
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int max);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int max);
[DllImport("user32.dll")] public static extern IntPtr GetParent(IntPtr h);
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

Say '--- 1. which binary carries the cnativeapi class names ---'
$needles = @('NativeApiHostWindow', 'NativeApi Host', 'NativeAPITaskbarRestartWatcher')
$files = @(Get-ChildItem -Path $ReleaseDir -File | Where-Object { $_.Extension -in @('.dll', '.exe') })
foreach ($f in $files) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
        $uni = [System.Text.Encoding]::Unicode.GetString($bytes)
        $hits = @()
        foreach ($n in $needles) {
            if ($ascii.Contains($n)) { $hits += "$n/ascii" }
            if ($uni.Contains($n)) { $hits += "$n/utf16" }
        }
        if ($hits.Count -gt 0) {
            Say ("  {0,-40} {1}" -f $f.Name, ($hits -join ', '))
        }
    } catch {
        Say ("  {0,-40} READ FAIL: {1}" -f $f.Name, $_.Exception.Message)
    }
}
Say '  (files scanned: ' + $files.Count + ')'

Say '--- 2. message-only enumeration attempts ---'
$proc = Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { Say '  actlog is not running' } else {
    Say "  target pid = $($proc.Id)"

    $script:mo = New-Object System.Collections.Generic.List[string]
    $cbChild = [TW.Win32+EnumProc] {
        param($hh, $ll)
        $script:mo.Add("EnumChildWindows(HWND_MESSAGE): hwnd=$hh class='$(Get-Class $hh)' title='$(Get-Title $hh)' pid=$(Get-Pid $hh)")
        return $true
    }
    [void][TW.Win32]::EnumChildWindows([IntPtr](-3), $cbChild, [IntPtr]::Zero)
    Say "  EnumChildWindows(HWND_MESSAGE) count = $($script:mo.Count)"
    foreach ($m in $script:mo) { Say "    $m" }

    foreach ($cls in @('NativeApiHostWindow', 'NativeApi Host')) {
        $h = [TW.Win32]::FindWindowEx([IntPtr](-3), [IntPtr]::Zero, $cls, $null)
        Say "  FindWindowEx(HWND_MESSAGE,'$cls') = $h"
        $h2 = [TW.Win32]::FindWindowEx([IntPtr](-3), [IntPtr]::Zero, $cls, 'NativeApi Host')
        Say "  FindWindowEx(HWND_MESSAGE,'$cls','NativeApi Host') = $h2"
    }
    $h3 = [TW.Win32]::FindWindowEx([IntPtr](-3), [IntPtr]::Zero, $null, 'NativeApi Host')
    Say "  FindWindowEx(HWND_MESSAGE,NULL,'NativeApi Host') = $h3"

    # every window on the desktop whose parent is HWND_MESSAGE
    $script:orphans = New-Object System.Collections.Generic.List[string]
    $cbAll = [TW.Win32+EnumProc] {
        param($hh, $ll)
        if ([TW.Win32]::GetParent($hh) -eq [IntPtr](-3)) {
            $script:orphans.Add("hwnd=$hh class='$(Get-Class $hh)' title='$(Get-Title $hh)' pid=$(Get-Pid $hh)")
        }
        return $true
    }
    [void][TW.Win32]::EnumWindows($cbAll, [IntPtr]::Zero)
    Say "  desktop windows with parent HWND_MESSAGE = $($script:orphans.Count)"
    foreach ($o in $script:orphans) { Say "    $o" }
}

$rep = 'F:\soft\00selfmade\practilog\.superpowers\dump_host_window2.txt'
$out | Set-Content -Path $rep -Encoding UTF8
Say "report = $rep"
