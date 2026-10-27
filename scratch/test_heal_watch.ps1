$p = Get-Process -Name "Battle_Realms_F"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MHeal {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [MHeal]::OpenProcess(0x1F0FFF, $false, $p.Id)
function W32($a, $v) {
    $b = [BitConverter]::GetBytes([int]$v)
    $out = 0
    [MHeal]::WriteProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$out) | Out-Null
}

# Heal Bldg[2] (Watchtower)
$b2 = 0x20FB3D6C
$maxHp = 900 -shl 16
W32 ($b2 + 0x88) $maxHp
W32 ($b2 + 0x8C) $maxHp
W32 ($b2 + 0x80) 0
W32 ($b2 + 0x2E8) 0
Write-Host "Healed Watchtower (Bldg[2])"

# Heal Bldg[21] (Stables)
$b21 = 0x20FBBB98
W32 ($b21 + 0x88) $maxHp
W32 ($b21 + 0x8C) $maxHp
W32 ($b21 + 0x80) 0
W32 ($b21 + 0x2E8) 0
Write-Host "Healed Stables (Bldg[21])"

[MHeal]::CloseHandle($h)
