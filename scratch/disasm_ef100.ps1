$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] 60
$fileOff = 0xEF100 - 0x1000 + 0x400
$fs.Position = $fileOff
$fs.Read($bytes, 0, 60) | Out-Null
$fs.Close()
Write-Host "Disassembly at RVA 0xEF100:"
Write-Host ([BitConverter]::ToString($bytes))
