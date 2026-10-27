$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] 200
$fileOff = 0xE8E50 - 0x1000 + 0x400
$fs.Position = $fileOff
$fs.Read($bytes, 0, 200) | Out-Null
$fs.Close()
Write-Host "Disassembly around Building Constructor Base (RVA 0xE8E50):"
Write-Host ([BitConverter]::ToString($bytes))
