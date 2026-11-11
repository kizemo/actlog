# actlog - dump every window that belongs to the running app process.
# Diagnostic helper: tells us which window classes/ids the tray callback
# message should be delivered to. ASCII only.
param(
  [string]$ProcessName = ''
)
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'data_location.ps1')

Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class PLDump {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumThreadWindows(uint tid, EnumWindowsProc cb, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr parent, EnumWindowsProc cb, IntPtr lParam);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr hWnd, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr hWnd, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindowExW(IntPtr parent, IntPtr after, string cls, string win);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    public static IntPtr HWND_MESSAGE { get { return (IntPtr)(-3); } }
    public static string ClassOf(IntPtr h) { var sb = new StringBuilder(256); GetClassNameW(h, sb, 256); return sb.ToString(); }
    public static string TextOf(IntPtr h) { var sb = new StringBuilder(512); GetWindowTextW(h, sb, 512); return sb.ToString(); }
    public static uint PidOf(IntPtr h) { uint p; GetWindowThreadProcessId(h, out p); return p; }
}
'@

$proc = $null
if ([string]::IsNullOrWhiteSpace($ProcessName)) {
    # current process name first, legacy name second
    foreach ($n in (Get-ActLogProcessNames)) {
        foreach ($p in [System.Diagnostics.Process]::GetProcessesByName($n)) { $proc = $p; break }
        if ($proc) { break }
    }
} else {
    foreach ($p in [System.Diagnostics.Process]::GetProcessesByName($ProcessName)) { $proc = $p; break }
}
if (-not $proc) { "process not running"; exit 2 }
$pid2 = [uint32]$proc.Id
"pid = $pid2"

'--- EnumWindows (top level, all processes) filtered by pid ---'
$script:rows = New-Object System.Collections.Generic.List[string]
$cb = [PLDump+EnumWindowsProc]{
  param($h, $l)
  if ([PLDump]::PidOf($h) -eq $pid2) {
    $script:rows.Add(("hwnd=" + $h.ToInt64() + " class=" + [PLDump]::ClassOf($h) + " text='" + [PLDump]::TextOf($h) + "' visible=" + [PLDump]::IsWindowVisible($h)))
  }
  return $true
}
[void][PLDump]::EnumWindows($cb, [IntPtr]::Zero)
foreach ($r in $script:rows) { $r }

'--- EnumThreadWindows per thread of the process ---'
$script:rows2 = New-Object System.Collections.Generic.List[string]
foreach ($th in $proc.Threads) {
  $cb2 = [PLDump+EnumWindowsProc]{
    param($h, $l)
    $script:rows2.Add(("tid=" + $th.Id + " hwnd=" + $h.ToInt64() + " class=" + [PLDump]::ClassOf($h) + " text='" + [PLDump]::TextOf($h) + "' visible=" + [PLDump]::IsWindowVisible($h)))
    return $true
  }
  [void][PLDump]::EnumThreadWindows([uint32]$th.Id, $cb2, [IntPtr]::Zero)
}
foreach ($r in $script:rows2) { $r }

'--- EnumChildWindows of every top level window of the process ---'
$script:childRows = New-Object System.Collections.Generic.List[string]
$cb3 = [PLDump+EnumWindowsProc]{
  param($h, $l)
  if ([PLDump]::PidOf($h) -eq $pid2) {
    $script:childRows.Add(("parent=" + $h.ToInt64() + " class=" + [PLDump]::ClassOf($h)))
    $cbChild = [PLDump+EnumWindowsProc]{
      param($c, $l2)
      $script:childRows.Add(("  child=" + $c.ToInt64() + " class=" + [PLDump]::ClassOf($c) + " text='" + [PLDump]::TextOf($c) + "'"))
      return $true
    }
    [void][PLDump]::EnumChildWindows($h, $cbChild, [IntPtr]::Zero)
  }
  return $true
}
[void][PLDump]::EnumWindows($cb3, [IntPtr]::Zero)
foreach ($r in $script:childRows) { $r }

'--- FindWindowEx(HWND_MESSAGE, ...) probes ---'
foreach ($cls in 'NativeApiHostWindow', 'NativeApiHost', 'FLUTTER_RUNNER_WIN32_WINDOW', '') {
    $after = [IntPtr]::Zero
    for ($i = 0; $i -lt 16; $i++) {
        $h = [PLDump]::FindWindowExW([PLDump]::HWND_MESSAGE, $after, $cls, $null)
        if ($h -eq [IntPtr]::Zero) { break }
        "msgonly class='" + $cls + "' hwnd=" + $h.ToInt64() + " realClass=" + [PLDump]::ClassOf($h) + " pid=" + [PLDump]::PidOf($h) + " text='" + [PLDump]::TextOf($h) + "'"
        $after = $h
    }
}
foreach ($txt in 'NativeApi Host', 'NativeApiHostWindow') {
    $after = [IntPtr]::Zero
    for ($i = 0; $i -lt 16; $i++) {
        $h = [PLDump]::FindWindowExW([PLDump]::HWND_MESSAGE, $after, $null, $txt)
        if ($h -eq [IntPtr]::Zero) { break }
        "msgonly title='" + $txt + "' hwnd=" + $h.ToInt64() + " realClass=" + [PLDump]::ClassOf($h) + " pid=" + [PLDump]::PidOf($h)
        $after = $h
    }
}
