<#
.SYNOPSIS
    Installs or removes the Claude Code orphan reaper (scheduled task + SessionEnd hook).

.DESCRIPTION
    Copies Reap-ClaudeOrphans.ps1, Run-ReaperHidden.vbs and orphan-reaper.exclude.txt from this folder to
    ~\.claude\scripts, registers the scheduled task \Claude\Claude Orphan Reaper (every -IntervalMinutes,
    interactive logon of the current user, hidden via wscript, 5 min execution limit, no overlapping runs)
    and adds a SessionEnd hook to ~\.claude\settings.json that runs the reaper when a Claude Code session ends.

    Idempotent: re-running refreshes the files and the task; an existing hook that points at
    Reap-ClaudeOrphans.ps1 is updated in place, never duplicated. settings.json is backed up to
    settings.json.bak-<timestamp> before it is rewritten, and only rewritten when something changed.
    Other hooks and settings are preserved, key order included (PowerShell 7.3+).

    -Uninstall removes the task and the hook. The copied files stay unless -RemoveFiles is given.
    Supports -WhatIf and -Confirm.

.PARAMETER IntervalMinutes
    Scheduled task repetition interval. Default 10.
.PARAMETER Uninstall
    Remove the scheduled task and the SessionEnd hook.
.PARAMETER RemoveFiles
    With -Uninstall: also delete the three files from ~\.claude\scripts.
.PARAMETER SkipTask
    Do not touch the scheduled task.
.PARAMETER SkipHook
    Do not touch ~\.claude\settings.json.

.EXAMPLE
    pwsh -NoProfile -File .\Install-ClaudeOrphanReaper.ps1 -WhatIf
    pwsh -NoProfile -File .\Install-ClaudeOrphanReaper.ps1
    pwsh -NoProfile -File .\Install-ClaudeOrphanReaper.ps1 -Uninstall -RemoveFiles
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateRange(1, 1440)]
    [int]$IntervalMinutes = 10,
    [switch]$Uninstall,
    [switch]$RemoveFiles,
    [switch]$SkipTask,
    [switch]$SkipHook
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$TaskPath     = '\Claude\'
$TaskName     = 'Claude Orphan Reaper'
$ClaudeDir    = Join-Path $HOME '.claude'
$ScriptsDir   = Join-Path $ClaudeDir 'scripts'
$SettingsPath = Join-Path $ClaudeDir 'settings.json'
$LogPath      = Join-Path $ClaudeDir 'logs\orphan-reaper.log'
$Files        = @('Reap-ClaudeOrphans.ps1', 'Run-ReaperHidden.vbs', 'orphan-reaper.exclude.txt')
$ReaperPath   = Join-Path $ScriptsDir 'Reap-ClaudeOrphans.ps1'
$VbsPath      = Join-Path $ScriptsDir 'Run-ReaperHidden.vbs'
$HookMarker   = 'Reap-ClaudeOrphans.ps1'
$HookTimeout  = 20
# Forward slashes: Claude Code runs hook commands through a POSIX-style shell on Windows as well.
$HookCommand  = 'pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -Source hook' -f ($ReaperPath -replace '\\', '/')

# --- Preconditions -------------------------------------------------------------------------
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Run this with PowerShell 7 (pwsh), not Windows PowerShell 5.1.' }
if ([IntPtr]::Size -ne 8) { throw 'The reaper reads process environment blocks via the x64 PEB layout; 64-bit PowerShell is required.' }
if (-not $IsWindows) { throw 'Windows only.' }
$pwshExe = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
if (-not (Test-Path $pwshExe) -and -not (Get-Command pwsh.exe -ErrorAction SilentlyContinue)) {
    throw "pwsh.exe not found at '$pwshExe' nor on PATH; the hidden launcher needs one of them."
}

# --- settings.json helpers -----------------------------------------------------------------
function Read-Settings {
    if (-not (Test-Path $SettingsPath)) { return [ordered]@{} }
    $raw = Get-Content -Path $SettingsPath -Raw -Encoding utf8
    if (-not $raw.Trim()) { return [ordered]@{} }
    return ($raw | ConvertFrom-Json -AsHashtable -Depth 64)
}

function Write-Settings($settings) {
    $json = $settings | ConvertTo-Json -Depth 64
    $null = $json | ConvertFrom-Json -Depth 64            # must round-trip before the file is touched
    if ($PSCmdlet.ShouldProcess($SettingsPath, 'rewrite (backup kept)')) {
        if (Test-Path $SettingsPath) {
            $bak = '{0}.bak-{1}' -f $SettingsPath, (Get-Date).ToString('yyyyMMdd-HHmmss')
            Copy-Item -Path $SettingsPath -Destination $bak -Force
            Write-Host "settings.json backed up to $bak"
        }
        [System.IO.File]::WriteAllText($SettingsPath, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
        return $true
    }
    return $false
}

# Emits every command hook under hooks.SessionEnd whose command mentions the reaper script. Callers wrap the
# call in @(): collecting command output that way yields a flat array, whereas 'return , $found' would nest it.
function Find-ReaperHooks($settings) {
    $found = @()
    if ($settings.Contains('hooks') -and $null -ne $settings['hooks'] -and $settings['hooks'].Contains('SessionEnd')) {
        foreach ($group in @($settings['hooks']['SessionEnd'])) {
            if ($null -eq $group -or -not $group.Contains('hooks')) { continue }
            foreach ($h in @($group['hooks'])) {
                if ($null -ne $h -and $h.Contains('command') -and "$($h['command'])" -like "*$HookMarker*") { $found += , $h }
            }
        }
    }
    return $found
}

function Install-Hook {
    $settings = Read-Settings
    $existing = @(Find-ReaperHooks $settings)
    if ($existing.Count -gt 0) {
        $changed = $false
        foreach ($h in $existing) {
            if (-not $h.Contains('type') -or $h['type'] -ne 'command') { $h['type'] = 'command'; $changed = $true }
            if ($h['command'] -ne $HookCommand) {
                Write-Host "SessionEnd hook command changes from: $($h['command'])"
                $h['command'] = $HookCommand; $changed = $true
            }
            if (-not $h.Contains('timeout') -or $h['timeout'] -ne $HookTimeout) { $h['timeout'] = $HookTimeout; $changed = $true }
        }
        if ($changed) { if (Write-Settings $settings) { Write-Host 'SessionEnd hook updated.' } }
        else { Write-Host 'SessionEnd hook already present and current.' }
        return
    }
    if (-not $settings.Contains('hooks') -or $null -eq $settings['hooks']) { $settings['hooks'] = [ordered]@{} }
    $hooks = $settings['hooks']
    $group = [ordered]@{ hooks = @([ordered]@{ type = 'command'; command = $HookCommand; timeout = $HookTimeout }) }
    if ($hooks.Contains('SessionEnd') -and $null -ne $hooks['SessionEnd']) { $hooks['SessionEnd'] = @($hooks['SessionEnd']) + @($group) }
    else { $hooks['SessionEnd'] = @($group) }
    if (Write-Settings $settings) { Write-Host 'SessionEnd hook added.' }
}

function Uninstall-Hook {
    $settings = Read-Settings
    if (@(Find-ReaperHooks $settings).Count -eq 0) { Write-Host 'No SessionEnd hook for the reaper found.'; return }
    $hooks = $settings['hooks']
    $keptGroups = @()
    foreach ($group in @($hooks['SessionEnd'])) {
        if ($null -eq $group -or -not $group.Contains('hooks')) { $keptGroups += , $group; continue }
        $kept = @(@($group['hooks']) | Where-Object { -not ($_.Contains('command') -and "$($_['command'])" -like "*$HookMarker*") })
        if ($kept.Count -gt 0) { $group['hooks'] = $kept; $keptGroups += , $group }
    }
    if ($keptGroups.Count -gt 0) { $hooks['SessionEnd'] = $keptGroups } else { $hooks.Remove('SessionEnd') }
    if ($hooks.Count -eq 0) { $settings.Remove('hooks') }
    if (Write-Settings $settings) { Write-Host 'SessionEnd hook removed.' }
}

# --- Scheduled task helpers ----------------------------------------------------------------
function Install-Task {
    $action  = New-ScheduledTaskAction -Execute (Join-Path $env:SystemRoot 'System32\wscript.exe') -Argument ('//B //Nologo "{0}"' -f $VbsPath)
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)
    $taskSettingsArgs = @{
        ExecutionTimeLimit         = New-TimeSpan -Minutes 5
        MultipleInstances          = 'IgnoreNew'
        StartWhenAvailable         = $true
        AllowStartIfOnBatteries    = $true
        DontStopIfGoingOnBatteries = $true
    }
    $taskSettings = New-ScheduledTaskSettingsSet @taskSettingsArgs
    # SID instead of a name: works for local, domain and Azure AD accounts alike. Interactive logon = no stored
    # password and no S4U registration, which is denied for some Azure AD accounts.
    $sid       = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $principal = New-ScheduledTaskPrincipal -UserId $sid -LogonType Interactive -RunLevel Limited
    $registerArgs = @{
        TaskName    = $TaskName
        TaskPath    = $TaskPath
        Action      = $action
        Trigger     = $trigger
        Settings    = $taskSettings
        Principal   = $principal
        Description = "Kills tool processes left behind by Claude Code sessions, hidden via Run-ReaperHidden.vbs (see $ReaperPath). Log: $LogPath"
        Force       = $true
    }
    if ($PSCmdlet.ShouldProcess("$TaskPath$TaskName", "register scheduled task (every $IntervalMinutes min)")) {
        $null = Register-ScheduledTask @registerArgs
        Write-Host "Scheduled task $TaskPath$TaskName registered (every $IntervalMinutes min)."
    }
}

function Uninstall-Task {
    $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
    if (-not $task) { Write-Host "Scheduled task $TaskPath$TaskName not found."; return }
    if ($PSCmdlet.ShouldProcess("$TaskPath$TaskName", 'unregister scheduled task')) {
        Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
        Write-Host "Scheduled task $TaskPath$TaskName removed."
    }
}

# --- Main ----------------------------------------------------------------------------------
if ($Uninstall) {
    if (-not $SkipTask) { Uninstall-Task }
    if (-not $SkipHook) { Uninstall-Hook }
    if ($RemoveFiles) {
        foreach ($f in $Files) {
            $p = Join-Path $ScriptsDir $f
            if ((Test-Path $p) -and $PSCmdlet.ShouldProcess($p, 'delete')) { Remove-Item -Path $p -Force }
        }
        if (-not $WhatIfPreference) { Write-Host "Files removed from $ScriptsDir." }
    }
    exit 0
}

foreach ($f in $Files) {
    $src = Join-Path $PSScriptRoot $f
    if (-not (Test-Path $src)) { throw "Missing $src; run this script from the folder that holds the reaper files." }
}
if (-not (Test-Path $ScriptsDir) -and $PSCmdlet.ShouldProcess($ScriptsDir, 'create directory')) {
    New-Item -ItemType Directory -Path $ScriptsDir -Force | Out-Null
}
foreach ($f in $Files) {
    $src = Join-Path $PSScriptRoot $f
    $dst = Join-Path $ScriptsDir $f
    if ($PSCmdlet.ShouldProcess($dst, "copy from $src")) { Copy-Item -Path $src -Destination $dst -Force }
}
if (-not $WhatIfPreference) { Write-Host "Files copied to $ScriptsDir." }
if (-not $SkipTask) { Install-Task }
if (-not $SkipHook) { Install-Hook }

Write-Host ''
Write-Host 'Verify:'
Write-Host ('  pwsh -NoProfile -File "{0}" -DryRun -MinAgeMinutes 0' -f $ReaperPath)
Write-Host ("  Get-ScheduledTaskInfo -TaskName '{0}' -TaskPath '{1}'" -f $TaskName, $TaskPath)
Write-Host ('  Get-Content "{0}" -Tail 20' -f $LogPath)
