$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class FindPtr {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [FindPtr]::OpenProcess(0x1F0FFF, $false, $id)

$target = 0x22F6DFD4 # Bldg 12
$targetBytes = [BitConverter]::GetBytes([uint32]$target)

# Scan the data section (Base + 0x500000 to Base + 0x600000)
$scanStart = $base + 0x500000
$scanLen = 0x100000
$buf = New-Object byte[] $scanLen
$read = [IntPtr]::Zero
[FindPtr]::ReadProcessMemory($h, [IntPtr]$scanStart, $buf, [IntPtr]$scanLen, [ref]$read) | Out-Null

Write-Host ("Scanning 0x{0:X} to 0x{1:X} for pointer 0x{2:X}..." -f $scanStart, ($scanStart + $scanLen), $target)
$found = 0
for ($i = 0; $i -lt ($scanLen - 4); $i += 4) {
    if ($buf[$i] -eq $targetBytes[0] -and 
        $buf[$i+1] -eq $targetBytes[1] -and 
        $buf[$i+2] -eq $targetBytes[2] -and 
        $buf[$i+3] -eq $targetBytes[3]) {
        $addr = $scanStart + $i
        $rva = $addr - $base
        Write-Host ("Found pointer at Base + 0x{0:X} (0x{1:X})" -f $rva, $addr)
        $found++
    }
}
Write-Host ("Total pointers found: {0}" -f $found)
