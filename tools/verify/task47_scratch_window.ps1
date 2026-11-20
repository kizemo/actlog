# task47_scratch_window.ps1 -- disposable window target for the Task 47 self-test.
#
# This is a TEST FIXTURE, never part of the product. Three jobs:
#
#   * control C14 (installed_app_check.ps1 close probe, negative half):
#     the criterion "app survives the window close" must report the opposite for
#     a target that really DOES quit on close. notepad.exe was tried first and is
#     unusable -- Windows 11 single-instance / session-restore hands the window to
#     an already running instance, so the tracked pid exits for the WRONG reason.
#     This fixture has none of that: one process, one window, close == exit.
#
#   * AUMID probe positive control, process side: -SetProcessAumid makes the
#     process declare an explicit AppUserModelID (SetCurrentProcessExplicitAppUserModelID).
#     Read back with GetApplicationUserModelId on this pid.
#
#   * AUMID probe positive control, window side: -SetWindowAumid writes
#     PKEY_AppUserModel_ID into this window's own property store through
#     IPropertyStore::SetValue. Measured fact: a process-level AUMID is NOT
#     copied into the window property store, so path C needs this flag to have
#     any non-empty value to read at all. Same binary, different flags, so the
#     positive/negative comparison stays honest.
#
# Modes:
#   exit-on-close  the window closes, the script ends, the process is GONE.
#   hold           the window stays up until -HoldMs elapses (or it is closed).
#
# Usage:
#   pwsh -NoProfile -File task47_scratch_window.ps1 -Mode exit-on-close
#   pwsh -NoProfile -File task47_scratch_window.ps1 -Mode hold -HoldMs 60000 `
#        -SetProcessAumid 'com.actlog.actlog.selftest' -HwndFile C:\tmp\w.txt

[CmdletBinding()]
param(
    [ValidateSet('exit-on-close', 'hold')]
    [string]$Mode = 'exit-on-close',
    [string]$WindowTitle = 'actlog scratch window',
    [int]$HoldMs = 600000,
    # Empty means "do not touch the process AppUserModelID" -- that is the
    # negative control.
    [string]$SetProcessAumid = '',
    # Empty means "leave the window property store alone" -- also the negative
    # control for path C.
    [string]$SetWindowAumid = '',
    [string]$HwndFile = ''
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-not ('PLScratchWin32' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class PLScratchWin32 {
    [DllImport("user32.dll", SetLastError = true)] public static extern bool SetProcessDpiAwarenessContext(IntPtr ctx);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string appId);

    [StructLayout(LayoutKind.Sequential)]
    public struct PROPERTYKEY { public Guid fmtid; public uint pid; }

    // 24 bytes on x64: the callee writes the whole struct, so the size is
    // explicit instead of letting the marshaller pass 16 bytes.
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
    static extern int SHGetPropertyStoreForWindow(IntPtr hwnd, ref Guid iid,
        [MarshalAs(UnmanagedType.Interface)] out IPropertyStore store);
    [DllImport("propsys.dll", CharSet = CharSet.Unicode)]
    static extern int InitPropVariantFromString(string value, out PROPVARIANT pv);
    [DllImport("ole32.dll")]
    static extern int PropVariantClear(ref PROPVARIANT pv);

    // Writes PKEY_AppUserModel_ID on this process's own window. Returns the HRESULT
    // so the fixture can report exactly what happened instead of assuming success.
    public static int SetWindowAumid(IntPtr hwnd, string fmtid, uint pid, string value) {
        Guid iid = new Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99");
        IPropertyStore store = null;
        int hr = SHGetPropertyStoreForWindow(hwnd, ref iid, out store);
        if (hr != 0 || store == null) return hr;
        PROPERTYKEY key = new PROPERTYKEY();
        key.fmtid = new Guid(fmtid);
        key.pid = pid;
        PROPVARIANT pv;
        hr = InitPropVariantFromString(value, out pv);
        if (hr != 0) return hr;
        hr = store.SetValue(ref key, ref pv);
        PropVariantClear(ref pv);
        if (hr != 0) return hr;
        return store.Commit();
    }
}
'@
}

$lines = New-Object 'System.Collections.Generic.List[string]'
function Say([string]$s) { $lines.Add($s); Write-Host $s }
function Write-Report {
    param([string]$Path, [string]$Text)
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $utf8)
}

# Keep the host console out of the way: a flashing console window would take the
# foreground away from the very window the probe is about to look at.
$con = [PLScratchWin32]::GetConsoleWindow()
if ($con -ne [IntPtr]::Zero) { [void][PLScratchWin32]::ShowWindow($con, 0) }

# Per-monitor v2 before any window exists, so rects are real pixels.
[void][PLScratchWin32]::SetProcessDpiAwarenessContext([IntPtr](-4))

Say ("MODE=" + $Mode)
Say ("PID=" + $PID)
Say ("TITLE=" + $WindowTitle)

# The AppUserModelID has to be set BEFORE the first window is created: a window
# only inherits the process id at creation time.
$aurHr = $null
if (-not [string]::IsNullOrWhiteSpace($SetProcessAumid)) {
    $aurHr = [PLScratchWin32]::SetCurrentProcessExplicitAppUserModelID($SetProcessAumid)
    Say ("AUMID_SET=" + $SetProcessAumid)
    Say ("AUMID_HR=" + $aurHr)
} else {
    Say 'AUMID_SET=(none)'
    Say 'AUMID_HR=(n/a)'
}

$script:form = New-Object System.Windows.Forms.Form
$script:form.Text = $WindowTitle
$script:form.Width = 520
$script:form.Height = 260
$script:form.StartPosition = 'CenterScreen'
$script:form.ShowInTaskbar = $true
$script:form.BackColor = [System.Drawing.Color]::White

$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = ('scratch target: ' + $Mode)
$lbl.AutoSize = $true
$lbl.Left = 20
$lbl.Top = 20
[void]$script:form.Controls.Add($lbl)

$script:closed = $false
$script:form.Add_FormClosed({ $script:closed = $true })

[void]$script:form.Show()
[void]$script:form.Refresh()
[void][PLScratchWin32]::SetForegroundWindow($script:form.Handle)

# Window property store: only an explicit SetValue lands here. A process AUMID
# does not (that is why the probe reads the process id separately).
$FMTID_AUM = '{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}'
$winAumHr = $null
if (-not [string]::IsNullOrWhiteSpace($SetWindowAumid)) {
    $winAumHr = [PLScratchWin32]::SetWindowAumid($script:form.Handle, $FMTID_AUM, 5, $SetWindowAumid)
    Say ("WIN_AUMID_SET=" + $SetWindowAumid)
    Say ("WIN_AUMID_HR=" + $winAumHr)
} else {
    Say 'WIN_AUMID_SET=(none)'
    Say 'WIN_AUMID_HR=(n/a)'
}

$hwndText = '0x' + $script:form.Handle.ToInt64().ToString('X')
Say ("HWND=" + $hwndText)
Write-Report -Path $HwndFile -Text (($lines -join "`r`n") + "`r`n")

# Pump the message queue by hand instead of Application::Run: WM_CLOSE is then
# dispatched here, the FormClosed handler flips the flag, and the loop ends --
# which is exactly the "close destroys the window" behaviour this fixture is for.
$sw = [System.Diagnostics.Stopwatch]::StartNew()
while (-not $script:closed) {
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 50
    if ($Mode -eq 'hold' -and $sw.Elapsed.TotalMilliseconds -ge $HoldMs) {
        $script:form.Close()
        break
    }
}

Say ("CLOSED_AFTER_MS=" + [int][Math]::Round($sw.Elapsed.TotalMilliseconds))
Say 'EXITING=1'
Write-Report -Path $HwndFile -Text (($lines -join "`r`n") + "`r`n")
exit 0