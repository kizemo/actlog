# task47_aumid_probe.ps1 -- path C for P-2: read the AppUserModelID straight
# from the window property store, instead of asking the tray or the log.
#
# WHY A THIRD PATH (Task 47 W1b round 2, report section F / P-2):
#   paths A (tray icon) and B (UIA on the tray) both go THROUGH the shell, so a
#   failure there cannot say whether the app ever declared its identity. This
#   probe asks the window itself:
#     SHGetPropertyStoreForWindow(hwnd, IID_IPropertyStore, STGM_READ)
#     -> IPropertyStore::GetValue(PKEY_AppUserModel_ID ...)
#   That is the same store the taskbar reads, so it is evidence about what the
#   app declared, not about what the shell decided to show.
#
# CONTROLS ARE MANDATORY AND ALWAYS RUN FIRST:
#   POS_WIN   the fixture sets the id on its own window store and the reader
#             must read it back. If Windows refuses that write, the gate
#             degrades to UNAVAILABLE and the VALUE branch stays UNPROVEN.
#   POS_PROC  the fixture declares a process id; the process reader must see it.
#   NEG       the same fixture with no id at all; both readers must say ABSENT.
#   All three run in separate processes, so they also prove that the read works
#   cross-process, which is the only case that matters here.
#
# The control host is Windows PowerShell 5.1, NOT pwsh: pwsh carries the package
# identity Microsoft.PowerShell_8wekyb3d8bbwe!App, so it can be neither a
# positive nor a negative control for process identity (measured).
#
# KEY NAMES (propkey.h, FMTID 9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3):
#   pid 5 = PKEY_AppUserModel_ID
#   pid 4 = PKEY_AppUserModel_RelaunchDisplayNameResource
#   pid 2 = PKEY_AppUserModel_RelaunchCommand            (side evidence)
#   There is NO PKEY_AppUserModel_RelaunchDisplayName without "Resource" in the
#   Windows SDK, so that key is reported as NOT_A_PKEY instead of inventing a pid.
#
# Output: console plus a report file. ASCII only.
#
# Usage:
#   pwsh -NoProfile -File tools/verify/task47_aumid_probe.ps1
#   pwsh -NoProfile -File tools/verify/task47_aumid_probe.ps1 -ExePath 'D:\Program Files\actlog\actlog.exe'

[CmdletBinding()]
param(
    [string]$ExePath = '',
    [string]$ReportDir = 'F:\soft\00selfmade\practilog\reports\task47-W1b-evidence',
    [string]$Report = '',
    [int]$StartupWaitSec = 20,
    # Read an already running actlog instead of starting one.
    [switch]$SkipStart,
    # SELF-TEST ONLY: point the reader at an unrelated window with a known
    # handle, given in hex. Empty means "use the real target".
    # Named *Hex on purpose: PowerShell variable names are case-insensitive, so
    # a parameter called $TargetHwnd would silently BE the internal $targetHwnd.
    [string]$TargetHwndHex = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'data_location.ps1')

if ([string]::IsNullOrWhiteSpace($Report)) {
    $Report = Join-Path $ReportDir 'aumid_probe.txt'
}
if (-not (Test-Path -LiteralPath $ReportDir)) {
    [void](New-Item -ItemType Directory -Path $ReportDir -Force)
}

$lines = New-Object 'System.Collections.Generic.List[string]'
function Say([string]$s) { $lines.Add($s); Write-Host $s }

$FMTID_AUM = '{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}'

if (-not ('PLAumid' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class PLAumid {
    [StructLayout(LayoutKind.Sequential)]
    public struct PROPERTYKEY { public Guid fmtid; public uint pid; }

    // PROPVARIANT is 24 bytes on x64 and the callee writes all of it: Size is
    // declared explicitly, otherwise the marshaller would pass 16 and the last
    // 8 bytes would land outside the struct.
    [StructLayout(LayoutKind.Explicit, Size = 24)]
    public struct PROPVARIANT {
        [FieldOffset(0)] public ushort vt;
        [FieldOffset(8)] public IntPtr ptr;
    }

    [ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IPropertyStore {
        [PreserveSig] int GetCount(out uint cProps);
        [PreserveSig] int GetAt(uint iProp, out PROPERTYKEY pkey);
        [PreserveSig] int GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
        [PreserveSig] int SetValue(ref PROPERTYKEY key, ref PROPVARIANT pv);
        [PreserveSig] int Commit();
    }

    [DllImport("shell32.dll")]
    public static extern int SHGetPropertyStoreForWindow(IntPtr hwnd, ref Guid iid,
        [MarshalAs(UnmanagedType.Interface)] out IPropertyStore store);

    [DllImport("ole32.dll")]
    public static extern int PropVariantClear(ref PROPVARIANT pv);

    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowTextW(IntPtr hWnd, System.Text.StringBuilder text, int maxCount);

    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int L; public int T; public int R; public int B; }

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

    public static string TitleOf(IntPtr hWnd) {
        var t = new System.Text.StringBuilder(512);
        GetWindowTextW(hWnd, t, 512);
        return t.ToString();
    }

    // Same as FindMainWindow but only for windows that already carry a title. A
    // console host window and a pre-first-frame window have none and are NOT the
    // window whose identity the shell reads (measured: taking the largest
    // visible window returned title=[] and a state the app never set).
    public static IntPtr FindTitledWindow(uint pid) {
        IntPtr best = IntPtr.Zero;
        long bestArea = -1;
        EnumWindows(delegate(IntPtr h, IntPtr l) {
            uint p; GetWindowThreadProcessId(h, out p);
            if (p != pid) return true;
            if (!IsWindowVisible(h)) return true;
            if (TitleOf(h) == "") return true;
            RECT r; if (!GetWindowRect(h, out r)) return true;
            long area = (long)(r.R - r.L) * (long)(r.B - r.T);
            if (area <= 0) return true;
            if (area > bestArea) { bestArea = area; best = h; }
            return true;
        }, IntPtr.Zero);
        return best;
    }

    // Three outcomes matter and they are NOT the same thing:
    //   vt=31 with text -> the app declared this value
    //   vt=31 empty     -> the key exists but is blank
    //   vt=0 (VT_EMPTY) -> the key is not present at all
    public static string ReadString(IntPtr hwnd, string fmtid, uint pid,
                                    out int hrStore, out int hrGet, out int vt) {
        hrStore = 0; hrGet = -1; vt = -1;
        Guid iid = new Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99");
        IPropertyStore store = null;
        hrStore = SHGetPropertyStoreForWindow(hwnd, ref iid, out store);
        if (hrStore != 0 || store == null) return null;
        PROPERTYKEY key = new PROPERTYKEY();
        key.fmtid = new Guid(fmtid);
        key.pid = pid;
        PROPVARIANT pv = new PROPVARIANT();
        hrGet = store.GetValue(ref key, out pv);
        if (hrGet != 0) return null;
        vt = pv.vt;
        string s = null;
        if (pv.vt == 31) s = (pv.ptr == IntPtr.Zero) ? "" : Marshal.PtrToStringUni(pv.ptr);
        PropVariantClear(ref pv);
        return s;
    }

    // The window property store does NOT expose a process-level AUMID: measured
    // here with the same fixture, -SetProcessAumid makes the window store read
    // ABSENT (see the POS_PROC lines). So "did the app declare an identity at
    // all" must be asked of the process itself: GetApplicationUserModelId,
    // documented in appmodel.h. 15700 = APPMODEL_ERROR_NO_APPLICATION.
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int GetApplicationUserModelId(IntPtr hProcess, ref uint appModelIdLength,
        System.Text.StringBuilder appModelId);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(uint access, bool inherit, uint procId);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr h);

    public static string ProcessAumid(uint procId, out int hr, out uint needed) {
        hr = -1; needed = 0;
        if (procId == 0) { return null; }
        IntPtr h = OpenProcess(0x1000u, false, procId); // PROCESS_QUERY_LIMITED_INFORMATION
        if (h == IntPtr.Zero) { hr = Marshal.GetLastWin32Error(); return null; }
        try {
            var sb = new System.Text.StringBuilder(1024);
            uint len = 1024;
            hr = GetApplicationUserModelId(h, ref len, sb);
            needed = len;
            if (hr != 0) return null;
            return sb.ToString();
        } finally {
            CloseHandle(h);
        }
    }
}
'@
}

function Format-Verdict {
    param([string]$Value, [int]$HrStore, [int]$HrGet, [int]$Vt)
    if ($HrStore -ne 0) { return ('READ_FAILED:store-hr=0x{0:X8}' -f $HrStore) }
    if ($HrGet -ne 0) { return ('READ_FAILED:get-hr=0x{0:X8}' -f $HrGet) }
    if ($Vt -eq 31) {
        if ([string]::IsNullOrEmpty($Value)) { return 'EMPTY' }
        return ('VALUE:' + $Value)
    }
    if ($Vt -eq 0) { return 'ABSENT' }
    return ('OTHER:vt=' + $Vt)
}

function Read-Key {
    param([IntPtr]$Hwnd, [string]$Name, [uint32]$KeyPid)
    $hrStore = 0; $hrGet = 0; $vt = 0
    $v = [PLAumid]::ReadString($Hwnd, $FMTID_AUM, $KeyPid, [ref]$hrStore, [ref]$hrGet, [ref]$vt)
    return [pscustomobject]@{
        Name    = $Name
        Raw     = $v
        HrStore = $hrStore
        HrGet   = $hrGet
        Vt      = $vt
        Text    = (Format-Verdict -Value $v -HrStore $hrStore -HrGet $hrGet -Vt $vt)
    }
}

# Wait for a window that carries a title: a pre-first-frame window has none and
# is not the window whose identity the shell reads.
function Wait-MainWindow {
    param([int]$TargetPid, [int]$TimeoutSec)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $hwnd = [IntPtr]::Zero
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        if ($TargetPid -gt 0) {
            $p = Get-Process -Id $TargetPid -ErrorAction SilentlyContinue
            if (-not $p) { break }
        }
        $hwnd = [PLAumid]::FindTitledWindow([uint32]$TargetPid)
        if ($hwnd -ne [IntPtr]::Zero) { return $hwnd }
        Start-Sleep -Milliseconds 250
    }
    return [IntPtr]::Zero
}

$fixture = Join-Path $PSScriptRoot 'task47_scratch_window.ps1'
$started = New-Object 'System.Collections.Generic.List[int]'
$fixtureSeq = 0

# The control host must be an UNPACKAGED script host: see the header note.
$fixtureHost = ''
foreach ($cand in @(
        (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'),
        (Join-Path $env:SystemRoot 'SysWOW64\WindowsPowerShell\v1.0\powershell.exe'))) {
    if ([System.IO.File]::Exists($cand)) { $fixtureHost = $cand; break }
}

# The window-store gate is exercised with pwsh: it is the only host that gets as
# far as reporting a write result. Windows PowerShell 5.1 shows its window but
# never reaches the log line for that path (measured). pwsh's own package AUMID
# is irrelevant here, because this gate is about the WINDOW store.
$winFixtureHost = [System.IO.Path]::Combine($PSHOME, 'pwsh.exe')
if (-not [System.IO.File]::Exists($winFixtureHost)) { $winFixtureHost = $fixtureHost }

function Format-ProcAumid {
    param([string]$Value, [int]$Hr)
    if ($Hr -eq 0) {
        if ([string]::IsNullOrEmpty($Value)) { return 'EMPTY' }
        return ('VALUE:' + $Value)
    }
    # 15700 APPMODEL_ERROR_NO_PACKAGE, 15703 APPMODEL_ERROR_NO_APPLICATION.
    # Both mean "this API has no identity to report", which is the normal answer
    # for an unpackaged app and is NOT the same as "the reader is broken".
    if ($Hr -eq 15700) { return 'NO_PACKAGE' }
    if ($Hr -eq 15703) { return 'NO_APPLICATION' }
    return ('READ_FAILED:hr=0x{0:X8}' -f $Hr)
}

function Read-ProcAumid {
    param([int]$ProcId)
    $hr = 0; $need = 0; $v = $null
    if ($ProcId -gt 0) { $v = [PLAumid]::ProcessAumid([uint32]$ProcId, [ref]$hr, [ref]$need) }
    return [pscustomobject]@{ Raw = $v; Hr = $hr; Text = (Format-ProcAumid -Value $v -Hr $hr) }
}

# The fixture rewrites its own -HwndFile once the window exists, so that file
# doubles as the fixture's log. Poll it: the window can show up a moment before
# the fixture gets around to flushing the line the control needs.
function Read-FixtureLine {
    param([string]$Path, [string]$Prefix)
    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 8) {
        if ([System.IO.File]::Exists($Path)) {
            $txt = ''
            try { $txt = [System.IO.File]::ReadAllText($Path) } catch { $txt = '' }
            foreach ($ln in ($txt -split "`r?`n")) {
                if ($ln.StartsWith($Prefix)) { return $ln.Substring($Prefix.Length) }
            }
        }
        Start-Sleep -Milliseconds 150
    }
    return ''
}

function Start-Fixture {
    param([string]$Tag, [string[]]$Extra, [string]$HostPath = '')
    if ([string]::IsNullOrWhiteSpace($HostPath)) { $HostPath = $fixtureHost }
    $script:fixtureSeq++
    $logPath = Join-Path $ReportDir ('fixture_' + $Tag + '_' + $script:fixtureSeq + '.txt')
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $fixture,
                 '-Mode', 'hold', '-HoldMs', '60000', '-HwndFile', $logPath) + $Extra
    $pr = Start-Process -FilePath $HostPath -ArgumentList $argList -PassThru
    [void]$started.Add($pr.Id)
    return [pscustomobject]@{ Proc = $pr; Log = $logPath }
}

Say '=== actlog AUMID probe (path C: window property store + process id) ==='
Say ("time      : " + (Get-Date).ToString('s'))
Say ("powershell: " + $PSVersionTable.PSVersion.ToString())
Say ("FMTID     : " + $FMTID_AUM)
Say ''

# ---------------------------------------------------------------- 0. controls
# Three gates, because they answer different questions:
#   POS_WIN   the reader sees a value that the window store really holds
#   POS_PROC  the process-id reader sees an id the process really declared
#   NEG       a process with no identity reads back ABSENT on both paths
# If POS_WIN cannot be produced at all, the window-store VALUE branch stays
# UNPROVEN and only its ABSENT branch is proven (by NEG).
Say '--- 0. controls (separate processes, always run first) ---'
$winCtlState = 'FAIL'
$procCtlOk = $false
$negOk = $false
# Round 5 (B): cross-application positive control for the window-store VALUE
# branch. It needs no fixture, so it also runs when no fixture host exists.
$xappOk = $false
$posWinState = 'NOT_RUN'
$posProcState = 'NOT_RUN'
$posProcWinState = 'NOT_RUN'
$negState = 'NOT_RUN'
$negProcState = 'NOT_RUN'
$posWinHr = ''

if (-not (Test-Path -LiteralPath $fixture)) {
    Say ("  [WARN] fixture not found: " + $fixture + " -> controls cannot run")
} elseif ([string]::IsNullOrWhiteSpace($fixtureHost)) {
    Say '  [WARN] no unpackaged script host found -> controls cannot run'
} else {
    Say ("  fixture host: " + $fixtureHost)
    Say '  (an unpackaged host is required: pwsh itself carries the package AUMID'
    Say '  Microsoft.PowerShell_8wekyb3d8bbwe!App, so it is neither a positive nor'
    Say '  a negative control for process identity.)'

    # gate 1 -- the window property store, which is what path C reads
    $winId = 'com.actlog.actlog.win-control'
    $f1 = Start-Fixture -Tag 'poswin' -HostPath $winFixtureHost `
        -Extra @('-WindowTitle', 'aumid-win-control', '-SetWindowAumid', $winId)
    $h1 = Wait-MainWindow -TargetPid $f1.Proc.Id -TimeoutSec 20
    $posWinHr = Read-FixtureLine -Path $f1.Log -Prefix 'WIN_AUMID_HR='
    $k1 = $null
    if ($h1 -ne [IntPtr]::Zero) {
        $k1 = Read-Key -Hwnd $h1 -Name 'PKEY_AppUserModel_ID' -KeyPid 5
        $posWinState = $k1.Text
        Say ("  POS_WIN   hwnd=0x" + $h1.ToInt64().ToString('X') + " title=[" + [PLAumid]::TitleOf($h1) + "]")
        Say ("  POS_WIN   fixture SetValue hr=" + $posWinHr + "  expected VALUE:" + $winId)
        Say ("  POS_WIN   got      " + $k1.Text)
    } else {
        $posWinState = 'NO_WINDOW'
        Say '  POS_WIN   no window: the reader was not exercised'
    }
    if ($k1 -ne $null -and $k1.Text -eq ('VALUE:' + $winId)) {
        $winCtlState = 'PASS'
        Say '  POS_WIN   -> PASS'
    } elseif ($posWinHr -eq '') {
        $winCtlState = 'UNAVAILABLE'
        Say '  POS_WIN   -> UNAVAILABLE: the fixture never reported a write result, so'
        Say '  POS_WIN   no positive control was produced and the VALUE branch of path'
        Say '  POS_WIN   C stays UNPROVEN.'
    } elseif ($posWinHr -ne '0') {
        $winCtlState = 'UNAVAILABLE'
        Say ('  POS_WIN   -> UNAVAILABLE: Windows refused the write (hr=' + $posWinHr + '), so')
        Say '  POS_WIN   the VALUE branch of path C is UNPROVEN. Its ABSENT branch is'
        Say '  POS_WIN   still proven by the negative control below.'
    } else {
        $winCtlState = 'UNAVAILABLE'
        Say '  POS_WIN   -> UNAVAILABLE: the write was accepted (hr=0) but the value does'
        Say '  POS_WIN   not read back, so this store cannot carry a window AUMID here.'
        Say '  POS_WIN   The VALUE branch of path C is UNPROVEN and only its ABSENT'
        Say '  POS_WIN   branch is proven (by the negative control below). P2 therefore'
        Say '  POS_WIN   cannot be decided by this path alone.'
    }

    # gate 2 -- process identity, the only path that can see a process AUMID
    $procId = 'com.actlog.actlog.proc-control'
    $f2 = Start-Fixture -Tag 'posproc' -Extra @('-WindowTitle', 'aumid-proc-control', '-SetProcessAumid', $procId)
    $h2 = Wait-MainWindow -TargetPid $f2.Proc.Id -TimeoutSec 20
    $pk = Read-ProcAumid -ProcId $f2.Proc.Id
    $posProcState = $pk.Text
    $procCtlOk = ($pk.Text -eq ('VALUE:' + $procId))
    Say ("  POS_PROC  pid=" + $f2.Proc.Id + " expected VALUE:" + $procId)
    Say ("  POS_PROC  got      " + $pk.Text + "  (informative, not a gate)")
    if (-not $procCtlOk) {
        Say ("  POS_PROC  fixture says AUMID_HR=" + (Read-FixtureLine -Path $f2.Log -Prefix 'AUMID_HR='))
        Say '  POS_PROC  GetApplicationUserModelId reports PACKAGE identity only: an'
        Say '  POS_PROC  explicit id set with SetCurrentProcessExplicitAppUserModelID'
        Say '  POS_PROC  is invisible to it. Measured: the fixture set its own id and'
        Say '  POS_PROC  the call still returned 0, yet this reader says NO_APPLICATION.'
        Say '  POS_PROC  So no positive control exists for this reader; it stays'
        Say '  POS_PROC  informative and the window store below is the actual gate.'
    }
    if ($h2 -ne [IntPtr]::Zero) {
        $k2 = Read-Key -Hwnd $h2 -Name 'PKEY_AppUserModel_ID' -KeyPid 5
        $posProcWinState = $k2.Text
        Say ("  POS_PROC  the same process's window store reads " + $k2.Text)
        Say '  POS_PROC  informative: a process AUMID is not copied into the window'
        Say '  POS_PROC  property store, so path C alone cannot see a process id.'
    }

    # gate 3 -- negative control
    $f3 = Start-Fixture -Tag 'neg' -Extra @('-WindowTitle', 'aumid-neg-control')
    $h3 = Wait-MainWindow -TargetPid $f3.Proc.Id -TimeoutSec 20
    $nk = Read-ProcAumid -ProcId $f3.Proc.Id
    $negProcState = $nk.Text
    if ($h3 -eq [IntPtr]::Zero) {
        $negState = 'NO_WINDOW'
    } else {
        $k3 = Read-Key -Hwnd $h3 -Name 'PKEY_AppUserModel_ID' -KeyPid 5
        $negState = $k3.Text
        $negOk = ((($k3.Text -eq 'ABSENT') -or ($k3.Text -eq 'EMPTY')) -and
                  ($nk.Text -match '^(ABSENT|EMPTY|NO_PACKAGE|NO_APPLICATION)$'))
        Say ("  NEG       hwnd=0x" + $h3.ToInt64().ToString('X') + " win=" + $k3.Text + " proc=" + $nk.Text)
        Say ("  NEG       expected ABSENT/EMPTY on both  -> " + $(if ($negOk) { 'PASS' } else { 'FAIL' }))
        if (-not $negOk) { Say ("  NEG       raw proc=[" + $nk.Raw + "] hr=" + $nk.Hr) }
    }
}
# gate 4 -- cross-application positive control (round 5, item B).
# POS_WIN above cannot be produced on this machine: Windows accepts the
# fixture's SetValue (hr=0) but the value does not read back, so the VALUE
# branch of path C had no positive control at all and P-2 could never leave
# UNDECIDED. This control needs no fixture: the Windows shell stamps its own
# top-level windows (taskbar, Start, Settings, ...) with a real AUMID, so
# reading at least one NON-EMPTY AUMID from another application's window proves
# that Read-Key can return a value and that a later ABSENT is a real absence
# rather than a broken reader.
Say '--- 0b. cross-application positive control (window store) ---'
$xappCap = 120
$script:xappWindows = New-Object System.Collections.Generic.List[IntPtr]
$script:xappHits = New-Object System.Collections.Generic.List[string]
try {
    $xcb = [PLAumid+EnumProc] {
        param($h, $l)
        $script:xappWindows.Add($h)
        return $true
    }
    [void][PLAumid]::EnumWindows($xcb, [IntPtr]::Zero)
    Say ("  POS_XAPP  top-level windows enumerated = " + $script:xappWindows.Count)
    $xappRead = 0
    $xappSkipped = 0
    foreach ($wh in $script:xappWindows) {
        if ($xappRead -ge $xappCap) { break }
        $ttl0 = [PLAumid]::TitleOf($wh)
        if ([string]::IsNullOrWhiteSpace($ttl0)) { $xappSkipped++; continue }
        $kk = Read-Key -Hwnd $wh -Name 'PKEY_AppUserModel_ID' -KeyPid 5
        $xappRead++
        if ($kk.Text -like 'VALUE:*') {
            $script:xappHits.Add("hwnd=0x" + $wh.ToInt64().ToString('X') +
                " title=[" + $ttl0 + "] AUMID=" + $kk.Text.Substring(6))
        }
    }
    Say ("  POS_XAPP  titled windows read = " + $xappRead + " (untitled skipped = " + $xappSkipped + ", cap = " + $xappCap + ")")
    foreach ($xl in $script:xappHits) { Say ("  POS_XAPP  " + $xl) }
    $xappOk = ($script:xappHits.Count -gt 0)
    Say ("  POS_XAPP  non-empty AUMID windows = " + $script:xappHits.Count + "  -> " + $(if ($xappOk) { 'PASS' } else { 'FAIL' }))
    if (-not $xappOk) {
        Say '  POS_XAPP  no other application exposed a window AUMID, so the VALUE'
        Say '  POS_XAPP  branch of path C stays UNPROVEN on this machine.'
    }
} catch {
    $xappOk = $false
    Say ("  POS_XAPP  enumeration failed: " + $_.Exception.Message)
}

# The gate for path C is the window store itself (POS_WIN) plus a negative
# control that proves the reader does not just invent a value. Round 5: the
# cross-application control POS_XAPP can stand in for POS_WIN when Windows
# refuses to keep a window AUMID written by the fixture.
$valueBranchProven = (($winCtlState -eq 'PASS') -or $xappOk)
$controlsOk = ($negOk -and $valueBranchProven)
$ctlLabel = if ($controlsOk) { 'PASS' } elseif (-not $negOk) { 'FAIL' } else { 'UNAVAILABLE' }
Say ("  CONTROLS = " + $ctlLabel +
    "   (win=" + $winCtlState +
    " xapp=" + $(if ($xappOk) { 'PASS' } else { 'FAIL' }) +
    " proc=" + $posProcState + " [informative]" +
    " neg=" + $(if ($negOk) { 'PASS' } else { 'FAIL' }) + ")")
Say ''
# ---------------------------------------------------------------- 1. target
Say '--- 1. target window ---'
$targetKind = 'none'
$targetPid = 0
$targetHwnd = [IntPtr]::Zero
$targetTitle = ''
$explicitArg = $TargetHwndHex
if (-not [string]::IsNullOrWhiteSpace($explicitArg)) {
    $hexText = $explicitArg.Trim()
    if ($hexText.StartsWith('0x') -or $hexText.StartsWith('0X')) { $hexText = $hexText.Substring(2) }
    $targetHwnd = [IntPtr]([System.Int64]::Parse($hexText, [System.Globalization.NumberStyles]::HexNumber))
    $targetKind = 'explicit-hwnd'
    $targetTitle = [PLAumid]::TitleOf($targetHwnd)
} else {
    if ([string]::IsNullOrWhiteSpace($ExePath)) { $ExePath = Resolve-ActLogExePath }
    if ($SkipStart) {
        $procs = @(Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue)
        if ($procs.Count -gt 0) {
            $targetKind = 'already-running'
            $targetPid = $procs[0].Id
            $targetHwnd = Wait-MainWindow -TargetPid $targetPid -TimeoutSec 10
        }
    } elseif ([System.IO.File]::Exists($ExePath)) {
        $p = Start-Process -FilePath $ExePath -PassThru
        [void]$started.Add($p.Id)
        $targetKind = 'started'
        $targetPid = $p.Id
        $targetHwnd = Wait-MainWindow -TargetPid $targetPid -TimeoutSec $StartupWaitSec
    } else {
        $targetKind = 'exe-missing'
    }
    if ($targetHwnd -ne [IntPtr]::Zero) { $targetTitle = [PLAumid]::TitleOf($targetHwnd) }
}
if ($targetPid -le 0 -and $targetHwnd -ne [IntPtr]::Zero) {
    $wpid = 0
    [void][PLAumid]::GetWindowThreadProcessId($targetHwnd, [ref]$wpid)
    $targetPid = [int]$wpid
}
Say ("  TARGET_KIND  = " + $targetKind)
Say ("  TARGET_EXE   = " + $(if ($ExePath) { $ExePath } else { '(none)' }))
Say ("  TARGET_PID   = " + $targetPid)
Say ("  TARGET_HWND  = 0x" + $targetHwnd.ToInt64().ToString('X'))
Say ("  TARGET_TITLE = [" + $targetTitle + "]")
Say ("  HWND_ARG     = [" + $explicitArg + "]")
Say ''

# ---------------------------------------------------------------- 2. the keys
$idState = 'NOT_READ'
$resState = 'NOT_READ'
$dispState = 'NOT_A_PKEY'
$cmdState = 'NOT_READ'
$procState = 'NOT_READ'
if ($targetHwnd -ne [IntPtr]::Zero) {
    Say '--- 2. identity of the target window ---'
    $kId = Read-Key -Hwnd $targetHwnd -Name 'PKEY_AppUserModel_ID' -KeyPid 5
    $kRes = Read-Key -Hwnd $targetHwnd -Name 'PKEY_AppUserModel_RelaunchDisplayNameResource' -KeyPid 4
    $kCmd = Read-Key -Hwnd $targetHwnd -Name 'PKEY_AppUserModel_RelaunchCommand' -KeyPid 2
    $idState = $kId.Text
    $resState = $kRes.Text
    $cmdState = $kCmd.Text
    Say ("  PKEY_AppUserModel_ID                          (pid 5, window store) = " + $idState)
    Say ("  PKEY_AppUserModel_RelaunchDisplayNameResource (pid 4, window store) = " + $resState)
    Say ("  PKEY_AppUserModel_RelaunchCommand             (pid 2, window store) = " + $cmdState)
    Say ("  PKEY_AppUserModel_RelaunchDisplayName         (no pid)             = " + $dispState)
    Say '  note: there is no PKEY_AppUserModel_RelaunchDisplayName without the'
    Say '  "Resource" suffix in the Windows SDK (propkey.h). The localised display'
    Say '  name goes through the *Resource key, which is why pid 4 is read instead'
    Say '  of guessing a pid for a key that does not exist.'
} else {
    Say '--- 2. identity of the target window ---'
    Say '  no target window: nothing to read'
}
if ($targetPid -gt 0) {
    $tp = Read-ProcAumid -ProcId $targetPid
    $procState = $tp.Text
    Say ("  GetApplicationUserModelId(pid " + $targetPid + ")                       = " + $procState)
} else {
    Say '  GetApplicationUserModelId: no pid, nothing to read'
}
Say ''

# ---------------------------------------------------------------- 3. path C verdict
Say '--- 3. path C verdict ---'
$pathC = if ($controlsOk -and $targetHwnd -ne [IntPtr]::Zero) { 'READABLE' } else { 'UNREADABLE' }
$p2 = 'UNDECIDED'
$winAbsent = ($idState -eq 'ABSENT' -or $idState -eq 'EMPTY')
$procAbsent = ($procState -match '^(ABSENT|EMPTY|NO_PACKAGE|NO_APPLICATION)$')
if (-not $controlsOk) {
    $p2 = 'UNDECIDED'
    Say '  the controls did not pass, so no statement about the target is allowed'
} elseif ($targetHwnd -eq [IntPtr]::Zero) {
    $p2 = 'UNDECIDED'
    Say '  no target window: the property store was not reachable'
} elseif ($idState -like 'VALUE:*') {
    $p2 = 'DEFER_TO_CONTROLLER'
    Say ('  the window declares an AUMID (' + $idState + '). Whether the localised')
    Say '  relaunch display name is acceptable is a product decision: see pid 4 above.'
} elseif ($procState -like 'VALUE:*') {
    $p2 = 'DEFER_TO_CONTROLLER'
    Say ('  the window store is empty (' + $idState + ') but the process declares')
    Say ('  ' + $procState + '. That combination is normal: a process-level AUMID is')
    Say '  not copied into the window property store (POS_PROC above shows the same'
    Say '  thing for a process that provably set one). Identity therefore exists;'
    Say '  whether the relaunch display name is localised is the controller decision.'
} elseif ($winAbsent -and $procAbsent) {
    $p2 = 'FAIL'
    Say '  the window store holds no AppUserModelID, the reader is proven by the'
    Say '  controls above (POS_WIN/POS_XAPP + NEG), and the process reports no package'
    Say '  application identity either. That is a product gap: the app never'
    Say '  declares an explicit identity, so the window carries no stable'
    Say '  relaunch/display identity for the shell to group or relaunch by.'
    Say '  Cross-check (report section L): apps\desktop has no call to'
    Say '  SetCurrentProcessExplicitAppUserModelID; the only AUMID string there is'
    Say '  the toast registration com.actlog.actlog, which does not reach the window.'
} else {
    $p2 = 'UNDECIDED'
    Say ('  unclassified states: window=' + $idState + ' process=' + $procState)
}

Say ''
Say ("AUMID_PROBE_TARGET=" + $targetKind)
Say ("TARGET_HWND=0x" + $targetHwnd.ToInt64().ToString('X'))
Say ("TARGET_TITLE=" + $targetTitle)
Say ("TARGET_PID=" + $targetPid)
Say ("AUMID_ID=" + $idState)
Say ("AUMID_PROC=" + $procState)
Say ("AUMID_RELAUNCH_DISPLAY=" + $dispState)
Say ("AUMID_RELAUNCH_RES=" + $resState)
Say ("AUMID_RELAUNCH_CMD=" + $cmdState)
Say ("AUMID_POS_WIN=" + $posWinState)
Say ("AUMID_POS_PROC=" + $posProcState)
Say ("AUMID_POS_PROC_WIN=" + $posProcWinState)
Say ("AUMID_POS_CONTROL=" + $(if ($controlsOk) { 'PASS' } else { 'FAIL' }))
Say ("AUMID_POS_XAPP=" + $(if ($xappOk) { 'PASS' } else { 'FAIL' }))
Say ("AUMID_POS_WIN_STATE=" + $winCtlState)
Say ("AUMID_POS_WIN_HR=" + $posWinHr)
Say ("AUMID_NEG_CONTROL=" + $negState + '/' + $negProcState)
Say ("P2_PATH_C=" + $pathC)
Say ("P2_VERDICT=" + $p2)

# ---------------------------------------------------------------- cleanup
foreach ($id in $started) {
    $live = Get-Process -Id $id -ErrorAction SilentlyContinue
    if ($live) { try { Stop-Process -Id $id -Force -ErrorAction Stop } catch { } }
}
Say ''
Say ("cleanup: stopped " + $started.Count + " process(es) started by this probe")
$left = @(Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue)
Say ("actlog processes remaining: " + $left.Count)

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Report, (($lines -join "`r`n") + "`r`n"), $utf8)
$written = -1
try { $written = (Get-Item -LiteralPath $Report).Length } catch { $written = -1 }
Write-Host ''
Write-Host "report written: $Report ($written bytes)"
Write-Host ("AUMID_ID=" + $idState + " AUMID_PROC=" + $procState + " P2_PATH_C=" + $pathC + " P2_VERDICT=" + $p2)
if ($p2 -eq 'FAIL') { exit 1 }
exit 0