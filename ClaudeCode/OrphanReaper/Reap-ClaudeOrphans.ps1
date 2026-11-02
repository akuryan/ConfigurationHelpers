<#
.SYNOPSIS
    Kills tool processes that Claude Code left behind on Windows.

.DESCRIPTION
    Claude Code on Windows starts the Bash/PowerShell tool through a launcher (bash.exe,
    cmd.exe) without a kill-on-close job object. When a tool call times out, a background
    task is stopped or a session ends, only the launcher dies and its children (kubectl,
    git, helm, find, sleep, ...) keep running. Upstream issues 62659 / 90672 / 92583.

    A process is reaped when ALL of the following hold:
      * its parent process no longer exists (or the PID was reused by a younger process),
      * it is older than -MinAgeMinutes,
      * its environment block contains CLAUDECODE=... (inherited from the Claude session)
        -> log reason "orphan"; OR it is a transient MSYS coreutil (sleep, tail, find, grep,
        sh, bash, ...) running from Git's usr\bin -> log reason "msys-orphan". MSYS children of
        Git Bash receive only a 5-variable Win32 environment (MSYSTEM, PATH, SYSTEMDRIVE,
        SYSTEMROOT, WINDIR), so the marker cannot be seen on them; verified 2026-10-31.
        Native tools (kubectl, helm, git, node, pwsh, cmd, ping, conhost) do carry the marker.
      * its name or command line matches no line of orphan-reaper.exclude.txt (next to this script).
    Live descendants of a reaped process are reaped with it. The user's own Git Bash terminals
    have a live parent (Windows Terminal) and no marker, so they are never touched.

    Every kill (or would-kill with -DryRun), every error and a per-run summary (scheduled-task
    runs only when something was reaped) is appended to
    ~\.claude\logs\orphan-reaper.log (override with -LogPath).
    Install-ClaudeOrphanReaper.ps1 (same folder) registers it as scheduled task \Claude\Claude Orphan Reaper
    (every 10 min, interactive logon, started via Run-ReaperHidden.vbs so no console window flashes) and as
    a SessionEnd hook in ~\.claude\settings.json (timeout 20 s). See README.md.

.PARAMETER Source
    Free text for the log: task | hook | manual (default).
.PARAMETER DryRun
    Report what would be killed, kill nothing.
.PARAMETER MinAgeMinutes
    Minimum process age before it is considered. Default 2.
.PARAMETER InspectPid
    Diagnostic: print the CLAUDE* environment variables of one process and exit.
.PARAMETER LogPath
    Log file. Default ~\.claude\logs\orphan-reaper.log; the directory is created when missing.

.EXAMPLE
    pwsh -NoProfile -File Reap-ClaudeOrphans.ps1 -DryRun -MinAgeMinutes 0
    pwsh -NoProfile -File Reap-ClaudeOrphans.ps1 -InspectPid 22856
#>
[CmdletBinding()]
param(
    [string]$Source = 'manual',
    [switch]$DryRun,
    [double]$MinAgeMinutes = 2,
    [int]$InspectPid = 0,
    [string]$LogPath = (Join-Path $HOME '.claude\logs\orphan-reaper.log')
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

# --- Read another process's environment block (x64 PEB -> RTL_USER_PROCESS_PARAMETERS). ---
# Offsets: PEB.ProcessParameters 0x20; Environment 0x80; EnvironmentSize 0x3F0 (x64, Vista+).
# Same technique as Process Explorer and the ProcessEx module; kept inline so the scheduled
# task has no module dependency.
if (-not ('ClaudeReaper.ProcEnv' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

namespace ClaudeReaper {
public static class ProcEnv {
    [StructLayout(LayoutKind.Sequential)]
    struct PROCESS_BASIC_INFORMATION {
        public IntPtr Reserved1;
        public IntPtr PebBaseAddress;
        public IntPtr Reserved2_0;
        public IntPtr Reserved2_1;
        public IntPtr UniqueProcessId;
        public IntPtr Reserved3;
    }
    [DllImport("ntdll.dll")]
    static extern int NtQueryInformationProcess(IntPtr h, int cls, ref PROCESS_BASIC_INFORMATION pbi, int len, out int ret);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, IntPtr size, out IntPtr read);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool CloseHandle(IntPtr h);

    const uint PROCESS_QUERY_INFORMATION = 0x0400;
    const uint PROCESS_VM_READ = 0x0010;

    static IntPtr ReadPtr(IntPtr h, IntPtr addr) {
        byte[] buf = new byte[8];
        IntPtr read;
        if (!ReadProcessMemory(h, addr, buf, (IntPtr)8, out read) || read.ToInt64() != 8) return IntPtr.Zero;
        return (IntPtr)BitConverter.ToInt64(buf, 0);
    }

    // Returns the raw UTF-16 environment block ("A=1<nul>B=2<nul><nul>") or null when unreadable.
    public static string GetEnvironmentBlock(int pid) {
        if (IntPtr.Size != 8) throw new PlatformNotSupportedException("64-bit PowerShell required");
        IntPtr h = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, false, pid);
        if (h == IntPtr.Zero) return null;
        try {
            PROCESS_BASIC_INFORMATION pbi = new PROCESS_BASIC_INFORMATION();
            int ret;
            if (NtQueryInformationProcess(h, 0, ref pbi, Marshal.SizeOf(pbi), out ret) != 0) return null;
            if (pbi.PebBaseAddress == IntPtr.Zero) return null;
            IntPtr prm = ReadPtr(h, (IntPtr)(pbi.PebBaseAddress.ToInt64() + 0x20));
            if (prm == IntPtr.Zero) return null;
            IntPtr env = ReadPtr(h, (IntPtr)(prm.ToInt64() + 0x80));
            if (env == IntPtr.Zero) return null;
            long size = ReadPtr(h, (IntPtr)(prm.ToInt64() + 0x3F0)).ToInt64();
            if (size <= 0 || size > 8 * 1024 * 1024) return null;
            byte[] buf = new byte[size];
            IntPtr got;
            if (!ReadProcessMemory(h, env, buf, (IntPtr)buf.Length, out got)) return null;
            return Encoding.Unicode.GetString(buf, 0, (int)got.ToInt64());
        } finally { CloseHandle(h); }
    }
}
}
'@
}

function Get-ProcessEnvVars([int]$ProcId) {
    $block = $null
    try { $block = [ClaudeReaper.ProcEnv]::GetEnvironmentBlock($ProcId) } catch { $block = $null }
    if (-not $block) { return $null }
    $vars = @{}
    foreach ($entry in $block.Split([char]0)) {
        if ($entry.Length -lt 2) { continue }
        $i = $entry.IndexOf('=', 1)            # entries like =C:=C:\path start with '=', skip that char
        if ($i -lt 1) { continue }
        $vars[$entry.Substring(0, $i).ToUpperInvariant()] = $entry.Substring($i + 1)
    }
    return $vars
}

function Write-ReaperLog([string]$Line) {
    $dir = Split-Path $LogPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $stamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
    Add-Content -Path $LogPath -Value "$stamp | $Source | $Line" -Encoding utf8
}

# --- Diagnostic mode ---------------------------------------------------------------------
if ($InspectPid -gt 0) {
    $vars = Get-ProcessEnvVars $InspectPid
    if ($null -eq $vars) { Write-Output "pid $InspectPid : environment not readable (exited, protected, or access denied)"; exit 0 }
    $claude = @($vars.GetEnumerator() | Where-Object { $_.Key -like 'CLAUDE*' } | Sort-Object Key)
    Write-Output ("pid {0} : {1} env vars, {2} CLAUDE* vars" -f $InspectPid, $vars.Count, $claude.Count)
    $claude | ForEach-Object { Write-Output ("  {0}={1}" -f $_.Key, $_.Value) }
    exit 0
}

# --- Sweep -------------------------------------------------------------------------------
try {
    $excludes = @()
    $excludeFile = Join-Path $PSScriptRoot 'orphan-reaper.exclude.txt'
    if (Test-Path $excludeFile) {
        $excludes = @(Get-Content $excludeFile | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
    }

    # MSYS fallback: transient coreutils under Git's usr\bin (see .DESCRIPTION). Deliberately an
    # allowlist so ssh.exe / ssh-agent.exe / gpg-agent.exe tunnels and agents with a dead parent survive.
    $gitRoot = (Get-ItemProperty 'HKLM:\SOFTWARE\GitForWindows' -ErrorAction SilentlyContinue).InstallPath
    if (-not $gitRoot) { $gitRoot = 'C:\Program Files\Git' }
    $msysBin = (Join-Path $gitRoot 'usr\bin').TrimEnd('\') + '\'
    $msysTransient = '^(sleep|tail|head|cat|find|grep|egrep|fgrep|sort|uniq|tee|xargs|timeout|watch|less|more|awk|gawk|sed|tr|wc|cut|yes|env|nohup|sh|bash|dash)\.exe$'

    $now = Get-Date
    $all = @(Get-CimInstance Win32_Process -Property ProcessId, ParentProcessId, Name, CreationDate, CommandLine, WorkingSetSize, ExecutablePath -Verbose:$false)
    $byPid = @{}
    foreach ($p in $all) { $byPid[[uint32]$p.ProcessId] = $p }

    # Never touch ourselves or our own ancestors (the hook runs as a child of the live claude.exe).
    $protected = @{}
    $cur = $byPid[[uint32]$PID]
    while ($cur) {
        $protected[[uint32]$cur.ProcessId] = $true
        $cur = $byPid[[uint32]$cur.ParentProcessId]
        if ($cur -and $protected.ContainsKey([uint32]$cur.ProcessId)) { break }
    }

    function Test-Excluded($p) {
        foreach ($rx in $excludes) {
            if ($p.Name -match $rx) { return $true }
            if ($p.CommandLine -and $p.CommandLine -match $rx) { return $true }
        }
        return $false
    }
    function Test-ParentGone($p) {
        if ($p.ParentProcessId -eq 0) { return $false }
        $parent = $byPid[[uint32]$p.ParentProcessId]
        if (-not $parent) { return $true }
        # PID reuse: a "parent" created after its child cannot be the real parent.
        if ($parent.CreationDate -and $p.CreationDate -and $parent.CreationDate -gt $p.CreationDate) { return $true }
        return $false
    }

    # Roots: dead parent + old enough + Claude marker + not excluded.
    $victims = @{}
    foreach ($p in $all) {
        if ($p.ProcessId -le 4 -or $protected.ContainsKey([uint32]$p.ProcessId)) { continue }
        if (-not (Test-ParentGone $p)) { continue }
        if (-not $p.CreationDate) { continue }
        $ageMin = ($now - $p.CreationDate).TotalMinutes
        if ($ageMin -lt $MinAgeMinutes) { continue }
        $vars = Get-ProcessEnvVars ([int]$p.ProcessId)
        $reason = $null
        if ($vars -and $vars.ContainsKey('CLAUDECODE')) { $reason = 'orphan' }
        elseif ($p.Name -match $msysTransient -and $p.ExecutablePath -and
                $p.ExecutablePath.StartsWith($msysBin, [StringComparison]::OrdinalIgnoreCase)) { $reason = 'msys-orphan' }
        if (-not $reason) { continue }
        if (Test-Excluded $p) { Write-Verbose "skip excluded root pid=$($p.ProcessId) $($p.Name)"; continue }
        $victims[[uint32]$p.ProcessId] = $reason
    }

    # Descendants of a root die with it (same session environment, launcher already gone).
    if ($victims.Count -gt 0) {
        $changed = $true
        while ($changed) {
            $changed = $false
            foreach ($p in $all) {
                $id = [uint32]$p.ProcessId
                if ($victims.ContainsKey($id) -or $protected.ContainsKey($id)) { continue }
                $parent = $byPid[[uint32]$p.ParentProcessId]
                if ($parent -and $victims.ContainsKey([uint32]$parent.ProcessId) -and $parent.CreationDate -le $p.CreationDate) {
                    if (Test-Excluded $p) { continue }
                    $victims[$id] = 'child-of-' + $parent.ProcessId
                    $changed = $true
                }
            }
        }
    }

    $action = if ($DryRun) { 'would-kill' } else { 'kill' }
    foreach ($id in ($victims.Keys | Sort-Object)) {
        $p = $byPid[$id]
        $ageMin = [math]::Round(($now - $p.CreationDate).TotalMinutes, 1)
        $ws = [math]::Round($p.WorkingSetSize / 1MB)
        $cmd = if ($p.CommandLine) { $p.CommandLine } else { '' }
        if ($cmd.Length -gt 300) { $cmd = $cmd.Substring(0, 300) + '...' }
        $line = "$action | pid=$id | $($p.Name) | reason=$($victims[$id]) | parent=$($p.ParentProcessId) | age_min=$ageMin | ws_mb=$ws | $cmd"
        if (-not $DryRun) {
            try { Stop-Process -Id $id -Force -ErrorAction Stop }
            catch { $line = "error | pid=$id | $($p.Name) | $($_.Exception.Message)" }
        }
        Write-ReaperLog $line
        Write-Output $line
    }
    # One summary line per run, except for silent scheduled-task runs (every 10 min would be noise).
    if ($Source -ne 'task' -or $victims.Count -gt 0) {
        Write-ReaperLog ("run | scanned={0} reaped={1} dryrun={2}" -f $all.Count, $victims.Count, [bool]$DryRun)
    }
    Write-Verbose ("scanned {0} processes, {1} reaped" -f $all.Count, $victims.Count)
}
catch {
    try { Write-ReaperLog ("error | sweep failed | " + $_.Exception.Message) } catch {}
    Write-Error $_
}
exit 0
