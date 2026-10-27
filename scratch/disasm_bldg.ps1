$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] 200
$fileOff = 0xAC0B0 - 0x1000 + 0x400
$fs.Position = $fileOff
$fs.Read($bytes, 0, 200) | Out-Null
$fs.Close()
Write-Host "Bytes at RVA 0xAC0B0 (file offset 0x$($fileOff.ToString('X'))):"
Write-Host ([BitConverter]::ToString($bytes))
