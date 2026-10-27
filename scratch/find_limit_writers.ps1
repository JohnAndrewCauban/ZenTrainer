$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] $fs.Length
$fs.Read($bytes, 0, $bytes.Length) | Out-Null
$fs.Close()

Write-Host "Code referencing 0x939728 (unit limit table):"
$target = [BitConverter]::GetBytes([int]0x00939728) # relocated with ImageBase 0x400000 -> 0x939728
for ($i = 0; $i -lt 0x4A4400; $i++) {
    if ($bytes[$i] -eq $target[0] -and $bytes[$i+1] -eq $target[1] -and $bytes[$i+2] -eq $target[2] -and $bytes[$i+3] -eq $target[3]) {
        $va = $i - 0x400 + 0x1000
        $pre = [BitConverter]::ToString($bytes, [Math]::Max(0, $i - 6), 12)
        Write-Host ("  RVA 0x{0:X}: {1}" -f $va, $pre)
    }
}
