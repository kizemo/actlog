; actlog installer (Inno Setup 6). Per-user install, no admin rights needed.
; NOTE: this file is re-saved as UTF-8 WITH BOM before compiling (Inno detects UTF-8 by BOM).
; LEGACY NOTE: this script is NOT the packager in use -- tools\build\installer.nsi
; (NSIS) is the only packager that runs. This file is kept as a second path for
; an Inno Setup machine and was renamed from practilog_setup.iss.
#define MyAppName "知行日志"
#define MyAppVer "1.0.0"
#define MyAppPublisher "actlog"
#define MyAppExe "actlog.exe"
#define MySrcDir "F:\soft\00selfmade\practilog\apps\desktop\build\windows\x64\runner\Release"

[Setup]
AppId={{8F3C2A11-6D2E-4B7A-9C55-1E7D4A6B0C21}
AppName={#MyAppName}
AppVersion={#MyAppVer}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\actlog
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=F:\soft\00selfmade\practilog\release
OutputBaseFilename=actlog-Setup-1.0.0
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExe}
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
Source: "{#MySrcDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.pdb,*.exp,*.lib,*.ilk"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExe}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
