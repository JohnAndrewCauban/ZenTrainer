$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] $fs.Length
$fs.Read($bytes, 0, $bytes.Length) | Out-Null
$fs.Close()

# Search for pattern: 8B ... 2C 00 00 00 (mov reg, [reg+2Ch]) or 3B ... 2C 00 00 00 (cmp reg, [reg+2Ch])
Write-Host "Code referencing +0x2C (MaxHP in typeDef):"
for ($i = 0; $i -lt 0x4A4400; $i++) {
    if ($bytes[$i] -eq 0x2C -and $bytes[$i+1] -eq 0x00 -and $bytes[$i+2] -eq 0x00 -and $bytes[$i+3] -eq 0x00) {
        $op = $bytes[$i-2]
        $modrm = $bytes[$i-1]
        # Check if modrm has disp32 (0x80-0xBF)
        if (($modrm -band 0xC0) -eq 0x80) {
            $va = $i - 0x400 + 0x1000 - 2
            $hex = [BitConverter]::ToString($bytes, $i - 6, 16)
            Write-Host ("  RVA 0x{0:X}: {1}" -f $va, $hex)
        }
    }
}
