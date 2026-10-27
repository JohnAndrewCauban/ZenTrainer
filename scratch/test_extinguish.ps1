$p = Get-Process Battle_Realms_F
$id = $p.Id
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class Extinguish {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr w);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [Extinguish]::OpenProcess(0x1F0FFF, $false, $id)

function WriteI32($addr, $v) {
    $b = [BitConverter]::GetBytes([int]$v)
    $w = [IntPtr]::Zero
    [Extinguish]::WriteProcessMemory($h, [IntPtr]$addr, $b, [IntPtr]4, [ref]$w) | Out-Null
}

$base = [int64]$p.MainModule.BaseAddress
$buf = New-Object byte[] 4; $r = [IntPtr]::Zero
[Extinguish]::ReadProcessMemory($h, [IntPtr]($base + 0x553568), $buf, [IntPtr]4, [ref]$r) | Out-Null
$arr = [uint32]([BitConverter]::ToInt32($buf, 0))

Write-Host "Fixing all burning buildings..."
for ($i = 0; $i -lt 500; $i++) {
    $b = $arr + $i * 0x6A4
    [Extinguish]::ReadProcessMemory($h, [IntPtr]($b + 0x6A0), $buf, [IntPtr]4, [ref]$r) | Out-Null
    if ([BitConverter]::ToInt32($buf, 0) -eq 0x68) {
        [Extinguish]::ReadProcessMemory($h, [IntPtr]($b + 0x258), $buf, [IntPtr]4, [ref]$r) | Out-Null
        $td = [uint32]([BitConverter]::ToInt32($buf, 0))
        if ($td -ge 0x01000000) {
            [Extinguish]::ReadProcessMemory($h, [IntPtr]($td + 0x2C), $buf, [IntPtr]4, [ref]$r) | Out-Null
            $maxHp = [BitConverter]::ToInt32($buf, 0)
            if ($maxHp -gt 0) {
                WriteI32 ($b + 0x88) ($maxHp -shl 16) # Max HP
                WriteI32 ($b + 0x8C) ($maxHp -shl 16) # Current HP
                WriteI32 ($b + 0x80) 0                # Fire damage over time
                WriteI32 ($b + 0x90) 0x00010000      # 100% constructed
                WriteI32 ($b + 0x94) 0                # Clear corrupted pointer
                WriteI32 ($b + 0x2E8) 0               # Clear active fire flame effects
            }
        }
    }
}
Write-Host "Done! All buildings healed and extinguished."
