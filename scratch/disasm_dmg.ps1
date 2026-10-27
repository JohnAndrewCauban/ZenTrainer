$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
function Disasm($rva, $len) {
    $bytes = New-Object byte[] $len
    $fileOff = $rva - 0x1000 + 0x400
    $fs.Position = $fileOff
    $fs.Read($bytes, 0, $len) | Out-Null
    Write-Host "`nDisasm at RVA 0x$($rva.ToString('X')):"
    Write-Host ([BitConverter]::ToString($bytes))
}
Disasm 0xAA7E0 64
Disasm 0xAA980 64
Disasm 0xADD40 64
$fs.Close()
