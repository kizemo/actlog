# task47_taskbar_name_fixture.ps1 -- capability probe for Task 47 W1c-1.
#
# QUESTION THIS ANSWERS
#   Can a process make its taskbar button show a name of its own choosing by
#   writing AppUserModel properties, independent of the window title? The W1c
#   product fix hypothesis is "set RelaunchDisplayNameResource so the taskbar
#   button follows the UI language". Before any product code is written, this
#   probe has to say whether that mechanism is real.
#
# WHY A COMPILED FIXTURE INSTEAD OF THE EXISTING SCRATCH WINDOW
#   * task47_scratch_window.ps1 runs inside pwsh. pwsh carries a package
#     identity (Microsoft.PowerShell_8wekyb3d8bbwe!App), which contaminates any
#     AUMID case: the button grouping would belong to PowerShell, not to us.
#   * powershell.exe 5.1 hangs on window property store writes (measured in
#     W1b: window shows, result never returns).
#   A standalone .NET Framework exe compiled with csc.exe avoids both: no
#   package identity, no 5.1 host, and its exe path is a unique identity so the
#   zero-AUMID case has an unambiguous AutomationId to match.
#
# DISCRIMINATIVE DESIGN (deliberate improvement over the dispatch text)
#   The dispatch said to use the SAME string for window title and for
#   RelaunchDisplayName. That makes the probe unable to tell which one the
#   taskbar used. Here the two strings are DIFFERENT:
#       window title            = ZZ-TB-TITLE-<case>-<nonce>
#       RelaunchDisplayName     = ZZ-TB-RELAUNCH-<case>-<nonce>
#   Then the observed button name says which source won.
#
# PROPERTY ORDERING
#   Window properties are written AFTER the HWND exists but BEFORE the window
#   is shown. That is the strongest ordering available to the mechanism (the
#   taskbar sees the properties at button-creation time); if it still loses to
#   the title, that is a real negative, not an artefact of late writing.
#
# CASES (each in its own process, own nonce)
#   C0  title only                        -- control: a fixture taskbar button
#                                            exists at all
#   C1  RelaunchCommand + RelaunchName    -- documented relaunch pairing
#   C2  window AUMID     + C1 props
#   C3  process AUMID    + window AUMID + C1 props
#
# VERDICT POLICY
#   MECHANISM_WORKS=true        a button name came from RelaunchDisplayName.
#   MECHANISM_WORKS=false       apparatus proven sound and the name did not.
#   MECHANISM_INCONCLUSIVE=true apparatus could not see enough (button never
#                               appeared, or the property never read back).
#   A blind apparatus must never be reported as a product negative.
#
# TEST FIXTURE, NOT PRODUCT CODE. The compiled exe and the .cs source live in
# the evidence directory and are disposable.

[CmdletBinding()]
param(
    [string]$ReportDir = 'F:\soft\00selfmade\practilog\reports\task47-W1c-evidence',
    [string]$CscPath = '',
    [int]$HoldMs = 30000,
    [int]$ReadyTimeoutSec = 20,
    # Compile only, do not run cases (used to validate the toolchain alone).
    [switch]$SkipRun,
    # Leave the compiled exe on disk (default keeps it, evidence directory).
    [switch]$KeepFixture
)

$ErrorActionPreference = 'Stop'

$lines = New-Object 'System.Collections.Generic.List[string]'
function Say([string]$s) {
    $lines.Add($s) | Out-Null
    Write-Host $s
}
function Write-Evidence {
    param([string]$Path, [string]$Text)
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $utf8)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw ("evidence file was not written: " + $Path)
    }
    $len = (Get-Item -LiteralPath $Path).Length
    Say ("EVIDENCE_FILE=" + $Path + " BYTES=" + $len)
}

if (-not (Test-Path -LiteralPath $ReportDir)) {
    [void](New-Item -ItemType Directory -Path $ReportDir -Force)
}

$exePath = Join-Path $ReportDir 'ZZTBFixture.exe'
$csPath = Join-Path $ReportDir 'ZZTBFixture.cs'
$probeLog = Join-Path $ReportDir 'probe_relaunch_display_name.txt'

$fmtidAum = '{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}'
$titleTag = 'ZZ-TB-TITLE'
$relaunchTag = 'ZZ-TB-RELAUNCH'
# Taskbar appends a pinned marker and a " - N windows" counter to button names.
$pinnedZh = -join @([char]0x5DF2, [char]0x56FA, [char]0x5B9A)

Say '=== task47 W1c-1 taskbar name capability probe ==='
Say ("REPORT_DIR=" + $ReportDir)
Say ("HOST_PS=" + $PSVersionTable.PSVersion.ToString())
Say ("PROPS_FMTID=" + $fmtidAum)
Say ("TITLE_TAG=" + $titleTag)
Say ("RELAUNCH_TAG=" + $relaunchTag)

# ---------------------------------------------------------------- toolchain --
if ([string]::IsNullOrWhiteSpace($CscPath)) {
    $cands = @(
        'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe',
        'C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe'
    )
    $CscPath = ($cands | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1)
}
if ([string]::IsNullOrWhiteSpace($CscPath) -or -not (Test-Path -LiteralPath $CscPath)) {
    Say 'PROBE_VERDICT=UNPROVEN'
    Say 'MECHANISM_WORKS=false'
    Say 'MECHANISM_INCONCLUSIVE=true'
    Say 'REASON=CSC_NOT_FOUND'
    Write-Evidence -Path $probeLog -Text (($lines -join "`r`n") + "`r`n")
    exit 2
}
Say ("CSC=" + $CscPath)

$csSource = @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

public static class ZZTBFixture
{
    const string FMTID_AUM = "{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}";
    const string IID_PROPS = "886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99";

    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    static extern int SetCurrentProcessExplicitAppUserModelID(string appId);
    // SHGetPropertyStoreForWindow can return CO_E_NOTINITIALIZED unless the
    // calling thread has OLE up. Manual DoEvents loops do not do it for us.
    [DllImport("ole32.dll")] static extern int CoInitializeEx(IntPtr pvReserved, uint coInit);

    [StructLayout(LayoutKind.Sequential)]
    struct PROPERTYKEY { public Guid fmtid; public uint pid; }

    // 24 bytes on x64; explicit size because the callee writes the whole struct.
    [StructLayout(LayoutKind.Explicit, Size = 24)]
    struct PROPVARIANT { [FieldOffset(0)] public ushort vt; [FieldOffset(8)] public IntPtr ptr; }

    [ComImport, Guid(IID_PROPS), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IPropertyStore
    {
        [PreserveSig] int GetCount(out uint cProps);
        [PreserveSig] int GetAt(uint iProp, out PROPERTYKEY pkey);
        [PreserveSig] int GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
        [PreserveSig] int SetValue(ref PROPERTYKEY key, ref PROPVARIANT pv);
        [PreserveSig] int Commit();
    }

    [DllImport("shell32.dll")] static extern int SHGetPropertyStoreForWindow(
        IntPtr hwnd, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out IPropertyStore store);

    [DllImport("ole32.dll")] static extern int PropVariantClear(ref PROPVARIANT pv);

    static int OpenStore(IntPtr hwnd, out IPropertyStore store)
    {
        Guid iid = new Guid(IID_PROPS);
        return SHGetPropertyStoreForWindow(hwnd, ref iid, out store);
    }

    // Writes a string property into the window's own property store.
    static int SetString(IntPtr hwnd, uint pid, string value)
    {
        IPropertyStore store;
        int hr = OpenStore(hwnd, out store);
        if (hr != 0 || store == null) return hr;
        PROPERTYKEY key = new PROPERTYKEY();
        key.fmtid = new Guid(FMTID_AUM);
        key.pid = pid;
        // InitPropVariantFromString is not an exported entry point of propsys.dll
        // on this host (EntryPointNotFoundException), so build VT_LPWSTR here.
        PROPVARIANT pv = new PROPVARIANT();
        pv.vt = 31;
        pv.ptr = Marshal.StringToCoTaskMemUni(value);
        if (pv.ptr == IntPtr.Zero) return -2147024882;
        hr = store.SetValue(ref key, ref pv);
        PropVariantClear(ref pv);
        if (hr != 0) return hr;
        return store.Commit();
    }

    // Same call, but never lets an exception escape: a throw here would kill
    // a winexe silently and the probe would lose the reason.
    static string TrySet(IntPtr hwnd, uint pid, string value)
    {
        try { return SetString(hwnd, pid, value).ToString(); }
        catch (Exception ex)
        {
            string m = ex.Message.Replace("\r", " ").Replace("\n", " ");
            return "EX:" + ex.GetType().Name + ":" + m;
        }
    }

    // Reads a string property back out of a window's property store. Works
    // across processes too (the taskbar is a different process as well), which
    // is why the harness can use it as an independent read-back control.
    static string ReadString(IntPtr hwnd, uint pid, out int hr, out int vt)
    {
        hr = -1; vt = 0;
        IPropertyStore store;
        hr = OpenStore(hwnd, out store);
        if (hr != 0 || store == null) return "";
        PROPERTYKEY key = new PROPERTYKEY();
        key.fmtid = new Guid(FMTID_AUM);
        key.pid = pid;
        PROPVARIANT pv;
        hr = store.GetValue(ref key, out pv);
        if (hr != 0) return "";
        vt = pv.vt;
        string s = "";
        if (pv.ptr != IntPtr.Zero) s = Marshal.PtrToStringUni(pv.ptr);
        PropVariantClear(ref pv);
        return s;
    }

    static Dictionary<string, string> ParseArgs(string[] args)
    {
        Dictionary<string, string> d = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        for (int i = 0; i < args.Length; i++)
        {
            string a = args[i];
            if (a.Length > 1 && a[0] == '-')
            {
                string v = (i + 1 < args.Length && !(args[i + 1].Length > 1 && args[i + 1][0] == '-'))
                    ? args[++i] : "1";
                d[a.Substring(1)] = v;
            }
        }
        return d;
    }

    static string Get(Dictionary<string, string> a, string k)
    {
        string v;
        return a.TryGetValue(k, out v) ? v : "";
    }

    static void Flush(string path, StringBuilder sb)
    {
        if (string.IsNullOrEmpty(path)) return;
        byte[] bytes = new UTF8Encoding(false).GetBytes(sb.ToString());
        using (FileStream fs = new FileStream(path, FileMode.Create, FileAccess.Write,
                                              FileShare.ReadWrite | FileShare.Delete))
        {
            fs.Write(bytes, 0, bytes.Length);
            fs.Flush(true);
        }
    }

    [STAThread]
    static int Main(string[] args)
    {
        Dictionary<string, string> a = ParseArgs(args);
        string mode = Get(a, "Mode");
        if (mode == "") mode = "hold";
        string logFile = Get(a, "LogFile");
        StringBuilder sb = new StringBuilder();
        Action<string> log = delegate(string s) { sb.Append(s).Append("\r\n"); Flush(logFile, sb); };

        // RPC_E_CHANGED_MODE (0x80010106) just means the thread was already
        // initialised with the other model; both are fine here.
        int coHr = CoInitializeEx(IntPtr.Zero, 2);
        log("COINIT_HR=" + coHr);
        // Lets the harness prove the log it reads belongs to this very run.
        log("RUN_NONCE=" + Get(a, "LogNonce"));

        if (mode == "read")
        {
            string hw = Get(a, "TargetHwnd");
            if (hw == "") { log("READ_ERROR=no-hwnd"); return 3; }
            IntPtr h = (IntPtr)Convert.ToInt64(hw, 16);
            int hr, vt;
            string v5 = ReadString(h, 5, out hr, out vt);
            log("READ_ID_HR=" + hr);
            log("READ_ID_VT=" + vt);
            log("READ_ID=" + v5);
            string v4 = ReadString(h, 4, out hr, out vt);
            log("READ_RN_HR=" + hr);
            log("READ_RN_VT=" + vt);
            log("READ_RN=" + v4);
            string v2 = ReadString(h, 2, out hr, out vt);
            log("READ_RC_HR=" + hr);
            log("READ_RC_VT=" + vt);
            log("READ_RC=" + v2);
            log("READ_EXITING=1");
            return 0;
        }

        string title = Get(a, "WindowTitle");
        if (title == "") title = "ZZ-TB-TITLE";
        int holdMs = 30000;
        int parsed;
        if (int.TryParse(Get(a, "HoldMs"), out parsed)) holdMs = parsed;

        log("MODE=" + mode);
        log("PID=" + Process.GetCurrentProcess().Id);
        log("TITLE=" + title);

        // Process AppUserModelID only lands if it is set before the first
        // window of the process is created.
        string procAum = Get(a, "SetProcessAumid");
        if (procAum != "")
        {
            int phr = SetCurrentProcessExplicitAppUserModelID(procAum);
            log("PROC_AUMID=" + procAum);
            log("PROC_AUMID_HR=" + phr);
        }
        else { log("PROC_AUMID="); log("PROC_AUMID_HR=(n/a)"); }

        Form f = new Form();
        f.Text = title;
        f.Width = 460;
        f.Height = 200;
        f.StartPosition = FormStartPosition.Manual;
        f.Location = new Point(160, 160);
        f.ShowInTaskbar = true;
        f.BackColor = Color.White;
        f.FormBorderStyle = FormBorderStyle.FixedSingle;
        Label lbl = new Label();
        lbl.Text = "task47 W1c-1 name fixture";
        lbl.AutoSize = true;
        lbl.Left = 16;
        lbl.Top = 16;
        f.Controls.Add(lbl);

        // SHOW FIRST. Measured in this host: SHGetPropertyStoreForWindow plus
        // Commit on a HWND that has never been shown blocks forever (cases C2
        // and C3 logged nothing after HWND). Showing first is what real apps
        // do, so this is not a weaker test of the mechanism.
        f.Show();
        f.Refresh();
        IntPtr hwnd = f.Handle;
        SetForegroundWindow(hwnd);
        log("SHOWN=1");
        log("HWND=0x" + hwnd.ToInt64().ToString("X"));

        string winAum = Get(a, "SetWindowAumid");
        if (winAum != "")
        {
            log("WIN_AUMID_HR=" + TrySet(hwnd, 5, winAum));
            log("WIN_AUMID=" + winAum);
        }
        else log("WIN_AUMID_HR=(n/a)");

        string rc = Get(a, "SetRelaunchCommand");
        if (rc != "")
        {
            log("RELAUNCH_CMD_HR=" + TrySet(hwnd, 2, rc));
            log("RELAUNCH_CMD=" + rc);
        }
        else log("RELAUNCH_CMD_HR=(n/a)");

        string rn = Get(a, "SetRelaunchDisplayName");
        if (rn != "")
        {
            log("RELAUNCH_NAME_HR=" + TrySet(hwnd, 4, rn));
            log("RELAUNCH_NAME=" + rn);
        }
        else log("RELAUNCH_NAME_HR=(n/a)");

        // In-process read-back: proves the value is really in the store, so a
        // later "no effect on the button" cannot be blamed on a failed write.
        int hr2, vt2;
        string rb4 = ReadString(hwnd, 4, out hr2, out vt2);
        log("INPROC_RN_HR=" + hr2);
        log("INPROC_RN_VT=" + vt2);
        log("INPROC_RN=" + rb4);
        string rb5 = ReadString(hwnd, 5, out hr2, out vt2);
        log("INPROC_ID_HR=" + hr2);
        log("INPROC_ID_VT=" + vt2);
        log("INPROC_ID=" + rb5);

        // Let the shell rebuild the button from the new properties. Hide/show
        // re-creates the taskbar button; it is a real path, not a name poke.
        if (winAum != "" || rc != "" || rn != "")
        {
            f.Hide();
            System.Threading.Thread.Sleep(400);
            f.Show();
            f.Refresh();
            SetForegroundWindow(hwnd);
            log("REFRESHED=1");
        }

        Stopwatch sw = Stopwatch.StartNew();
        while (sw.Elapsed.TotalMilliseconds < holdMs)
        {
            Application.DoEvents();
            System.Threading.Thread.Sleep(40);
        }
        log("CLOSED_AFTER_MS=" + (int)sw.Elapsed.TotalMilliseconds);
        log("EXITING=1");
        f.Close();
        return 0;
    }
}
'@

Say ("CS_BYTES=" + [System.Text.Encoding]::ASCII.GetByteCount($csSource))
$ascii = New-Object System.Text.ASCIIEncoding
[System.IO.File]::WriteAllText($csPath, $csSource, $ascii)

$compileArgs = @(
    '/nologo',
    '/target:winexe',
    '/platform:anycpu',
    ('/out:' + $exePath),
    '/reference:System.dll',
    '/reference:System.Core.dll',
    '/reference:System.Drawing.dll',
    '/reference:System.Windows.Forms.dll',
    $csPath
)
# A fixture left over from an aborted run still holds the exe open and makes
# the linker fail with CS0016, which would silently probe a stale binary.
$strays = @(Get-Process -Name 'ZZTBFixture' -ErrorAction SilentlyContinue)
if ($strays.Count -gt 0) {
    foreach ($sp in $strays) { try { Stop-Process -Id $sp.Id -Force -ErrorAction Stop } catch { } }
    Start-Sleep -Milliseconds 400
    Say ('STRAYS_STOPPED=' + $strays.Count)
}
$cout = & $CscPath $compileArgs 2>&1
$compileRc = $LASTEXITCODE
foreach ($l in $cout) { Say ("CSC_OUT| " + [string]$l) }
Say ("COMPILE_RC=" + $compileRc)
if (-not (Test-Path -LiteralPath $exePath)) {
    Say 'PROBE_VERDICT=UNPROVEN'
    Say 'MECHANISM_WORKS=false'
    Say 'MECHANISM_INCONCLUSIVE=true'
    Say 'REASON=FIXTURE_COMPILE_FAILED'
    Write-Evidence -Path $probeLog -Text (($lines -join "`r`n") + "`r`n")
    exit 3
}
Say ("FIXTURE_EXE=" + $exePath + " BYTES=" + (Get-Item -LiteralPath $exePath).Length)

function Stop-Fixture {
    $procs = @(Get-Process -Name 'ZZTBFixture' -ErrorAction SilentlyContinue)
    foreach ($p in $procs) {
        try { Stop-Process -Id $p.Id -Force -ErrorAction Stop } catch { }
    }
    return $procs.Count
}
[void](Stop-Fixture)

if ($SkipRun) {
    Say 'SKIP_RUN=1'
    Write-Evidence -Path $probeLog -Text (($lines -join "`r`n") + "`r`n")
    exit 0
}

# ------------------------------------------------------------- UIA helpers --
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

if (-not ('ZZTBW32' -as [type])) {
    Add-Type -Namespace ZZTBW32 -Name Win32 -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern System.IntPtr FindWindow(string cls, string win);
'@
}

function Get-TaskbarButtons {
    $h = [ZZTBW32.Win32]::FindWindow('Shell_TrayWnd', $null)
    if ($h -eq [IntPtr]::Zero) { return @() }
    $el = [System.Windows.Automation.AutomationElement]::FromHandle($h)
    if ($null -eq $el) { return @() }
    $all = $el.FindAll([System.Windows.Automation.TreeScope]::Descendants,
                       [System.Windows.Automation.Condition]::TrueCondition)
    $out = New-Object 'System.Collections.Generic.List[object]'
    foreach ($e in $all) {
        try {
            if ($e.Current.ControlType.ProgrammaticName -ne 'ControlType.Button') { continue }
            $out.Add([pscustomobject]@{
                Name = [string]$e.Current.Name
                AutomationId = [string]$e.Current.AutomationId
                ClassName = [string]$e.Current.ClassName
            })
        } catch { }
    }
    return $out
}

function Remove-TaskbarDecorations {
    param([string]$Name)
    if ([string]::IsNullOrEmpty($Name)) { return '' }
    $s = $Name.Trim()
    $s = $s.Replace($pinnedZh, '').Replace('pinned', '').Trim()
    if ($s -match '^(.*)\s-\s\d+\s.+$') { $s = $Matches[1].Trim() }
    return $s
}

function Read-LogKey {
    param([string]$Path, [string]$Key)
    if (-not (Test-Path -LiteralPath $Path)) { return '' }
    # The fixture keeps the log open for writing; a plain ReadAllLines would
    # collide with it and throw "being used by another process".
    $txt = ''
    try {
        $share = [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
        $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, $share)
        try {
            $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::UTF8)
            $txt = $sr.ReadToEnd()
            $sr.Dispose()
        } finally { $fs.Dispose() }
    } catch { return '' }
    foreach ($l in ($txt -split "`r?`n")) {
        if ($l.StartsWith($Key + '=')) { return $l.Substring($Key.Length + 1) }
    }
    return ''
}

function Wait-LogKey {
    param([string]$Path, [string]$Key, [int]$TimeoutSec)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        $v = Read-LogKey -Path $Path -Key $Key
        if (-not [string]::IsNullOrEmpty($v)) { return $v }
        Start-Sleep -Milliseconds 150
    }
    return ''
}

function Wait-LogValue {
    param([string]$Path, [string]$Key, [string]$Expected, [int]$TimeoutSec)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        if ((Read-LogKey -Path $Path -Key $Key) -eq $Expected) { return $Expected }
        Start-Sleep -Milliseconds 150
    }
    return ''
}

# ------------------------------------------------------------------- cases --
$nonce = (Get-Date).ToString('HHmmss')
$cases = @(
    @{ Id = 'C0'; Desc = 'title only'; Proc = ''; Win = ''; Rc = ''; Rn = '' },
    @{ Id = 'C1'; Desc = 'window RelaunchCommand + RelaunchDisplayName'; Proc = ''; Win = ''; Rc = '1'; Rn = '1' },
    @{ Id = 'C2'; Desc = 'window AUMID + relaunch props'; Proc = ''; Win = '1'; Rc = '1'; Rn = '1' },
    @{ Id = 'C3'; Desc = 'process AUMID + window AUMID + relaunch props'; Proc = '1'; Win = '1'; Rc = '1'; Rn = '1' }
)

$results = New-Object 'System.Collections.Generic.List[object]'
$controlButtonVisible = $false
$controlReadbackOk = $false
$sawRelaunchName = $false
$sawAnyName = $false

foreach ($c in $cases) {
    $id = $c.Id
    $title = $titleTag + '-' + $id + '-' + $nonce
    $relaunch = $relaunchTag + '-' + $id + '-' + $nonce
    $procAum = ''
    $winAum = ''
    if ($c.Proc -eq '1') { $procAum = 'ZZTBFixture.Probe.' + $id + '.' + $nonce }
    if ($c.Win -eq '1') { $winAum = 'ZZTBFixture.Win.' + $id + '.' + $nonce }

    $log = Join-Path $ReportDir ('fixture_' + $id + '.txt')

    Say ''
    Say ('--- CASE ' + $id + ' ' + $c.Desc + ' ---')
    Say ('CASE_TITLE=' + $title)
    Say ('CASE_RELAUNCH_NAME=' + $relaunch)

    $argList = @('-Mode', 'hold', '-WindowTitle', $title, '-HoldMs', [string]$HoldMs, '-LogFile', $log, '-LogNonce', $nonce)
    if ($procAum -ne '') { $argList += @('-SetProcessAumid', $procAum) }
    if ($winAum -ne '') { $argList += @('-SetWindowAumid', $winAum) }
    if ($c.Rc -eq '1') { $argList += @('-SetRelaunchCommand', $exePath) }
    if ($c.Rn -eq '1') { $argList += @('-SetRelaunchDisplayName', $relaunch) }

    $proc = Start-Process -FilePath $exePath -ArgumentList $argList -PassThru
    # An earlier run leaves a log with the same name; never trust it.
    $rn = Wait-LogValue -Path $log -Key 'RUN_NONCE' -Expected $nonce -TimeoutSec $ReadyTimeoutSec
    if ($rn -ne $nonce) { Say ('LOG_NONCE_MISSING=' + $rn) }
    $hwnd = Wait-LogKey -Path $log -Key 'HWND' -TimeoutSec $ReadyTimeoutSec
    $shown = Wait-LogKey -Path $log -Key 'SHOWN' -TimeoutSec 10

    $row = [pscustomobject]@{
        Case = $id
        Pid = $proc.Id
        Hwnd = $hwnd
        Title = $title
        Relaunch = $relaunch
        ProcAumid = $procAum
        WinAumid = $winAum
        ReadHr = ''
        ReadValue = ''
        XReadValue = ''
        ButtonName = ''
        ButtonAutomationId = ''
        ButtonClean = ''
        Source = 'NONE'
        Hung = ([string]::IsNullOrEmpty($shown))
        RelaunchNeeded = ($c.Rn -eq '1')
        WriteHr = ''
    }
    # The fixture writes the properties after SHOWN; reading the log before the
    # write stage lands would report a false "write not attempted".
    $null = Wait-LogKey -Path $log -Key 'INPROC_RN_HR' -TimeoutSec 10
    $null = Wait-LogKey -Path $log -Key 'REFRESHED' -TimeoutSec 3
    $row.WriteHr = (Read-LogKey -Path $log -Key 'RELAUNCH_NAME_HR')

    Say ('FIXTURE_PID=' + $proc.Id)
    Say ('FIXTURE_HWND=' + $hwnd)
    Say ('FIXTURE_SHOWN=' + $shown)
    Say ('CASE_HUNG=' + $row.Hung)
    foreach ($k in @('PROC_AUMID_HR', 'WIN_AUMID_HR', 'RELAUNCH_CMD_HR', 'RELAUNCH_NAME_HR',
                     'INPROC_RN_HR', 'INPROC_RN_VT', 'INPROC_RN', 'INPROC_ID_HR', 'INPROC_ID')) {
        Say ('LOG_' + $k + '=' + (Read-LogKey -Path $log -Key $k))
    }

    if (-not [string]::IsNullOrEmpty($hwnd)) {
        # Independent process reads the property back across the process
        # boundary, which is what the shell itself has to do.
        $rlog = Join-Path $ReportDir ('readback_' + $id + '.txt')
        $rp = Start-Process -FilePath $exePath -ArgumentList @('-Mode', 'read', '-TargetHwnd', $hwnd, '-LogFile', $rlog, '-LogNonce', $nonce) -PassThru -Wait
        $row.XReadValue = (Read-LogKey -Path $rlog -Key 'READ_RN')
        Say ('XPROC_READ_RN_HR=' + (Read-LogKey -Path $rlog -Key 'READ_RN_HR'))
        Say ('XPROC_READ_RN_VT=' + (Read-LogKey -Path $rlog -Key 'READ_RN_VT'))
        Say ('XPROC_READ_RN=' + $row.XReadValue)
        Say ('XPROC_READ_ID=' + (Read-LogKey -Path $rlog -Key 'READ_ID'))
        $xNonce = Read-LogKey -Path $rlog -Key 'RUN_NONCE'
        Say ('XPROC_LOG_NONCE=' + $xNonce)
        if ($c.Rn -eq '1' -and $row.XReadValue -eq $relaunch -and $xNonce -eq $nonce) { $controlReadbackOk = $true }
    }

    # Give the shell a moment to build/update the button.
    Start-Sleep -Milliseconds 1500
    $buttons = @(Get-TaskbarButtons)
    Say ('TASKBAR_BUTTONS=' + $buttons.Count)

    $exeLeaf = [System.IO.Path]::GetFileNameWithoutExtension($exePath)
    $match = $null
    foreach ($b in $buttons) {
        $hitId = ($b.AutomationId -like ('*' + $exeLeaf + '*')) -or
                 ($procAum -ne '' -and $b.AutomationId -like ('*' + $procAum + '*')) -or
                 ($winAum -ne '' -and $b.AutomationId -like ('*' + $winAum + '*'))
        $hitName = ($b.Name -like ('*' + $title + '*')) -or ($b.Name -like ('*' + $relaunch + '*'))
        if ($hitId -or $hitName) { $match = $b; break }
    }

    if ($null -ne $match) {
        $row.ButtonName = $match.Name
        $row.ButtonAutomationId = $match.AutomationId
        $row.ButtonClean = Remove-TaskbarDecorations -Name $match.Name
        if ($row.ButtonClean -like ('*' + $relaunchTag + '*' )) { $row.Source = 'RELAUNCH_DISPLAY_NAME' }
        elseif ($row.ButtonClean -like ('*' + $titleTag + '*')) { $row.Source = 'WINDOW_TITLE' }
        elseif ($row.ButtonClean -like ('*' + $exeLeaf + '*')) { $row.Source = 'EXE_NAME' }
        elseif ($row.ButtonClean -ne '') { $row.Source = 'OTHER_NONEMPTY' }
        else { $row.Source = 'EMPTY' }
        Say ('BUTTON_FOUND=1')
        Say ('BUTTON_NAME=' + $row.ButtonName)
        Say ('BUTTON_NAME_CLEAN=' + $row.ButtonClean)
        Say ('BUTTON_AUTOMATION_ID=' + $row.ButtonAutomationId)
        Say ('BUTTON_NAME_SOURCE=' + $row.Source)
        if ($row.ButtonClean -ne '') { $sawAnyName = $true }
        if ($row.Source -eq 'RELAUNCH_DISPLAY_NAME') { $sawRelaunchName = $true }
        if ($id -eq 'C0') { $controlButtonVisible = $true }
    }
    else {
        Say 'BUTTON_FOUND=0'
        Say 'BUTTON_NAME_SOURCE=NONE'
        foreach ($b in $buttons) {
            Say ('ALL_BTN| name=' + $b.Name + ' | aid=' + $b.AutomationId + ' | cls=' + $b.ClassName)
        }
    }

    $results.Add($row) | Out-Null

    if (-not $proc.HasExited) {
        try { Stop-Process -Id $proc.Id -Force -ErrorAction Stop } catch { }
    }
    [void]$proc.WaitForExit(5000)
    Start-Sleep -Milliseconds 600
}

$cleaned = Stop-Fixture
Say ''
Say ('CLEANED_FIXTURE_PROCS=' + $cleaned)
Say ('FIXTURE_PROCS_AFTER=' + @(Get-Process -Name 'ZZTBFixture' -ErrorAction SilentlyContinue).Count)

# --------------------------------------------------------------- aggregate --
Say ''
Say '=== SUMMARY ==='
foreach ($r in $results) {
    Say ('RESULT| case=' + $r.Case + ' source=' + $r.Source +
         ' clean=' + $r.ButtonClean + ' inproc_rn=' + $r.ReadValue + ' xproc_rn=' + $r.XReadValue)
}

$mechanismWorks = $sawRelaunchName
$inconclusive = $false
if (-not $controlButtonVisible) { $inconclusive = $true }
if (-not $sawAnyName) { $inconclusive = $true }
foreach ($r in $results) { if ($r.Hung) { $inconclusive = $true } }
$writeOk = $false
foreach ($r in $results) { if ($r.RelaunchNeeded -and $r.WriteHr -eq '0') { $writeOk = $true } }
Say ('CONTROL_WRITE_OK=' + $writeOk)
if (-not ($writeOk -and $controlReadbackOk)) { $inconclusive = $true }

Say ('CONTROL_BUTTON_VISIBLE=' + $controlButtonVisible)
Say ('CONTROL_READBACK_OK=' + $controlReadbackOk)
Say ('MECHANISM_WORKS=' + ($mechanismWorks.ToString().ToLower()))
Say ('MECHANISM_INCONCLUSIVE=' + ($inconclusive.ToString().ToLower()))

$verdict = 'UNPROVEN'
if ($inconclusive) {
    $verdict = 'UNPROVEN'
}
elseif (-not $sawAnyName) {
    $verdict = 'FAIL'
}
else {
    $verdict = 'PASS'
}
Say ('PROBE_VERDICT=' + $verdict)

if (-not $KeepFixture) {
    # Keep the exe: it is the evidence that the fixture ran. Only the .cs
    # source is dropped when the caller asks for a clean directory.
}

Write-Evidence -Path $probeLog -Text (($lines -join "`r`n") + "`r`n")

$csv = New-Object 'System.Collections.Generic.List[string]'
$csv.Add('case,desc,pid,hwnd,title,relaunch,proc_aumid,win_aumid,inproc_rn_hr,inproc_rn,xproc_rn,button_name,button_name_clean,button_automation_id,source') | Out-Null
foreach ($r in $results) {
    $vals = @($r.Case, '', $r.Pid, $r.Hwnd, $r.Title, $r.Relaunch, $r.ProcAumid, $r.WinAumid,
              $r.ReadHr, $r.ReadValue, $r.XReadValue, $r.ButtonName, $r.ButtonClean,
              $r.ButtonAutomationId, $r.Source)
    $csv.Add(($vals -join ',')) | Out-Null
}
Write-Evidence -Path (Join-Path $ReportDir 'probe_relaunch_display_name.csv') -Text (($csv -join "`r`n") + "`r`n")

exit 0