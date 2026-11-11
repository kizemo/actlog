# data_location.ps1 -- the single source of truth for where actlog keeps its
# database and logs, shared by every script under tools/verify.
#
# RENAME (PractiLog -> actlog):
#   The app, its exe and its data dirs are renamed. Every candidate the CURRENT
#   app uses comes first; every LEGACY (PractiLog-era) candidate follows it, so
#   a machine that has not been migrated yet is still readable and the
#   acceptance scripts work on both generations.
#
# Why this file exists: the data dir moved twice:
#   %APPDATA%\com.practiclog\practilog   (legacy, pre-migration)
#   <directory of the exe>\userdata       (install layout, primary)
# so hard-coding one of them in each script is wrong on one side or the other.
# Resolution lives here; scripts only say which log file they want.
#
# Candidate order (mirrors apps/desktop/lib/src/app_paths.dart):
#   1. pin                $env:ACTLOG_DATA_DIR, then the legacy
#                         $env:PRACTILOG_DATA_DIR. When set, the pin wins
#                         outright, even if the dir does not exist yet, because
#                         its whole purpose is to make an acceptance run
#                         deterministic.
#   2. userdata           <exe dir>\userdata, from -ExePath if the caller knows
#                         which build it is verifying, else the dev Release dir.
#                         This is where a migrated build writes.
#   3. programdata        %PROGRAMDATA%\actlog, then the legacy
#                         %PROGRAMDATA%\practilog.
#   4. localappdata       %LOCALAPPDATA%\com.actlog\actlog-fallback, then the
#                         legacy %LOCALAPPDATA%\com.practiclog\practilog-fallback.
#   5. appdata            %APPDATA%\com.actlog\actlog, then the legacy
#                         %APPDATA%\com.practiclog\practilog -- NOT a write
#                         target any more (it is only the migration source),
#                         but every log written before the migration is there,
#                         so reads must keep looking there.
#
# Outside of the pin, the resolver returns the FIRST candidate that actually
# exists. If none exists it returns candidate 2, i.e. the dir a migrated build
# is about to create, so a caller treating "file not found" as "no log yet"
# behaves the same way it did with the old hard-coded path.
#
# Log file names follow the app: actlog_startup.log / actlog_selftest.log /
# actlog_toast_probe.log (+ actlog.db and its -wal / -shm sidecars). When the
# new name is absent but the legacy name is present in the same data dir, the
# LEGACY path is returned, so an unmigrated install stays readable.
#
# NOTE the two "data" names are NOT the same thing and must never be confused:
#   <exe dir>\userdata           -> actlog's own db + logs  (this resolver)
#   <exe dir>\data\flutter_assets-> Flutter framework assets, owned by the build
#
# Usage (dot-source from a script in this same folder -- $PSScriptRoot there is
# that script's own dir, which is also this file's dir):
#   . (Join-Path $PSScriptRoot 'data_location.ps1')
#   $log = Resolve-ActLogLogFile -FileName 'actlog_startup.log' -ExePath $ExePath
#   $info = Resolve-ActLogDataDir -ExePath $ExePath   # .Path .Kind .Exists .Candidates
#
# Dot-sourcing also sets two convenience variables ($ActLogDataDir,
# $ActLogStartupLog) for callers that do not have an exe path to pass.
# The legacy function names and variables are kept as thin aliases so scripts
# outside this folder (for example .superpowers/final_check.ps1) keep working
# unchanged.
#
# ASCII only, read only, never creates or deletes anything.

# Captured while this file is being dot-sourced: $PSScriptRoot here is
# tools/verify, i.e. this file's own directory, not the caller's.
$script:ActLogVerifyDir = $PSScriptRoot

# Legacy file names inside the same data dir: current name -> legacy name.
$script:ActLogLegacyFileNames = @{
    'actlog_startup.log'     = 'practilog_startup.log'
    'actlog_selftest.log'    = 'practilog_selftest.log'
    'actlog_toast_probe.log' = 'practilog_toast_probe.log'
    'actlog.db'              = 'practilog.db'
}

function Get-ActLogDevReleaseDir {
    <#
      Dev Windows build output. Derived from this file's location so the repo
      stays movable; falls back to the absolute dev path from the P1 brief.
    #>
    [CmdletBinding()]
    param()
    $rel = 'apps\desktop\build\windows\x64\runner\Release'
    if ($script:ActLogVerifyDir) {
        $tools = Split-Path -Parent $script:ActLogVerifyDir          # ...\tools
        $root = Split-Path -Parent $tools                               # repo root
        $cand = Join-Path $root $rel
        if ($root -and (Test-Path (Join-Path $root 'apps\desktop'))) { return $cand }
    }
    return 'F:\soft\00selfmade\practilog\apps\desktop\build\windows\x64\runner\Release'
}

function Get-ActLogExeNames {
    <# Current exe file name first, legacy exe file name second. #>
    return @('actlog.exe', 'practilog.exe')
}

function Get-ActLogProcessNames {
    <# Current process name first, legacy process name second. #>
    return @('actlog', 'practilog')
}

function Resolve-ActLogExePath {
    <#
      The exe to verify: an explicit -ExePath always wins, otherwise the dev
      Release dir is probed for the current exe name and then the legacy one.
      Never throws, even when the drive is not mounted.
    #>
    [CmdletBinding()]
    param([string]$ExePath = '')
    if (-not [string]::IsNullOrWhiteSpace($ExePath)) { return $ExePath }
    $dir = Get-ActLogDevReleaseDir
    if ([string]::IsNullOrWhiteSpace($dir)) { return '' }
    foreach ($n in (Get-ActLogExeNames)) {
        $p = [System.IO.Path]::Combine($dir, $n)
        if ([System.IO.File]::Exists($p)) { return $p }
    }
    return [System.IO.Path]::Combine($dir, 'actlog.exe')
}

function Get-ActLogTitleCandidates {
    <#
      Accepted app title / tray tooltip strings. The Chinese product title is
      built from code points so this file stays pure ASCII; the ASCII names are
      the renamed product name and the legacy one.
    #>
    $cn = [string]([char]0x77E5) + [char]0x884C + [char]0x65E5 + [char]0x5FD7
    return @($cn, 'actlog', 'practilog')
}

function Test-ActLogTitle {
    <# True when the text is exactly one of the accepted titles (case-insensitive). #>
    [CmdletBinding()]
    param([string]$Text = '')
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    foreach ($c in (Get-ActLogTitleCandidates)) {
        if ($Text.Trim() -ieq $c) { return $true }
    }
    return $false
}

function Get-ActLogTitleRegex {
    <# Regex that matches any accepted title inside a longer string. #>
    $cn = [string]([char]0x77E5) + [char]0x884C + [char]0x65E5 + [char]0x5FD7
    return ('(?i)(' + [regex]::Escape($cn) + '|actlog|practilog)')
}

function Get-ActLogDataDirCandidate {
    <#
      Ordered candidate list, highest priority first. Does not touch the disk
      except a cheap existence probe per entry so callers can show what it saw.
    #>
    [CmdletBinding()]
    param([string]$ExePath = '')

    [System.Collections.Generic.List[object]]$out = New-Object 'System.Collections.Generic.List[object]'

    foreach ($envName in @('ACTLOG_DATA_DIR', 'PRACTILOG_DATA_DIR')) {
        $pin = [System.Environment]::GetEnvironmentVariable($envName)
        if (-not [string]::IsNullOrWhiteSpace($pin)) {
            $out.Add([pscustomobject]@{
                Kind = 'pin'; Path = $pin; Exists = [System.IO.Directory]::Exists($pin)
            })
            return $out.ToArray()
        }
    }

    # Every path here is built with [IO.Path]::Combine / GetDirectoryName and
    # probed with [IO.Directory]::Exists on purpose: Join-Path and Test-Path
    # resolve drives, so pointing -ExePath at a volume that is not currently
    # mounted (verifying an install on another drive) would throw instead of
    # simply reporting "does not exist".
    $exeDir = ''
    if (-not [string]::IsNullOrWhiteSpace($ExePath)) {
        $exeDir = [System.IO.Path]::GetDirectoryName($ExePath)
    }
    if ([string]::IsNullOrWhiteSpace($exeDir)) { $exeDir = Get-ActLogDevReleaseDir }
    if (-not [string]::IsNullOrWhiteSpace($exeDir)) {
        $ud = [System.IO.Path]::Combine($exeDir, 'userdata')
        $out.Add([pscustomobject]@{
            Kind = 'userdata'; Path = $ud; Exists = [System.IO.Directory]::Exists($ud)
        })
    }

    if ($env:PROGRAMDATA) {
        $pd = [System.IO.Path]::Combine($env:PROGRAMDATA, 'actlog')
        $out.Add([pscustomobject]@{
            Kind = 'programdata'; Path = $pd; Exists = [System.IO.Directory]::Exists($pd)
        })
        $pdl = [System.IO.Path]::Combine($env:PROGRAMDATA, 'practilog')
        $out.Add([pscustomobject]@{
            Kind = 'programdata-legacy'; Path = $pdl; Exists = [System.IO.Directory]::Exists($pdl)
        })
    }
    if ($env:LOCALAPPDATA) {
        $fb = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'com.actlog', 'actlog-fallback')
        $out.Add([pscustomobject]@{
            Kind = 'localappdata-fallback'; Path = $fb; Exists = [System.IO.Directory]::Exists($fb)
        })
        $fbl = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'com.practiclog', 'practilog-fallback')
        $out.Add([pscustomobject]@{
            Kind = 'localappdata-fallback-legacy'; Path = $fbl; Exists = [System.IO.Directory]::Exists($fbl)
        })
    }
    if ($env:APPDATA) {
        $ad = [System.IO.Path]::Combine($env:APPDATA, 'com.actlog', 'actlog')
        $out.Add([pscustomobject]@{
            Kind = 'appdata'; Path = $ad; Exists = [System.IO.Directory]::Exists($ad)
        })
        $adl = [System.IO.Path]::Combine($env:APPDATA, 'com.practiclog', 'practilog')
        $out.Add([pscustomobject]@{
            Kind = 'appdata-legacy'; Path = $adl; Exists = [System.IO.Directory]::Exists($adl)
        })
    }
    return $out.ToArray()
}

function Resolve-ActLogDataDir {
    <#
      Returns [pscustomobject]@{ Path; Kind; Exists; Candidates } -- see the
      header comment for the rule. Never writes anything.
    #>
    [CmdletBinding()]
    param([string]$ExePath = '')

    $cands = @(Get-ActLogDataDirCandidate -ExePath $ExePath)
    if ($cands.Count -eq 0) {
        return [pscustomobject]@{ Path = ''; Kind = 'none'; Exists = $false; Candidates = @() }
    }
    if ($cands[0].Kind -eq 'pin') {
        return [pscustomobject]@{
            Path = $cands[0].Path; Kind = 'pin'; Exists = $cands[0].Exists; Candidates = $cands
        }
    }
    foreach ($c in $cands) {
        if ($c.Exists) {
            return [pscustomobject]@{
                Path = $c.Path; Kind = $c.Kind; Exists = $true; Candidates = $cands
            }
        }
    }
    # Nothing exists yet: hand back the install-layout dir the migrated app will
    # create, so "log file missing" keeps meaning "no log written yet".
    $primary = $cands | Where-Object { $_.Kind -eq 'userdata' } | Select-Object -First 1
    if (-not $primary) { $primary = $cands[0] }
    return [pscustomobject]@{
        Path = $primary.Path; Kind = $primary.Kind; Exists = $false; Candidates = $cands
    }
}

function ConvertTo-ActLogFileName {
    <#
      Maps a legacy file name onto the current one
      (practilog_startup.log -> actlog_startup.log). Unknown names are
      returned unchanged.
    #>
    [CmdletBinding()]
    param([string]$FileName = '')
    if ([string]::IsNullOrWhiteSpace($FileName)) { return $FileName }
    if ($FileName -match '^practilog') {
        return ('actlog' + $FileName.Substring('practilog'.Length))
    }
    return $FileName
}

function Resolve-ActLogLogFile {
    <#
      Full path of one log file inside the resolved data dir. The current file
      name wins; when it is absent but the legacy name is present in the same
      dir, the legacy path is returned so an unmigrated install stays readable.
      When neither exists the current path is returned, so "missing" still
      means "not written yet".
    #>
    [CmdletBinding()]
    param(
        [string]$ExePath = '',
        [Parameter(Mandatory = $true)][string]$FileName
    )
    $dir = Resolve-ActLogDataDir -ExePath $ExePath
    if ([string]::IsNullOrWhiteSpace($dir.Path)) { return $FileName }
    $current = ConvertTo-ActLogFileName -FileName $FileName
    $primary = [System.IO.Path]::Combine($dir.Path, $current)
    if ([System.IO.File]::Exists($primary)) { return $primary }
    if ($script:ActLogLegacyFileNames.ContainsKey($current)) {
        $legacy = [System.IO.Path]::Combine($dir.Path, $script:ActLogLegacyFileNames[$current])
        if ([System.IO.File]::Exists($legacy)) { return $legacy }
    }
    return $primary
}

# ---- legacy names kept as thin aliases (other scripts still call them) ----
Set-Alias -Name Get-PractiLogDevReleaseDir -Value Get-ActLogDevReleaseDir
Set-Alias -Name Get-PractiLogDataDirCandidate -Value Get-ActLogDataDirCandidate
Set-Alias -Name Resolve-PractiLogDataDir -Value Resolve-ActLogDataDir
Set-Alias -Name Resolve-PractiLogLogFile -Value Resolve-ActLogLogFile

# ---- thin convenience wrapper for callers without an exe path ----
if (-not $script:ActLogDataDir) {
    $script:ActLogDataDir = (Resolve-ActLogDataDir).Path
}
if (-not $script:ActLogStartupLog) {
    $script:ActLogStartupLog = Resolve-ActLogLogFile -FileName 'actlog_startup.log'
}
# legacy variable names, same values
$script:PractiLogDataDir = $script:ActLogDataDir
$script:PractiLogStartupLog = $script:ActLogStartupLog
