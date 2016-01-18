$name = "World Wide Web Services (HTTP Traffic-In)"
$rule = Get-NetFirewallRule -DisplayName $name
$ruleTime = [datetime]::ParseExact($rule.Description, 'yyyy-MM-dd HH:mm:ss',$null)
$file = '.\firewall.allow'
$fileTime = (Get-Item $file).LastWriteTime
$time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$tspan = New-TimeSpan $ruleTime $fileTime
$seconds = ($tspan).TotalSeconds
if ($seconds -lt 0) {
  echo "$time Firewall up-to-date, exitting"
  exit
}
echo "$time Loading new firewall rules"
$ips = New-Object Collections.Generic.List[String]
$lines = Get-Content $file
foreach ($line in $lines) {
  if ($line -match "^s*#") {
    continue
  } elseif ($line -match "^s*$") {
    continue
  } elseif ($line -match "^([0-9./]{7,18})s*(#.*)?$") {
    echo $matches[1]
    $ips.Add($line)
  } else {
    echo ("IGNORED: " + $line)
  }
}
# set new firewall rules
try {
  Set-NetFirewallRule -DisplayName $name -RemoteAddress $ips -Description $time
} catch {
  echo "ERROR: Firewall rules could not be loaded"
}