# Generates password

Param(
	[int]$length=15
)

 
$ascii=$NULL;For ($a=33;$a –le 126;$a++) {$ascii+=,[char][byte]$a }
For ($loop=1; $loop –le $length; $loop++) {

            $TempPassword+=($ascii | GET-RANDOM)

            }

Write-Host $TempPassword