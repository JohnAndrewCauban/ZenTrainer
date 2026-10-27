$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] 120
$fileOff = 0xADD00 - 0x1000 + 0x400
$fs.Position = $fileOff
$fs.Read($bytes, 0, 120) | Out-Null
$fs.Close()
Write-Host "Disasm before RVA 0xADD40:"
Write-Host ([BitConverter]::ToString($bytes))
