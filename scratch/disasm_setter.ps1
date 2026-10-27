$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] 60
$fileOff = 0xDA390 - 0x1000 + 0x400
$fs.Position = $fileOff
$fs.Read($bytes, 0, 60) | Out-Null
$fs.Close()
Write-Host "Setter at RVA 0xDA390:"
Write-Host ([BitConverter]::ToString($bytes))
