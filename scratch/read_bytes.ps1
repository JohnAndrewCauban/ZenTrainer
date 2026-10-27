$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
# Find section with virtual address
$peBytes = New-Object byte[] 4096
$fs.Read($peBytes, 0, 4096) | Out-Null
$e_lfanew = [BitConverter]::ToInt32($peBytes, 0x3C)
$numSections = [BitConverter]::ToInt16($peBytes, $e_lfanew + 6)
$optHeaderSize = [BitConverter]::ToInt16($peBytes, $e_lfanew + 20)
$secHeaderStart = $e_lfanew + 24 + $optHeaderSize

for ($i = 0; $i -lt $numSections; $i++) {
    $sec = $secHeaderStart + ($i * 40)
    $name = [System.Text.Encoding]::ASCII.GetString($peBytes, $sec, 8).Trim([char]0)
    $va = [BitConverter]::ToInt32($peBytes, $sec + 12)
    $rawAddr = [BitConverter]::ToInt32($peBytes, $sec + 20)
    $rawSize = [BitConverter]::ToInt32($peBytes, $sec + 16)
    Write-Host "$name VA=0x$($va.ToString('X')) Raw=0x$($rawAddr.ToString('X')) Size=0x$($rawSize.ToString('X'))"
    if (0xDA01C -ge $va -and 0xDA01C -lt ($va + $rawSize)) {
        $fileOff = 0xDA01C - $va + $rawAddr
        $fs.Position = $fileOff
        $code = New-Object byte[] 64
        $fs.Read($code, 0, 64) | Out-Null
        Write-Host "Bytes at 0xDA01C (file offset 0x$($fileOff.ToString('X'))):"
        Write-Host ([BitConverter]::ToString($code))
    }
}
$fs.Close()
