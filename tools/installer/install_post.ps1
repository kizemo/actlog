# install_post.ps1 -- post-extract step run by the SFX installer.
# Creates a Desktop + Start Menu shortcut and launches the app.
# ASCII only: the Chinese shortcut description is built from char codes.
#
# Called with the working directory = the extraction folder (actlog.exe sits next to this file).
#   -NoShortcut : verification mode, do not touch the user's Desktop / Start Menu
#   -NoLaunch   : do not start the app

param(
    [switch]$NoShortcut,
    [switch]$NoLaunch,
    [string]$AppDir = ''
)

$ErrorActionPreference = 'Stop'
if (-not $AppDir) { $AppDir = $PSScriptRoot }
$exe = Join-Path $AppDir 'actlog.exe'
# kAppTitle = zhi-xing-ri-zhi (U+77E5 U+884C U+65E5 U+5FD7)
$name = [string]([char]0x77E5) + [char]0x884C + [char]0x65E5 + [char]0x5FD7
# Shortcut file name: the product was renamed PractiLog -> actlog, so the
# shortcut the user sees on the Desktop / Start Menu is "actlog".
$brand = 'actlog'
$ico = Join-Path $AppDir 'app_icon.ico'
if (-not (Test-Path $ico)) {
    $cand = Join-Path $AppDir 'data\flutter_assets\assets\icon.png'
    $ico = ''   # PNG cannot be a .lnk icon source; fall back to the exe itself
}
$report = Join-Path $env:TEMP 'actlog_install_post.txt'
$out = @()
$out += "appdir   = $AppDir"
$out += "exe      = $exe  exists=$(Test-Path $exe)"

if (-not (Test-Path $exe)) {
    $out += 'VERDICT = FAIL (actlog.exe missing next to install_post.ps1)'
    $out | Set-Content -Path $report -Encoding UTF8
    throw "actlog.exe not found in $AppDir"
}

if (-not $NoShortcut) {
    $sh = New-Object -ComObject WScript.Shell
    $iconLoc = if ($ico -and (Test-Path $ico)) { "$ico,0" } else { "$exe,0" }
    $desk = [Environment]::GetFolderPath('Desktop')
    $l1 = $sh.CreateShortcut((Join-Path $desk "$brand.lnk"))
    $l1.TargetPath = $exe; $l1.WorkingDirectory = $AppDir; $l1.IconLocation = $iconLoc
    $l1.Description = $name; $l1.Save()
    $out += "desktop-shortcut = $(Join-Path $desk "$brand.lnk") exists=$(Test-Path (Join-Path $desk "$brand.lnk"))"

    $sm = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\actlog'
    New-Item -ItemType Directory -Force -Path $sm | Out-Null
    $l2 = $sh.CreateShortcut((Join-Path $sm "$brand.lnk"))
    $l2.TargetPath = $exe; $l2.WorkingDirectory = $AppDir; $l2.IconLocation = $iconLoc
    $l2.Description = $name; $l2.Save()
    $out += "startmenu-shortcut = $(Join-Path $sm "$brand.lnk") exists=$(Test-Path (Join-Path $sm "$brand.lnk"))"
    $out += "icon-location = $iconLoc"
} else {
    $out += 'shortcuts = SKIPPED (-NoShortcut, verification mode)'
}

if (-not $NoLaunch) {
    Start-Process -FilePath $exe -WorkingDirectory $AppDir | Out-Null
    Start-Sleep -Seconds 2
    $p = Get-Process actlog -ErrorAction SilentlyContinue
    $out += "launched = pid $(if ($p) { ($p | Select-Object -First 1).Id } else { 'NONE' })"
} else {
    $out += 'launch = SKIPPED (-NoLaunch)'
}
$out += 'VERDICT = OK'
$out | Set-Content -Path $report -Encoding UTF8
$out | ForEach-Object { Write-Output $_ }
