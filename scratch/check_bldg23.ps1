$p = Get-Process -Name "Battle_Realms_F"
$base = $p.MainModule.BaseAddress.ToInt64()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MTest {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [MTest]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [MTest]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$pPlayer = R32 ($base + 0x513228)
$localPlayerId = if ($pPlayer -ne 0) { R32 ($pPlayer + 0x6C) } else { -1 }
$selPtr = R32 ($base + 0x554AC0)
Write-Host ("pPlayer: 0x{0:X8}, localPlayerId: {1}, selPtr: 0x{2:X8}" -f $pPlayer, $localPlayerId, $selPtr)

$bldg23 = 0x20FBC8E0
Write-Host "Bldg[23] details:"
Write-Host ("  tag (+6A0): 0x{0:X}" -f (R32 ($bldg23 + 0x6A0)))
Write-Host ("  team (+7C): {0}" -f (R32 ($bldg23 + 0x7C)))
Write-Host ("  owner (+78): {0}" -f (R32 ($bldg23 + 0x78)))
Write-Host ("  curHp (+8C): 0x{0:X8} ({1})" -f (R32 ($bldg23 + 0x8C)), ((R32 ($bldg23 + 0x8C))/65536.0))
Write-Host ("  maxHp (+88): 0x{0:X8} ({1})" -f (R32 ($bldg23 + 0x88)), ((R32 ($bldg23 + 0x88))/65536.0))
Write-Host ("  prog (+90): 0x{0:X8}" -f (R32 ($bldg23 + 0x90)))
Write-Host ("  typeDef (+258): 0x{0:X8}" -f (R32 ($bldg23 + 0x258)))

$td = R32 ($bldg23 + 0x258)
if ($td -ge 0x01000000) {
    Write-Host ("  typeDef+0x2C (nominal MaxHP): {0}" -f (R32 ($td + 0x2C)))
}

[MTest]::CloseHandle($h)
