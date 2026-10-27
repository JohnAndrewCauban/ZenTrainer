$bytes = [System.IO.File]::ReadAllBytes("C:\Other SSD Drive\Programs\Battle.Realms.Zen.Edition.v1.59.1\Battle_Realms_F.exe")
$peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
$numSections = [BitConverter]::ToInt16($bytes, $peOffset + 6)
$optHeaderSize = [BitConverter]::ToInt16($bytes, $peOffset + 20)
$sectionTableOffset = $peOffset + 24 + $optHeaderSize

function RawToRva($raw) {
    for ($i = 0; $i -lt $numSections; $i++) {
        $secOffset = $sectionTableOffset + $i * 40
        $vSize = [BitConverter]::ToInt32($bytes, $secOffset + 8)
        $vAddr = [BitConverter]::ToInt32($bytes, $secOffset + 12)
        $rSize = [BitConverter]::ToInt32($bytes, $secOffset + 16)
        $rOffset = [BitConverter]::ToInt32($bytes, $secOffset + 20)
        if ($raw -ge $rOffset -and $raw -lt ($rOffset + $rSize)) {
            return $vAddr + ($raw - $rOffset)
        }
    }
    return 0
}

Write-Host "Searching for writes to [reg + 0x8C]..."
for ($i = 0; $i -lt $bytes.Length - 10; $i++) {
    # 89 80..8F 8C 00 00 00 (mov [reg+0x8C], reg)
    if ($bytes[$i] -eq 0x89 -and ($bytes[$i+1] -band 0xC7) -eq 0x80 -and $bytes[$i+2] -eq 0x8C -and $bytes[$i+3] -eq 0x00 -and $bytes[$i+4] -eq 0x00 -and $bytes[$i+5] -eq 0x00) {
        $rva = RawToRva($i)
        Write-Host ("mov [reg+0x8C], reg at raw 0x{0:X8} (RVA 0x{1:X8})" -f $i, $rva)
    }
    # 01 / 29 (add / sub [reg+0x8C], reg)
    if (($bytes[$i] -eq 0x01 -or $bytes[$i] -eq 0x29) -and ($bytes[$i+1] -band 0xC7) -eq 0x80 -and $bytes[$i+2] -eq 0x8C -and $bytes[$i+3] -eq 0x00 -and $bytes[$i+4] -eq 0x00 -and $bytes[$i+5] -eq 0x00) {
        $rva = RawToRva($i)
        Write-Host ("add/sub [reg+0x8C], reg at raw 0x{0:X8} (RVA 0x{1:X8})" -f $i, $rva)
    }
}
