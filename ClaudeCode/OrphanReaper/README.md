# Claude Code Orphan Reaper

On Windows, Claude Code starts its Bash/PowerShell tool through a launcher (`bash.exe` / `cmd.exe`) that has no
kill-on-close job object. When a tool call times out, a background task is stopped or the session ends, only the
launcher dies. Its children (`kubectl`, `git`, `helm`, `find`, `sleep`, `sed`, `cat`, ...) keep running and pile up.
This is tracked upstream in
[#62659](https://github.com/anthropics/claude-code/issues/62659) (closed),
[#90672](https://github.com/anthropics/claude-code/issues/90672) (open) and
[#92583](https://github.com/anthropics/claude-code/issues/92583) (open), status as of 2026-11-02.
This folder is a safety net until that is fixed upstream: a script that finds and kills such leftovers, plus an
installer that runs it every 10 minutes and when a Claude Code session ends.

## What it does

A process is reaped when all of the following hold:

- Its parent process no longer exists, or the parent PID was reused by a process younger than the child.
- It is older than `-MinAgeMinutes` (default 2).
- It carries the `CLAUDECODE` environment variable (log reason `orphan`), or it is a transient MSYS coreutil
  running from Git's `usr\bin` (log reason `msys-orphan`).
- Its name or command line matches no regex in `orphan-reaper.exclude.txt`.

Further rules:

- The `CLAUDECODE` marker is read from the other process's memory (PEB, via `NtQueryInformationProcess` and
  `ReadProcessMemory`, inline C#, x64 only).
- The MSYS rule exists because MSYS children receive only a 5-variable environment (`MSYSTEM`, `PATH`,
  `SYSTEMDRIVE`, `SYSTEMROOT`, `WINDIR`), so the marker is invisible on them. It is an allowlist of executable
  names: `sleep tail head cat find grep egrep fgrep sort uniq tee xargs timeout watch less more awk gawk sed tr wc
  cut yes env nohup sh bash dash`. Other tools from `usr\bin` (`ssh`, `ssh-agent`, `gpg-agent`) are not touched.
  Native tools (`kubectl`, `helm`, `git`, `node`, `pwsh`, `cmd`, `ping`, `conhost`) do carry the marker.
- Descendants of a reaped process are reaped with it.
- The script never touches itself or its own ancestors (the SessionEnd hook runs as a child of the live
  `claude.exe`).
- Your own Git Bash terminals have a live parent (Windows Terminal) and no marker, so they are not touched.

Delivery:

- Scheduled task `\Claude\Claude Orphan Reaper`, every 10 minutes, interactive logon of the current user
  (SID-based principal, no stored password), 5-minute execution limit, overlapping runs ignored, start when
  available. It is launched through `wscript.exe //B //Nologo Run-ReaperHidden.vbs` so that no console window
  flashes. `pwsh -WindowStyle Hidden` still flashes a window, and S4U registration is denied for some Azure AD
  accounts, which is why the task uses interactive logon.
- A `SessionEnd` hook in `~\.claude\settings.json` with a 20 second timeout.

## Files

| File | Purpose |
| --- | --- |
| `Reap-ClaudeOrphans.ps1` | The reaper: sweeps, kills, logs. Also has the `-InspectPid` diagnostic. |
| `Install-ClaudeOrphanReaper.ps1` | Installs or removes the scheduled task and the SessionEnd hook. Idempotent. |
| `Run-ReaperHidden.vbs` | `wscript` launcher that starts the reaper in `pwsh` with a hidden window. |
| `orphan-reaper.exclude.txt` | Regexes of processes that must never be killed. Default: `^claude\.exe$`. |

## Install

```powershell
git clone https://github.com/akuryan/ConfigurationHelpers.git
cd ConfigurationHelpers\ClaudeCode\OrphanReaper

# Preview: shows what would be copied, registered and rewritten, changes nothing
pwsh -NoProfile -File .\Install-ClaudeOrphanReaper.ps1 -WhatIf

# Real run
pwsh -NoProfile -File .\Install-ClaudeOrphanReaper.ps1
```

Run it with `pwsh` (PowerShell 7), not Windows PowerShell 5.1; the installer refuses to run otherwise. No elevated
shell is needed: the task is registered under your own account (verified from a non-admin shell on Windows 11
with an Azure AD account).

What the installer changes on the machine:

1. Copies the three runtime files (`Reap-ClaudeOrphans.ps1`, `Run-ReaperHidden.vbs`, `orphan-reaper.exclude.txt`)
   to `~\.claude\scripts`, creating the folder if needed and overwriting existing copies. The task and the hook
   run these copies, not the clone.
2. Registers the scheduled task `\Claude\Claude Orphan Reaper`, replacing an existing one of the same name. The
   first run is about a minute after installation.
3. Adds a `SessionEnd` hook to `~\.claude\settings.json`. The file is first backed up to
   `settings.json.bak-<yyyyMMdd-HHmmss>` and only rewritten when something changed. Other hooks and settings are
   preserved, including key order on PowerShell 7.3+. The file is re-serialized, so whitespace may differ from
   the original; the backup keeps the original.

The hook is added as a new group under `hooks.SessionEnd`; its command entry looks like this (forward slashes in
the path, because Claude Code runs hook commands through a POSIX-style shell on Windows as well):

```json
{
  "type": "command",
  "command": "pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"C:/Users/<you>/.claude/scripts/Reap-ClaudeOrphans.ps1\" -Source hook",
  "timeout": 20
}
```

Re-running the installer is safe: it refreshes the files and the task, and updates an existing reaper hook in
place instead of adding a second one. Run it again after pulling a newer version of this folder.

Other installer parameters: `-IntervalMinutes <1-1440>` (task interval, default 10), `-SkipTask` and `-SkipHook`
(leave the task or `settings.json` alone), `-Confirm`, and `-Uninstall` / `-RemoveFiles` (see
[Uninstall](#uninstall)).

## Verify

These are the three commands the installer prints at the end:

```powershell
# 1. Report what would be reaped right now, regardless of process age; kills nothing
pwsh -NoProfile -File "$HOME\.claude\scripts\Reap-ClaudeOrphans.ps1" -DryRun -MinAgeMinutes 0

# 2. Confirm the scheduled task exists and has run
Get-ScheduledTaskInfo -TaskName 'Claude Orphan Reaper' -TaskPath '\Claude\'

# 3. Read the log
Get-Content "$HOME\.claude\logs\orphan-reaper.log" -Tail 20
```

## Diagnostics

```powershell
$reaper = "$HOME\.claude\scripts\Reap-ClaudeOrphans.ps1"

# -DryRun: report what would be killed, kill nothing.
# -MinAgeMinutes: minimum process age before it is considered (default 2).
pwsh -NoProfile -File $reaper -DryRun -MinAgeMinutes 0

# -InspectPid: print the CLAUDE* environment variables of one process and exit
pwsh -NoProfile -File $reaper -InspectPid 22856

# -Source: free text for the log (task, hook or manual; default manual).
# -LogPath: log file (default ~\.claude\logs\orphan-reaper.log; the directory is created when missing).
# A dry run still writes would-kill lines to the log, so point it elsewhere for experiments.
pwsh -NoProfile -File $reaper -DryRun -Source test -LogPath "$env:TEMP\reaper-test.log"
```

`-InspectPid` prints `pid <n> : <count> env vars, <count> CLAUDE* vars` followed by those variables, or
`environment not readable (exited, protected, or access denied)`. An MSYS coreutil shows 5 variables and no
`CLAUDE*` ones, which is why the MSYS rule is separate.

Log format, one line per event:

```text
2026-10-31T08:00:40 | task | kill | pid=21248 | conhost.exe | reason=orphan | parent=26348 | age_min=4.4 | ws_mb=15 | \??\C:\WINDOWS\system32\conhost.exe 0x4
2026-10-31T08:02:25 | hook | kill | pid=19040 | nohup.exe | reason=msys-orphan | parent=18704 | age_min=3.2 | ws_mb=14 | "C:\Program Files\Git\usr\bin\nohup.exe" ping -n 200 127.0.0.1
2026-10-31T08:02:25 | hook | kill | pid=26232 | PING.EXE | reason=child-of-19040 | parent=19040 | age_min=3.2 | ws_mb=13 | C:\WINDOWS\system32\ping.exe -n 200 127.0.0.1
2026-11-02T12:25:26 | task | run | scanned=509 reaped=2 dryrun=False
```

Actions are `kill`, `would-kill` (dry run) and `error`. Reasons are `orphan`, `msys-orphan` and
`child-of-<pid>`. Scheduled-task runs write the `run` summary line only when something was reaped; manual and
hook runs always write it. Command lines are logged (truncated to 300 characters), so review the log before
pasting it into a bug report.

### Exclude file

`orphan-reaper.exclude.txt` holds one regular expression per line. Blank lines and lines starting with `#` are
ignored. Each regex is matched, case-insensitively, against both the process name and the full command line, so
anchor patterns you want to be exact. A matching process is never killed, and its children are not pulled in
with it. The shipped file contains:

```text
^claude\.exe$
```

The reaper reads the file next to the script it runs, which is the installed copy in `~\.claude\scripts`. Edit
that copy. Re-running the installer overwrites it with the version from this folder, so keep your additions in
the clone as well.

## Uninstall

```powershell
# Remove the scheduled task and the SessionEnd hook (add -WhatIf to preview)
pwsh -NoProfile -File .\Install-ClaudeOrphanReaper.ps1 -Uninstall

# Also delete the three files from ~\.claude\scripts, including your edited exclude file
pwsh -NoProfile -File .\Install-ClaudeOrphanReaper.ps1 -Uninstall -RemoveFiles
```

Only the reaper's own hook is removed from `settings.json` (after a backup, as on install). The log file and the
`settings.json.bak-*` backups are left in place; delete them by hand if you want them gone.

## Requirements and limitations

Requirements:

- Windows 10 or 11, x64.
- PowerShell 7 (`pwsh`). 7.3 or newer for the key-order-preserving rewrite of `settings.json`.
- Git for Windows, for the MSYS rule. Optional: without it only the `CLAUDECODE` marker rule is useful. The
  install path is read from `HKLM:\SOFTWARE\GitForWindows`, falling back to `C:\Program Files\Git`.
- Claude Code with hooks support (for the `SessionEnd` hook).

Limitations:

- x64 only; the environment block is read through the x64 PEB layout.
- A fresh orphan lives for up to one task cycle plus the age threshold (about 12 minutes with the defaults).
- The MSYS allowlist only covers Git's `usr\bin`. Other orphans are caught only if they carry the marker.
- The MSYS rule does not look for the marker: an allowlisted coreutil from Git's `usr\bin` with a dead parent
  and an age above the threshold is reaped whether or not Claude Code started it. Add a line to the exclude file
  if you rely on such a process.
- Processes whose memory cannot be read are skipped by the marker rule.
- This is a safety net, not a fix for the upstream issues. Still bound long commands with coreutils `timeout`
  (for example `timeout 60 kubectl get pods`) and stop background tasks before ending a session. In PowerShell,
  Windows `timeout.exe` is a delay, not a limit.
