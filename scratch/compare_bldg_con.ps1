$p = Get-Process -Name "Battle_Realms_F"
$base = $p.MainModule.BaseAddress.ToInt64()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class M4 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [M4]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [M4]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$bldg1 = 0x20FB36C8  # Dragon Peasant Hut (finished)
$bldg23 = 0x20FBC8E0 # Dragon Dojo (scaffold / under construction)

Write-Host "Comparing Bldg[1] (finished) vs Bldg[23] (under construction):"
for ($off = 0; $off -lt 0x150; $off += 4) {
    $v1 = R32 ($bldg1 + $off)
    $v23 = R32 ($bldg23 + $off)
    if ($v1 -ne $v23) {
        Write-Host ("+0x{0:X3}: Bldg[1]=0x{1:X8} ({1}) | Bldg[23]=0x{2:X8} ({2})" -f $off, $v1, $v23)
    }
}

[M4]::CloseHandle($h)
