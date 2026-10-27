$p = Get-Process -Name "Battle_Realms_F"
$base = $p.MainModule.BaseAddress.ToInt64()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MUnit {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [MUnit]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [MUnit]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$pPlayer = R32 ($base + 0x513228)
$localPlayerId = if ($pPlayer -ne 0) { R32 ($pPlayer + 0x6C) } else { -1 }
$selBldg = R32 ($base + 0x554AC0)
Write-Host ("pPlayer: 0x{0:X8}, localPlayerId: {1}, selBldg: 0x{2:X8}" -f $pPlayer, $localPlayerId, $selBldg)

# Check selected unit or building
if ($selBldg -ne 0) {
    Write-Host ("Selected Bldg (+6A0): 0x{0:X}, +7C: {1}, +CC: {2}" -f (R32 ($selBldg + 0x6A0)), (R32 ($selBldg + 0x7C)), (R32 ($selBldg + 0xCC)))
}

# Check unit selection at base + 0x554AC4 (if exists) or scan
[MUnit]::CloseHandle($h)
