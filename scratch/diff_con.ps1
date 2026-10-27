$p = Get-Process -Name "Battle_Realms_F"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class M5 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [M5]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [M5]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$bldg23 = 0x20FBC8E0 # Dragon Dojo under construction

$s1 = @{}
for ($off = 0; $off -lt 0x500; $off += 4) {
    $s1[$off] = R32 ($bldg23 + $off)
}

Start-Sleep -Seconds 3

$s2 = @{}
for ($off = 0; $off -lt 0x500; $off += 4) {
    $s2[$off] = R32 ($bldg23 + $off)
}

Write-Host "Changes in Bldg[23] over 3 seconds:"
foreach ($off in ($s1.Keys | Sort-Object)) {
    if ($s1[$off] -ne $s2[$off]) {
        Write-Host ("+0x{0:X3}: 0x{1:X8} ({1}) -> 0x{2:X8} ({2})" -f $off, $s1[$off], $s2[$off])
    }
}

[M5]::CloseHandle($h)
