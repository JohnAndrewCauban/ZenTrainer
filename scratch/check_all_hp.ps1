$p = Get-Process -Name "Battle_Realms_F"
$base = $p.MainModule.BaseAddress.ToInt64()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MAll {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [MAll]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [MAll]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$arr = R32 ($base + 0x553568)
for ($i = 0; $i -lt 500; $i++) {
    $b = $arr + $i * 0x6A4
    if ((R32 ($b + 0x6A0)) -ne 0x68) { continue }
    $cur = R32 ($b + 0x8C)
    $max = R32 ($b + 0x88)
    $td = R32 ($b + 0x258)
    if ($td -lt 0x01000000) { continue }
    $nom = R32 ($td + 0x2C)
    if ($cur -ne ($nom -shl 16) -or $max -ne ($nom -shl 16)) {
        Write-Host ("Bldg[{0}]: addr=0x{1:X8}, CurHP={2:F1}/{3:F1} (nom={4}), team={5}, flames={6}" -f `
            $i, $b, ($cur/65536.0), ($max/65536.0), $nom, (R32 ($b + 0x7C)), (R32 ($b + 0x2E8)))
    }
}
[MAll]::CloseHandle($h)
