$p = Get-Process -Name "Battle_Realms_F"
$base = $p.MainModule.BaseAddress.ToInt64()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MScan {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [MScan]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [MScan]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$arr = R32 ($base + 0x553568)
for ($i = 0; $i -lt 100; $i++) {
    $b = $arr + $i * 0x6A4
    if ((R32 ($b + 0x6A0)) -ne 0x68) { continue }
    $td = R32 ($b + 0x258)
    if ($td -lt 0x01000000) { continue }
    $c = R32 ($b + 0x0C)
    $f64 = R32 ($b + 0x64)
    $f78 = R32 ($b + 0x78)
    $f7C = R32 ($b + 0x7C)
    $fCC = R32 ($b + 0xCC)
    $fE4 = R32 ($b + 0xE4)
    Write-Host ("Bldg[{0,2}]: +0C=0x{1:X8}, +64={2}, +78={3}, +7C={4}, +CC={5}, +E4=0x{6:X8}" -f $i, $c, $f64, $f78, $f7C, $fCC, $fE4)
}
[MScan]::CloseHandle($h)
