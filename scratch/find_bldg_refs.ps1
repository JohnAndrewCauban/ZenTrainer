$fs = [System.IO.File]::OpenRead("Battle_Realms_F.exe")
$bytes = New-Object byte[] $fs.Length
$fs.Read($bytes, 0, $bytes.Length) | Out-Null
$fs.Close()

# Search for pattern: [+0x8C] in instructions e.g. [reg+0x8C]
# Common opcodes:
# 8B ... 8C 00 00 00 (mov reg, [reg+8C])
# 89 ... 8C 00 00 00 (mov [reg+8C], reg)
# D9 ... 8C 00 00 00 (fld dword ptr [reg+8C])
# C7 ... 8C 00 00 00 (mov dword ptr [reg+8C], imm32)

function FindRefs($offset) {
    Write-Host "`nReferences to +0x$($offset.ToString('X')):"
    $target = [BitConverter]::GetBytes([int]$offset)
    $matches = 0
    for ($i = 0; $i -lt 0x4A4400; $i++) {
        if ($bytes[$i] -eq $target[0] -and $bytes[$i+1] -eq $target[1] -and $bytes[$i+2] -eq $target[2] -and $bytes[$i+3] -eq $target[3]) {
            # Check preceding opcode (1-3 bytes back)
            $va = $i - 0x400 + 0x1000 # RVA in .text
            $pre = [BitConverter]::ToString($bytes, [Math]::Max(0, $i - 4), 8)
            Write-Host ("  RVA 0x{0:X}: ... {1} ..." -f $va, $pre)
            $matches++
            if ($matches -ge 10) { break }
        }
    }
}

FindRefs 0x8C
FindRefs 0x88
FindRefs 0x90
FindRefs 0x94
