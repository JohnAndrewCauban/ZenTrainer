$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] $fs.Length
$fs.Read($bytes, 0, $bytes.Length) | Out-Null
$fs.Close()

Write-Host "Calls to SetUnitLimit (RVA 0xDA3A0):"
for ($i = 0; $i -lt 0x4A4400; $i++) {
    if ($bytes[$i] -eq 0xE8) { # call rel32
        $rel = [BitConverter]::ToInt32($bytes, $i + 1)
        $callVa = $i - 0x400 + 0x1000
        $targetVa = $callVa + 5 + $rel
        if ($targetVa -eq 0xDA3A0) {
            $pre = [BitConverter]::ToString($bytes, [Math]::Max(0, $i - 10), 16)
            Write-Host ("  Call at RVA 0x{0:X}: {1}" -f $callVa, $pre)
        }
    }
}
