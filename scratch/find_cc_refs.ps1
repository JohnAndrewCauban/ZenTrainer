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

Write-Host "Searching for writes or checks of [reg + 0xCC]..."
for ($i = 0; $i -lt $bytes.Length - 10; $i++) {
    # 83 B8/BF CC 00 00 00 00 (cmp dword ptr [reg+0xCC], 0)
    if ($bytes[$i] -eq 0x83 -and ($bytes[$i+1] -band 0xC7) -eq 0x80 -and $bytes[$i+2] -eq 0xCC -and $bytes[$i+3] -eq 0x00 -and $bytes[$i+4] -eq 0x00 -and $bytes[$i+5] -eq 0x00) {
        $rva = RawToRva($i)
        Write-Host ("cmp [reg+0xCC], imm8 at RVA 0x{0:X8}" -f $rva)
    }
    # C7 80..87 CC 00 00 00 01 00 00 00 (mov dword ptr [reg+0xCC], 1)
    if ($bytes[$i] -eq 0xC7 -and ($bytes[$i+1] -band 0xC7) -eq 0x80 -and $bytes[$i+2] -eq 0xCC -and $bytes[$i+3] -eq 0x00 -and $bytes[$i+4] -eq 0x00 -and $bytes[$i+5] -eq 0x00) {
        $val = [BitConverter]::ToInt32($bytes, $i + 6)
        $rva = RawToRva($i)
        Write-Host ("mov [reg+0xCC], {0} at RVA 0x{1:X8}" -f $val, $rva)
    }
}
