# Generates password
# Got it from https://blogs.technet.microsoft.com/heyscriptingguy/2013/06/03/generating-a-new-password-with-windows-powershell/
Param(
	[int]$length=15
)

 
$ascii=$NULL;For ($a=48;$a –le 122;$a++) {$ascii+=,[char][byte]$a }
For ($loop=1; $loop –le $length; $loop++) {

            $TempPassword+=($ascii | GET-RANDOM)

            }

Write-Host $TempPassword