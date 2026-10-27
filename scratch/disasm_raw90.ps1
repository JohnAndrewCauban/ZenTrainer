$bytes = [System.IO.File]::ReadAllBytes("C:\Other SSD Drive\Programs\Battle.Realms.Zen.Edition.v1.59.1\Battle_Realms_F.exe")
$peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
$numSections = [BitConverter]::ToInt16($bytes, $peOffset + 6)
$optHeaderSize = [BitConverter]::ToInt16($bytes, $peOffset + 20)
$sectionTableOffset = $peOffset + 24 + $optHeaderSize

$raw = 0x003878C9
$rva = 0
for ($i = 0; $i -lt $numSections; $i++) {
    $secOffset = $sectionTableOffset + $i * 40
    $vSize = [BitConverter]::ToInt32($bytes, $secOffset + 8)
    $vAddr = [BitConverter]::ToInt32($bytes, $secOffset + 12)
    $rSize = [BitConverter]::ToInt32($bytes, $secOffset + 16)
    $rOffset = [BitConverter]::ToInt32($bytes, $secOffset + 20)
    if ($raw -ge $rOffset -and $raw -lt ($rOffset + $rSize)) {
        $rva = $vAddr + ($raw - $rOffset)
        break
    }
}
Write-Host ("Raw 0x{0:X8} -> RVA 0x{1:X8}" -f $raw, $rva)

# Dump surrounding bytes
$start = [Math]::Max(0, $raw - 64)
$len = 128
$hex = ($bytes[$start..($start+$len)] | ForEach-Object { "{0:X2}" -f $_ }) -join " "
Write-Host "Bytes around target:"
Write-Host $hex
