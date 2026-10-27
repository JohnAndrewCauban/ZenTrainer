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

$targetRva = 0x00321DB0 # SetHP function entry
Write-Host ("Searching for calls to 0x{0:X8}..." -f $targetRva)
for ($i = 0; $i -lt $bytes.Length - 5; $i++) {
    if ($bytes[$i] -eq 0xE8) {
        $rel = [BitConverter]::ToInt32($bytes, $i + 1)
        $curRva = RawToRva($i)
        if ($curRva -ne 0) {
            $dest = $curRva + 5 + $rel
            if ($dest -eq $targetRva) {
                Write-Host ("Found call at RVA 0x{0:X8}" -f $curRva)
            }
        }
    }
}
