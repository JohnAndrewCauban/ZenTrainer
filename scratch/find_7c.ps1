$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] $fs.Length
$fs.Read($bytes, 0, $bytes.Length) | Out-Null
$fs.Close()

Write-Host "References to +0x7C in code:"
for ($i = 0; $i -lt 0x4A4400; $i++) {
    if ($bytes[$i] -eq 0x7C -and $bytes[$i-1] -eq 0x7E -and $bytes[$i-2] -eq 0x83) { # cmp dword ptr [esi+7Ch], imm8
        $va = $i - 0x400 + 0x1000 - 2
        Write-Host ("  cmp [esi+7Ch] at RVA 0x{0:X}: imm=0x{1:X2}" -f $va, $bytes[$i+1])
    }
    if ($bytes[$i] -eq 0x7C -and $bytes[$i-1] -eq 0x79 -and $bytes[$i-2] -eq 0x83) { # cmp dword ptr [ecx+7Ch], imm8
        $va = $i - 0x400 + 0x1000 - 2
        Write-Host ("  cmp [ecx+7Ch] at RVA 0x{0:X}: imm=0x{1:X2}" -f $va, $bytes[$i+1])
    }
}
