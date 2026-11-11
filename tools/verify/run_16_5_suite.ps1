# actlog P1 section 16.5 verification suite.
#
# Runs, in one shot:
#   1. toast probe            (release exe --toast-probe)
#   2. notification db check  (marker inside wpndatabase.db + row count delta)
#   3. tray interaction check (left click toggle / right click menu / show window)
#   4. SFX rebuild + payload listing
#
# Evidence files:
#   .superpowers\p1_16_5_suite.txt        (this run's log)
#   .superpowers\toast_probe_check.json   (raw notification db dump)
#   .superpowers\tray_interaction_report.txt
#
# ASCII only.
param(
  [string]$ReleaseDir = 'F:\soft\00selfmade\practilog\apps\desktop\build\windows\x64\runner\Release'
)

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$outDir = Join-Path $root '.superpowers'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$logPath = Join-Path $outDir 'p1_16_5_suite.txt'

$script:lines = New-Object System.Collections.Generic.List[string]
function Add-Line([string]$text) {
  $script:lines.Add($text)
  ($script:lines -join "`r`n") | Out-File -FilePath $logPath -Encoding utf8
}
function Add-Block([string]$title, [string]$body) {
  Add-Line ("--- $title ---")
  Add-Line $body
}

# current exe name first, legacy exe name second
$exe = Join-Path $ReleaseDir 'actlog.exe'
if (-not (Test-Path $exe)) { $exe = Join-Path $ReleaseDir 'practilog.exe' }
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
$sevenZip = 'C:\Program Files\7-Zip\7z.exe'

Add-Line ("run_at = " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Add-Line ("release_dir = " + $ReleaseDir)

if (Get-Process -Name LogonUI -ErrorAction SilentlyContinue) {
  Add-Line 'FAIL session is locked (LogonUI running)'
  exit 2
}
if (-not (Test-Path $exe)) { Add-Line "FAIL release exe missing: $exe"; exit 2 }

# ---------------------------------------------------------------- 1. toast
Add-Line '=== STEP 1: toast probe ==='
$before = & $python (Join-Path $PSScriptRoot 'toast_probe_check.py') 2>&1 | Out-String
Add-Block 'notification db BEFORE probe' $before

$probeOut = & $exe --toast-probe 2>&1 | Out-String
$probeExit = $LASTEXITCODE
Add-Line ("probe_exit = " + $probeExit)
Add-Block 'probe stdout' $probeOut

Start-Sleep -Seconds 3
$after = & $python (Join-Path $PSScriptRoot 'toast_probe_check.py') --report (Join-Path $outDir 'toast_probe_check.json') 2>&1 | Out-String
$checkExit = $LASTEXITCODE
Add-Block 'notification db AFTER probe' $after
Add-Line ("toast_check_exit = " + $checkExit)

# ------------------------------------------------- 2. tray interaction
Add-Line '=== STEP 2: tray interaction ==='
Get-Process -Name 'actlog', 'practilog' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
$app = Start-Process -FilePath $exe -WorkingDirectory $ReleaseDir -PassThru
Add-Line ("app_pid = " + $app.Id)
Start-Sleep -Seconds 8

$trayScript = Join-Path $PSScriptRoot 'tray_interaction_check.ps1'
$trayOut = & pwsh -NoProfile -ExecutionPolicy Bypass -File $trayScript 2>&1 | Out-String
$trayExit = $LASTEXITCODE
Add-Line ("tray_exit = " + $trayExit)
Add-Block 'tray script stdout' $trayOut

# ------------------------------------------------- 3. SFX rebuild
Add-Line '=== STEP 3: SFX rebuild ==='
$sfxScript = Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'build') 'make_sfx.ps1'
$sfxOut = & pwsh -NoProfile -ExecutionPolicy Bypass -File $sfxScript 2>&1 | Out-String
$sfxExit = $LASTEXITCODE
Add-Line ("sfx_exit = " + $sfxExit)
Add-Block 'sfx builder stdout' $sfxOut

$sfxExe = ($sfxOut -split "`n" | Where-Object { $_ -like 'sfx_out = *' } | Select-Object -First 1)
if ($sfxExe) {
  $sfxPath = ($sfxExe -replace '^sfx_out = ', '').Trim()
  $listing = & $sevenZip l $sfxPath 2>&1 | Out-String
  Add-Block 'sfx payload listing' $listing
}

# ------------------------------------------------- summary
Add-Line '=== SUMMARY ==='
Add-Line ("toast_probe_exit = " + $probeExit)
Add-Line ("toast_db_check_exit = " + $checkExit)
Add-Line ("tray_interaction_exit = " + $trayExit)
Add-Line ("sfx_build_exit = " + $sfxExit)
$failed = @()
if ($probeExit -ne 0) { $failed += 'toast_probe' }
if ($checkExit -ne 0) { $failed += 'toast_db_check' }
if ($trayExit -ne 0) { $failed += 'tray_interaction' }
if ($sfxExit -ne 0) { $failed += 'sfx_build' }
if ($failed.Count -eq 0) { Add-Line 'SUITE = PASS' } else { Add-Line ('SUITE = FAIL (' + ($failed -join ', ') + ')') }
