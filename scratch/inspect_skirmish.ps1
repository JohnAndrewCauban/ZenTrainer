$p = Get-Process -Name "Battle_Realms_F*"
$base = $p.MainModule.BaseAddress.ToInt64()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MSkirmish {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [MSkirmish]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [MSkirmish]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$pPlayer = R32 ($base + 0x513228)
$localPlayerId = R32 ($pPlayer + 0x6C)
$selPtr = R32 ($base + 0x554AC0)
Write-Host ("PID: {0}, pPlayer: 0x{1:X8}, localPlayerId: {2}, selPtr: 0x{3:X8}" -f $p.Id, $pPlayer, $localPlayerId, $selPtr)

$arr = R32 ($base + 0x553568)
for ($i = 0; $i -lt 50; $i++) {
    $b = $arr + $i * 0x6A4
    if ((R32 ($b + 0x6A0)) -ne 0x68) { continue }
    $td = R32 ($b + 0x258)
    if ($td -lt 0x01000000) { continue }
    $nom = R32 ($td + 0x2C)
    $np = R32 ($td + 4)
    $bname = New-Object byte[] 40
    $o = 0
    [MSkirmish]::ReadProcessMemory($h, [IntPtr]$np, $bname, 40, [ref]$o) | Out-Null
    $name = [System.Text.Encoding]::Unicode.GetString($bname).Trim([char]0)
    $cur = (R32 ($b + 0x8C)) / 65536.0
    $max = (R32 ($b + 0x88)) / 65536.0
    Write-Host ("Bldg[{0}]: addr=0x{1:X8}, name='{2}', +04=0x{3:X8}, +14={4}, +78={5}, +7C={6}, +CC={7}, HP={8:F0}/{9:F0}" -f `
        $i, $b, $name, (R32 ($b + 0x04)), (R32 ($b + 0x14)), (R32 ($b + 0x78)), (R32 ($b + 0x7C)), (R32 ($b + 0xCC)), $cur, $max)
}
[MSkirmish]::CloseHandle($h)
