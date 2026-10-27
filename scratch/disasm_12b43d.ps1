$bytes = [System.IO.File]::ReadAllBytes("C:\Other SSD Drive\Programs\Battle.Realms.Zen.Edition.v1.59.1\Battle_Realms_F.exe")
$peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
$numSections = [BitConverter]::ToInt16($bytes, $peOffset + 6)
$optHeaderSize = [BitConverter]::ToInt16($bytes, $peOffset + 20)
$sectionTableOffset = $peOffset + 24 + $optHeaderSize

function RvaToRaw($rva) {
    for ($i = 0; $i -lt $numSections; $i++) {
        $secOffset = $sectionTableOffset + $i * 40
        $vSize = [BitConverter]::ToInt32($bytes, $secOffset + 8)
        $vAddr = [BitConverter]::ToInt32($bytes, $secOffset + 12)
        $rSize = [BitConverter]::ToInt32($bytes, $secOffset + 16)
        $rOffset = [BitConverter]::ToInt32($bytes, $secOffset + 20)
        if ($rva -ge $vAddr -and $rva -lt ($vAddr + $vSize)) {
            return $rOffset + ($rva - $vAddr)
        }
    }
    return 0
}

$raw = RvaToRaw(0x0012B43D)
$start = [Math]::Max(0, $raw - 16)
$sub = $bytes[$start..($start+64)]
Write-Host "Bytes around 0x0012B43D:"
Write-Host (($sub | ForEach-Object { "{0:X2}" -f $_ }) -join " ")
