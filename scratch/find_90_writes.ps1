$bytes = [System.IO.File]::ReadAllBytes("C:\Other SSD Drive\Programs\Battle.Realms.Zen.Edition.v1.59.1\Battle_Realms_F.exe")

# Search for patterns: e.g. 89 ?? 90 00 00 00 (mov [reg+0x90], reg) or cmp [reg+0x90], 0x10000 or similar
Write-Host "Searching for writes to [reg + 0x90]..."
for ($i = 0; $i -lt $bytes.Length - 10; $i++) {
    # 89 80 90 00 00 00 ... 89 88 90 00 00 00 ...
    if ($bytes[$i] -eq 0x89 -and ($bytes[$i+1] -band 0xC7) -eq 0x80 -and $bytes[$i+2] -eq 0x90 -and $bytes[$i+3] -eq 0x00 -and $bytes[$i+4] -eq 0x00 -and $bytes[$i+5] -eq 0x00) {
        $rva = $i - 0x400 + 0x1000 # typical PE raw offset to RVA roughly, or calculate properly
        Write-Host ("Found mov [reg+0x90], reg at raw 0x{0:X8}" -f $i)
    }
    # C7 80 90 00 00 00 (mov dword ptr [reg+0x90], imm32)
    if ($bytes[$i] -eq 0xC7 -and ($bytes[$i+1] -band 0xC7) -eq 0x80 -and $bytes[$i+2] -eq 0x90 -and $bytes[$i+3] -eq 0x00 -and $bytes[$i+4] -eq 0x00 -and $bytes[$i+5] -eq 0x00) {
        Write-Host ("Found mov [reg+0x90], imm32 at raw 0x{0:X8}" -f $i)
    }
}
