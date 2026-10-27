$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] 160
$fileOff = 0xF1290 - 0x1000 + 0x400
$fs.Position = $fileOff
$fs.Read($bytes, 0, 160) | Out-Null
$fs.Close()
Write-Host "Disassembly at RVA 0xF1290 (Building Loop):"
Write-Host ([BitConverter]::ToString($bytes))
