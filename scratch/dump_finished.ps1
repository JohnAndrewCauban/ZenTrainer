$p = Get-Process -Name "Battle_Realms_F"
$base = $p.MainModule.BaseAddress.ToInt64()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class M7 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [M7]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [M7]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$bldg1 = 0x20FB36C8 # Dragon Peasant Hut (finished)
Write-Host "Dumping first 0x200 bytes of Bldg[1]:"
for ($off = 0; $off -lt 0x200; $off += 16) {
    $v0 = R32 ($bldg1 + $off)
    $v4 = R32 ($bldg1 + $off + 4)
    $v8 = R32 ($bldg1 + $off + 8)
    $vC = R32 ($bldg1 + $off + 12)
    Write-Host ("+0x{0:X3}: {1:X8} {2:X8} {3:X8} {4:X8}" -f $off, $v0, $v4, $v8, $vC)
}
[M7]::CloseHandle($h)
