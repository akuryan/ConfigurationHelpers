' Starts Reap-ClaudeOrphans.ps1 (next to this file) with no console window.
' Task Scheduler shows console programs under an interactive logon (S4U registration can be denied,
' e.g. for Azure AD accounts), and "pwsh -WindowStyle Hidden" still flashes a window before hiding it.
' wscript is a GUI-subsystem host and honors windowStyle 0 (SW_HIDE) from the start.
' Registered by Install-ClaudeOrphanReaper.ps1 as: wscript.exe //B //Nologo "<this file>"
Option Explicit
Dim fso, sh, dir, ps1, pwsh
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
dir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1 = fso.BuildPath(dir, "Reap-ClaudeOrphans.ps1")
pwsh = fso.BuildPath(sh.ExpandEnvironmentStrings("%ProgramFiles%"), "PowerShell\7\pwsh.exe")
If Not fso.FileExists(pwsh) Then pwsh = "pwsh.exe"
sh.Run """" & pwsh & """ -NoProfile -NonInteractive -ExecutionPolicy Bypass -File """ & ps1 & """ -Source task", 0, False
