$p = Get-Process -Name "Battle_Realms_F"
$base = $p.MainModule.BaseAddress.ToInt64()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class M3 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [M3]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [M3]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }
function RB($a, $l) { $b = New-Object byte[] $l; $o = 0; [M3]::ReadProcessMemory($h, [IntPtr]$a, $b, $l, [ref]$o) | Out-Null; return $b }

$pPlayer = R32 ($base + 0x513228)
$localPlayerId = if ($pPlayer -ne 0) { R32 ($pPlayer + 0x6C) } else { -1 }
$selPtr = R32 ($base + 0x554AC0)
Write-Host ("pPlayer: 0x{0:X8}, localPlayerId: {1}, selPtr: 0x{2:X8}" -f $pPlayer, $localPlayerId, $selPtr)

if ($selPtr -ne 0) {
    $tag = R32 ($selPtr + 0x6A0)
    $owner = R32 ($selPtr + 0x78)
    $team = R32 ($selPtr + 0x7C)
    $cur = R32 ($selPtr + 0x8C)
    $max = R32 ($selPtr + 0x88)
    $prog = R32 ($selPtr + 0x90)
    $td = R32 ($selPtr + 0x258)
    $name = ''
    if ($td -ge 0x01000000) {
        $np = R32 ($td + 4)
        if ($np -ge 0x01000000) { $name = [System.Text.Encoding]::Unicode.GetString((RB $np 40)).Trim([char]0) }
    }
    Write-Host ("SELECTED: addr=0x{0:X8}, name='{1}', tag=0x{2:X}, +78(owner)={3}, +7C(team)={4}, HP={5}/{6}, prog=0x{7:X8}" -f $selPtr, $name, $tag, $owner, $team, ($cur/65536.0), ($max/65536.0), $prog)
}

$arr = R32 ($base + 0x553568)
for ($i = 0; $i -lt 500; $i++) {
    $b = $arr + $i * 0x6A4
    $tag = R32 ($b + 0x6A0)
    if ($tag -ne 0x68) { continue }
    $td = R32 ($b + 0x258)
    if ($td -lt 0x01000000) { continue }
    $m = R32 ($td + 0x2C)
    if ($m -le 0) { continue }
    $np = R32 ($td + 4)
    $name = if ($np -ge 0x01000000) { [System.Text.Encoding]::Unicode.GetString((RB $np 40)).Trim([char]0) } else { '?' }
    $owner = R32 ($b + 0x78)
    $team = R32 ($b + 0x7C)
    $cur = R32 ($b + 0x8C)
    $max = R32 ($b + 0x88)
    $prog = R32 ($b + 0x90)
    Write-Host ("Bldg[{0}]: addr=0x{1:X8}, name={2}, owner={3}, team={4}, HP={5}/{6}, prog=0x{7:X8}" -f $i, $b, $name, $owner, $team, ($cur/65536.0), ($max/65536.0), $prog)
}
[M3]::CloseHandle($h)
