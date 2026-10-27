$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] $fs.Length
$fs.Read($bytes, 0, $bytes.Length) | Out-Null
$fs.Close()

Write-Host "Code referencing +0x6C (Player ID):"
for ($i = 0; $i -lt 0x4A4400; $i++) {
    if ($bytes[$i] -eq 0x6C -and $bytes[$i-1] -eq 0x41 -and $bytes[$i-2] -eq 0x8B) { # mov eax, [ecx+6Ch]
        $va = $i - 0x400 + 0x1000 - 2
        $pre = [BitConverter]::ToString($bytes, $i - 2, 10)
        Write-Host ("  mov eax, [ecx+6Ch] at RVA 0x{0:X}: {1}" -f $va, $pre)
    }
}
