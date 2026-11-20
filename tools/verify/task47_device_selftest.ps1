# task47_device_selftest.ps1 -- C1..C15 positive/negative controls for Task 47 W1b.
#
# Purpose: prove the five device scripts can actually JUDGE, before any of them
# is used to judge the product. Every control below is a positive/negative
# pair: a control that cannot fail is not a control.
#
# Controls (see waves/task47-W1b.md section 6):
#   C1  CONTROL_TITLE_STRICT_POS        strict title match accepts the zh title
#   C2  CONTROL_TITLE_STRICT_NEG        strict title match rejects a non-title
#   C3  CONTROL_EXPECTED_TITLE_ZH       expected title for zh is the zh title
#   C4  CONTROL_EXPECTED_TITLE_EN       expected title for en is 'actlog'
#   C5  CONTROL_TITLE_DISCRIMINATES     zh title accepted for zh, rejected for en
#   C6  CONTROL_EXE_SMOKE_TITLE_POS     real launch: title == expected title
#   C7  CONTROL_EXE_SMOKE_PRECOND       no window obtainable => FAIL_PRECONDITION
#   C8  CONTROL_TARGET_RESOLVE_EXPLICIT explicit exe => installed target
#   C9  CONTROL_TARGET_RESOLVE_DEFAULT  no exe arg => installed (or buildtree+WARN)
#   C10 CONTROL_MENU_CLOSE              right click => menu => close deterministically
#   C11 CONTROL_TRAY_LEFTCLICK          left click flips IsWindowVisible
#   C12 CONTROL_UIA_INFINITE_RECT       infinite UIA rect is formatted, not thrown
#   C13 CONTROL_CLOSE_PROBE_ALIVE       hide-on-close target judged alive (exit 0)
#   C14 CONTROL_CLOSE_PROBE_DEAD        exit-on-close target judged gone (exit 1)
#   C15 CONTROL_TRAY_A3_INCONCLUSIVE    flyout-closed => INCONCLUSIVE, not NOT FOUND
#
# Device controls run each script as a CHILD PROCESS on purpose: the scripts
# call `exit`, which would otherwise terminate this self-test.
#
# ASCII only. Evidence goes to $EvidenceDir (one raw file per control plus a
# summary) and is read back with Test-Path + byte count, because a previous
# round claimed a file that was never written.
#
# Usage:
#   pwsh -File tools/verify/task47_device_selftest.ps1
#   pwsh -File tools/verify/task47_device_selftest.ps1 -SkipDevice   # C1..C5, C12, C15 (no app launch)

[CmdletBinding()]
param(
    [string]$InstalledExe = 'D:\Program Files\actlog\actlog.exe',
    [string]$EvidenceDir = 'F:\soft\00selfmade\practilog\reports\task47-W1b-evidence',
    [switch]$SkipDevice
)

$ErrorActionPreference = 'Stop'
$Verify = $PSScriptRoot
. (Join-Path $Verify 'data_location.ps1')

if (-not (Test-Path -LiteralPath $EvidenceDir)) {
    [void](New-Item -ItemType Directory -Path $EvidenceDir -Force)
}

$script:summary = New-Object System.Collections.Generic.List[string]
$script:pwshExe = (Get-Process -Id $PID).Path
$script:utf8 = New-Object System.Text.UTF8Encoding($false)

function Record([string]$id, [bool]$pass, [string]$detail) {
    $tag = if ($pass) { 'PASS' } else { 'FAIL' }
    $line = "CONTROL_$id = $tag   $detail"
    $script:summary.Add($line)
    Write-Host $line
}

function Save-Raw([string]$name, [string]$text) {
    $p = Join-Path $EvidenceDir $name
    [System.IO.File]::WriteAllText($p, $text, $script:utf8)
    $len = (Get-Item -LiteralPath $p).Length
    Write-Host "[evidence] $p ($len bytes)"
    return $p
}

# Run one device script in a child process and capture stdout+stderr and the
# exit code. In-process invocation is not an option: these scripts end in
# `exit N`.
function Run-Device([string]$label, [string]$scriptPath, [string[]]$argList) {
    Write-Host ''
    Write-Host "=== RUN $label : $(Split-Path -Leaf $scriptPath) $($argList -join ' ')"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $out = & $script:pwshExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath @argList 2>&1 | Out-String
    $code = $LASTEXITCODE
    $sw.Stop()
    Write-Host $out
    Write-Host "=== EXIT $code in $($sw.ElapsedMilliseconds) ms"
    $raw = $out + "`r`nEXIT=$code`r`nMS=$($sw.ElapsedMilliseconds)`r`nARGS=$($argList -join ' ')`r`n"
    [void](Save-Raw "$label.txt" $raw)
    return [pscustomobject]@{ Out = $out; Code = $code; Ms = $sw.ElapsedMilliseconds }
}

Write-Host '=== Task 47 W1b device self-test ==='
Write-Host "time         : $((Get-Date).ToString('s'))"
Write-Host "verify dir   : $Verify"
Write-Host "evidence dir : $EvidenceDir"
Write-Host "installed exe: $InstalledExe"
Write-Host "child pwsh   : $script:pwshExe"

# The zh product title, built from code points so this file stays ASCII.
$zh = [string]([char]0x77E5) + [char]0x884C + [char]0x65E5 + [char]0x5FD7
$zhTitle = "$zh actlog"
$zhCodes = ($zhTitle.ToCharArray() | ForEach-Object { 'U+{0:X4}' -f [int]$_ }) -join ' '
Write-Host "zh title     : $zhTitle  ($zhCodes)"

# ---------------------------------------------------------------- C1..C5 (pure)
$c1 = Test-ActLogTitleStrict -Text $zhTitle
Record 'TITLE_STRICT_POS' $c1 "strict match on '$zhTitle' returned $c1 (expected True)"

$neg = 'zzz-not-the-app-title'
$c2 = Test-ActLogTitleStrict -Text $neg
Record 'TITLE_STRICT_NEG' (-not $c2) "strict match on '$neg' returned $c2 (expected False; sample contains no actlog/practilog substring)"

$expZh = Get-ActLogExpectedTitle -Language zh
$c3 = ($expZh -eq $zhTitle)
$expZhCodes = ($expZh.ToCharArray() | ForEach-Object { 'U+{0:X4}' -f [int]$_ }) -join ' '
Record 'EXPECTED_TITLE_ZH' $c3 "Get-ActLogExpectedTitle -Language zh = '$expZh' ($expZhCodes); expected '$zhTitle' ($zhCodes)"

$expEn = Get-ActLogExpectedTitle -Language en
$c4 = ($expEn -eq 'actlog')
Record 'EXPECTED_TITLE_EN' $c4 "Get-ActLogExpectedTitle -Language en = '$expEn' (expected 'actlog')"

$okZh = Test-ActLogTitleStrict -Text $zhTitle -Language zh
$okEn = Test-ActLogTitleStrict -Text $zhTitle -Language en
$c5 = ($okZh -eq $true -and $okEn -eq $false)
Record 'TITLE_DISCRIMINATES' $c5 "-Language zh => $okZh (expected True), -Language en => $okEn (expected False)"

# ---------------------------------------------------------------- C6/C7 (device)
if (-not $SkipDevice) {
    if (-not (Test-Path -LiteralPath $InstalledExe)) {
        Record 'EXE_SMOKE_TITLE_POS' $false "installed exe missing: $InstalledExe (cannot judge)"
        Record 'EXE_SMOKE_PRECOND' $false "installed exe missing: $InstalledExe (cannot judge)"
    } else {
        $r6 = Run-Device 'C6_exe_smoke_zh' (Join-Path $Verify 'exe_smoke.ps1') @(
            '-ExePath', $InstalledExe, '-Language', 'zh')
        $c6 = ($r6.Code -eq 0) -and ($r6.Out -match 'EXE_SMOKE: PASS') -and ($r6.Out -match 'window title is the app title')
        $titleLine = @($r6.Out -split "`r?`n" | Where-Object { $_ -match 'window title = ' }) -join ' / '
        Record 'EXE_SMOKE_TITLE_POS' $c6 "exit=$($r6.Code); $titleLine"

        $r7 = Run-Device 'C7_exe_smoke_precond' (Join-Path $Verify 'exe_smoke.ps1') @(
            '-ExePath', $InstalledExe, '-Language', 'zh', '-SimulateNoWindow')
        $sawPrecond = $r7.Out -match 'FAIL_PRECONDITION'
        $sawTitleJudge = $r7.Out -match 'window title is the app title'
        $c7 = ($r7.Code -eq 2) -and $sawPrecond -and (-not $sawTitleJudge)
        Record 'EXE_SMOKE_PRECOND' $c7 "exit=$($r7.Code) (expected 2); FAIL_PRECONDITION=$sawPrecond; title criterion was judged=$sawTitleJudge (expected False)"
    }
} else {
    Write-Host '[SKIP] -SkipDevice: C6/C7/C10/C11 not run'
}

# ---------------------------------------------------------------- C8/C9 (device)
if (-not $SkipDevice) {
    $r8 = Run-Device 'C8_target_explicit' (Join-Path $Verify 'installed_app_check.ps1') @(
        '-ExePath', $InstalledExe,
        '-Report', (Join-Path $EvidenceDir 'C8_installed_app_check_explicit.txt'))
    $src8 = if ($r8.Out -match '(?m)^\s*TARGET_SOURCE = (\S+)') { $matches[1] } else { '(missing)' }
    $kind8 = if ($r8.Out -match '(?m)^\s*TARGET_KIND\s+= (\S+)') { $matches[1] } else { '(missing)' }
    $dir8 = if ($r8.Out -match '(?m)^\s*DATA_DIR\s+= (.+)$') { $matches[1].Trim() } else { '(missing)' }
    $c8 = ($src8 -eq 'explicit') -and ($kind8 -eq 'installed') -and ($dir8 -eq 'D:\Program Files\actlog\userdata')
    Record 'TARGET_RESOLVE_EXPLICIT' $c8 "TARGET_SOURCE=$src8 TARGET_KIND=$kind8 DATA_DIR=$dir8"

    $r9 = Run-Device 'C9_target_default' (Join-Path $Verify 'installed_app_check.ps1') @(
        '-Report', (Join-Path $EvidenceDir 'C9_installed_app_check_default.txt'))
    $src9 = if ($r9.Out -match '(?m)^\s*TARGET_SOURCE = (\S+)') { $matches[1] } else { '(missing)' }
    $kind9 = if ($r9.Out -match '(?m)^\s*TARGET_KIND\s+= (\S+)') { $matches[1] } else { '(missing)' }
    if ($kind9 -eq 'installed') {
        $c9 = ($src9 -eq 'auto-installed')
        Record 'TARGET_RESOLVE_DEFAULT' $c9 "TARGET_SOURCE=$src9 TARGET_KIND=$kind9 (expected auto-installed/installed)"
    } else {
        $warned = $r9.Out -match 'target is the BUILD TREE'
        $c9 = ($src9 -eq 'auto-buildtree') -and $warned
        Record 'TARGET_RESOLVE_DEFAULT' $c9 "TARGET_SOURCE=$src9 TARGET_KIND=$kind9; buildtree WARN present=$warned (acceptable branch, but a device/setup defect)"
    }
} else {
    Write-Host '[SKIP] -SkipDevice: C8/C9 not run'
}

# ---------------------------------------------------------------- C10/C11 (device)
if (-not $SkipDevice) {
    $r10 = Run-Device 'C10C11_tray_interaction' (Join-Path $Verify 'tray_interaction_check.ps1') @(
        '-ExePath', $InstalledExe, '-ReportDir', $EvidenceDir)
    $closed = if ($r10.Out -match '(?m)^control_menu_closed = (\S+)') { $matches[1] } else { '(missing)' }
    $method = if ($r10.Out -match '(?m)^menu_close_method = (\S+)') { $matches[1] } else { '(missing)' }
    $flip = if ($r10.Out -match '(?m)^left_click_flip = (\S+)') { $matches[1] } else { '(missing)' }
    $vb = if ($r10.Out -match '(?m)^left_click_visible_before = (\S+)') { $matches[1] } else { '(missing)' }
    $va = if ($r10.Out -match '(?m)^left_click_visible_after = (\S+)') { $matches[1] } else { '(missing)' }
    $c10 = ($closed -eq 'True') -and ($method -ne 'none') -and ($method -ne 'no-menu-appeared') -and ($method -ne '(missing)')
    Record 'MENU_CLOSE' $c10 "control_menu_closed=$closed menu_close_method=$method (expected True / a real method)"
    $c11 = ($flip -eq 'True')
    Record 'TRAY_LEFTCLICK' $c11 "left_click_visible_before=$vb left_click_visible_after=$va flip=$flip (expected True)"
} else {
    Write-Host '[SKIP] -SkipDevice: C10/C11 not run'
}

# ---------------------------------------------------------------- C12 (device)
$uiaPath = Join-Path $Verify 'uia_find_tray.ps1'
$infiniteSeen = $false
if (-not $SkipDevice) {
    $r12 = Run-Device 'C12_uia_find_tray' $uiaPath @('-ReportDir', $EvidenceDir)
    $infiniteSeen = ($r12.Out -match 'INFINITE')
    $c12a = ($r12.Code -eq 0)
    Write-Host "  uia run: exit=$($r12.Code) INFINITE printed=$infiniteSeen"
} else {
    $c12a = $true
}

# The formatter lives inside uia_find_tray.ps1 (it is not a module), so the
# fallback lifts that exact function source out of the file and runs it on a
# constructed infinite rectangle: same code path, no fake reimplementation.
$injected = 'not needed'
$c12b = $true
if (-not $infiniteSeen) {
    $txt = Get-Content -Raw -LiteralPath $uiaPath
    $m = [regex]::Match($txt, '(?ms)^function Format-Rect\(\$r\) \{.*?^\}')
    if (-not $m.Success) {
        $c12b = $false
        $injected = 'Format-Rect source not found'
    } else {
        Invoke-Expression $m.Value
        $fake = [pscustomobject]@{
            X      = [double]::PositiveInfinity
            Y      = 0.0
            Width  = 10.0
            Height = 10.0
        }
        $got = Format-Rect $fake
        $injected = "Format-Rect(PositiveInfinity) => '$got'"
        $c12b = ($got -eq 'INFINITE')
    }
}
$c12 = $c12a -and $c12b
Record 'UIA_INFINITE_RECT' $c12 "script exit ok=$c12a; INFINITE seen in a live run=$infiniteSeen; injection: $injected"

# ------------------------------------------------------- C13 / C14 (device)
# F.2: the "the app survives the window close" judgement has to be able to
# FAIL, otherwise it proves nothing. Both controls run the SAME judgement
# script (installed_app_check.ps1, which drives a real WM_CLOSE and then
# re-scans the pid's top-level windows) against two different targets:
#   C13 the installed app, which hides to the tray => must be judged alive
#   C14 the scratch fixture in -Mode exit-on-close => must be judged gone
# A single-target run cannot distinguish "the check works" from "the check
# always says alive".
$iacPath = Join-Path $Verify 'installed_app_check.ps1'
$scratchPath = Join-Path $Verify 'task47_scratch_window.ps1'
# C10/C11 deliberately leave the app running (so a human can look at the
# tray). installed_app_check refuses to close a session it did not start, so
# the close probe would be SKIPPED -- and a skipped probe cannot serve as a
# positive control. Clear those self-test processes first. (Seen in the first
# C13 run: "CLOSE_PROBE = SKIPPED (actlog is already running)".)
if (-not $SkipDevice) {
    $leftover = @(Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue)
    if ($leftover.Count -gt 0) {
        Write-Host "  clearing $($leftover.Count) app process(es) left over from C10/C11 before the close probe"
        $leftover | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 800
    }
    $r13 = Run-Device 'C13_installed_app_check_alive' $iacPath @(
        '-ExePath', $InstalledExe,
        '-ReportDir', $EvidenceDir,
        '-Report', (Join-Path $EvidenceDir 'C13_installed_app_check_alive_report.txt'))
    $c13a = ($r13.Code -eq 0)
    $c13b = ($r13.Out -match 'CLOSE_PROBE=HIDDEN_TO_TRAY')
    $c13c = -not ($r13.Out -match 'process is gone')
    $c13 = $c13a -and $c13b -and $c13c
    Record 'CLOSE_PROBE_ALIVE' $c13 "exit=$($r13.Code) (expected 0); CLOSE_PROBE=HIDDEN_TO_TRAY=$c13b; no 'process is gone'=$c13c"

    $r14 = Run-Device 'C14_installed_app_check_dead' $iacPath @(
        '-ExePath', $script:pwshExe,
        '-ProbeFixture', $scratchPath,
        '-ProbeFixtureMode', 'exit-on-close',
        '-ProbeFixtureTitle', 'scratch-c14',
        '-ReportDir', $EvidenceDir,
        '-Report', (Join-Path $EvidenceDir 'C14_installed_app_check_dead_report.txt'))
    $c14a = ($r14.Code -eq 1)
    $c14b = ($r14.Out -match 'CLOSE_PROBE=PROCESS_GONE')
    $c14c = ($r14.Out -match 'process is gone')
    $c14d = -not ($r14.Out -match 'CLOSE_PROBE=HIDDEN_TO_TRAY')
    $c14 = $c14a -and $c14b -and $c14c -and $c14d
    Record 'CLOSE_PROBE_DEAD' $c14 "exit=$($r14.Code) (expected 1); CLOSE_PROBE=PROCESS_GONE=$c14b; 'process is gone' printed=$c14c; not misread as alive=$c14d"
} else {
    Write-Host '[SKIP] -SkipDevice: C13/C14 not run'
}

# ---------------------------------------------------------- C15 (injection)
# A3 of tray_alive_check.ps1 used to print 'NOT FOUND' when the overflow
# flyout had simply never opened -- an unjudged case dressed up as a negative.
# The verdict table now lives in Get-A3Verdict; this control lifts that exact
# function source out of the script and calls it with constructed counts.
# INJECTION PATH (same treatment as C12): it proves the three-way table, it
# does NOT open a real overflow flyout on this machine -- said plainly here so
# nobody reads C15 as live evidence about the tray.
$trayPath = Join-Path $Verify 'tray_alive_check.ps1'
$trayTxt = Get-Content -Raw -LiteralPath $trayPath
$m15 = [regex]::Match($trayTxt, '(?ms)^function Get-A3Verdict \{.*?^\}')
$c15 = $false
$c15Detail = 'Get-A3Verdict source not found in tray_alive_check.ps1'
if ($m15.Success) {
    Invoke-Expression $m15.Value
    $vOverflow = Get-A3Verdict -FoundCount 0 -FlyoutCount 0
    $vOpenNoHit = Get-A3Verdict -FoundCount 0 -FlyoutCount 3
    $vHit = Get-A3Verdict -FoundCount 1 -FlyoutCount 3
    $c15a = ($vOverflow -match '^INCONCLUSIVE_TRAY_IN_OVERFLOW')
    $c15b = -not ($vOverflow -match 'NOT FOUND')
    $c15c = ($vOpenNoHit -match '^NOT FOUND')
    $c15d = ($vHit -match '^PASS')
    $c15e = ($vOverflow -ne $vOpenNoHit)
    $c15 = $c15a -and $c15b -and $c15c -and $c15d -and $c15e
    $c15Detail = "injection path, no live flyout: closed=>INCONCLUSIVE=$c15a not-NOTFOUND=$c15b; open-no-hit=>NOT FOUND=$c15c; hit=>PASS=$c15d; two cases discriminable=$c15e"
}
Record 'TRAY_A3_INCONCLUSIVE' $c15 $c15Detail

# ---------------------------------------------------------------- cleanup + summary
# The device scripts start the app; leave no stray process behind.
Get-Process -Name (Get-ActLogProcessNames) -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host ''
Write-Host '=== summary ==='
foreach ($l in $script:summary) { Write-Host $l }
$failed = @($script:summary | Where-Object { $_ -match '= FAIL' })
$total = $script:summary.Count
$allpass = if ($failed.Count -eq 0) { 'yes' } else { 'no' }
$summaryText = ($script:summary -join "`r`n") + "`r`n" +
    "CONTROLS=$total`r`nFAILED=$($failed.Count)`r`nCONTROL_ALLPASS=$allpass`r`n"
[void](Save-Raw 'task47_selftest_summary.txt' $summaryText)

Write-Host ''
Write-Host "CONTROLS = $total  FAILED = $($failed.Count)  CONTROL_ALLPASS = $allpass"
if ($failed.Count -gt 0) {
    foreach ($f in $failed) { Write-Host "  $f" }
    exit 1
}
exit 0