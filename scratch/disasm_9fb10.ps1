$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] 100
$fileOff = 0x9FB10 - 0x1000 + 0x400
$fs.Position = $fileOff
$fs.Read($bytes, 0, 100) | Out-Null
$fs.Close()
Write-Host "Disassembly at RVA 0x9FB10 (Refs to +0x94):"
Write-Host ([BitConverter]::ToString($bytes))
