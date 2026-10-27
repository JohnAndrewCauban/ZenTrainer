$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] 300
$fileOff = 0xE8F00 - 0x1000 + 0x400
$fs.Position = $fileOff
$fs.Read($bytes, 0, 300) | Out-Null
$fs.Close()
Write-Host "Disassembly around Building Constructor (RVA 0xE8F00):"
Write-Host ([BitConverter]::ToString($bytes))
