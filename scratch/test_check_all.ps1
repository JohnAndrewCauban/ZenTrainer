$p = Get-Process -Name "Battle_Realms_F"
$base = $p.MainModule.BaseAddress.ToInt64()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class M8 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [M8]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [M8]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$arr = R32 ($base + 0x553568)
for ($i = 0; $i -lt 500; $i++) {
    $b = $arr + $i * 0x6A4
    $tag = R32 ($b + 0x6A0)
    if ($tag -ne 0x68) { continue }
    $td = R32 ($b + 0x258)
    if ($td -lt 0x01000000) { continue }
    $m = R32 ($td + 0x2C)
    if ($m -le 0) { continue }
    
    $f04 = R32 ($b + 0x04)
    $f14 = R32 ($b + 0x14)
    $f7C = R32 ($b + 0x7C)
    $fCC = R32 ($b + 0xCC)
    $fE4 = R32 ($b + 0xE4)
    Write-Host ("Bldg[{0,2}]: +04=0x{1:X8}, +14={2}, +7C={3}, +CC={4}, +E4=0x{5:X8}" -f $i, $f04, $f14, $f7C, $fCC, $fE4)
}
[M8]::CloseHandle($h)
