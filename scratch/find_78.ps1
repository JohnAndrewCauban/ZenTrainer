$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] $fs.Length
$fs.Read($bytes, 0, $bytes.Length) | Out-Null
$fs.Close()

Write-Host "References to +0x78 in code:"
$target = [BitConverter]::GetBytes([int]0x78)
for ($i = 0; $i -lt 0x4A4400; $i++) {
    if ($bytes[$i] -eq 0x78 -and $bytes[$i+1] -eq 0x00 -and $bytes[$i+2] -eq 0x00 -and $bytes[$i+3] -eq 0x00) {
        $op = $bytes[$i-2]
        $modrm = $bytes[$i-1]
        if (($modrm -band 0xC0) -eq 0x80) {
            $va = $i - 0x400 + 0x1000 - 2
            $hex = [BitConverter]::ToString($bytes, [Math]::Max(0, $i - 4), 10)
            Write-Host ("  RVA 0x{0:X}: {1}" -f $va, $hex)
        }
    }
}
