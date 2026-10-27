$p = Get-Process -Name "Battle_Realms_F*"
$base = $p.MainModule.BaseAddress.ToInt64()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MTest3 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [MTest3]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [MTest3]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$pPlayer = R32 ($base + 0x513228)
$localPlayerId = R32 ($pPlayer + 0x6C)
Write-Host ("localPlayerId: {0}" -f $localPlayerId)

$arr = R32 ($base + 0x553568)
for ($i = 0; $i -lt 100; $i++) {
    $b = $arr + $i * 0x6A4
    if ((R32 ($b + 0x6A0)) -ne 0x68) { continue }
    $owner = R32 ($b + 0x84)
    if ($owner -ne $localPlayerId) { continue }
    $td = R32 ($b + 0x258)
    if ($td -lt 0x01000000) { continue }
    $np = R32 ($td + 4)
    $bname = New-Object byte[] 40
    $o = 0
    [MTest3]::ReadProcessMemory($h, [IntPtr]$np, $bname, 40, [ref]$o) | Out-Null
    $name = [System.Text.Encoding]::Unicode.GetString($bname).Trim([char]0)
    $nomMax = R32 ($td + 0x2C)
    $cur = (R32 ($b + 0x8C)) / 65536.0
    $max = (R32 ($b + 0x88)) / 65536.0
    $isCon = R32 ($b + 0xCC)
    Write-Host ("Player Bldg[{0}]: name='{1}', curHP={2:F1}, maxHP={3:F1}, nomMax={4}, isConstructed(+CC)={5}" -f `
        $i, $name, $cur, $max, $nomMax, $isCon)
}
[MTest3]::CloseHandle($h)
