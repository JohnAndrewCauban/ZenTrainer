$p = Get-Process -Name "Battle_Realms_F"
$base = $p.MainModule.BaseAddress.ToInt64()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MPlayer {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [MPlayer]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [MPlayer]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$pPlayer = R32 ($base + 0x513228)
Write-Host ("pPlayer: 0x{0:X8}" -f $pPlayer)
Write-Host ("  +0x6C (PlayerID): {0}" -f (R32 ($pPlayer + 0x6C)))
Write-Host ("  +0x70 (Team): {0}" -f (R32 ($pPlayer + 0x70)))
Write-Host ("  +0x74 (Clan?): {0}" -f (R32 ($pPlayer + 0x74)))

# Let's inspect first 0x100 dwords of pPlayer
for ($off = 0; $off -lt 0x100; $off += 16) {
    Write-Host ("+0x{0:X3}: {1:X8} {2:X8} {3:X8} {4:X8}" -f $off, (R32 ($pPlayer + $off)), (R32 ($pPlayer + $off + 4)), (R32 ($pPlayer + $off + 8)), (R32 ($pPlayer + $off + 12)))
}

[MPlayer]::CloseHandle($h)
