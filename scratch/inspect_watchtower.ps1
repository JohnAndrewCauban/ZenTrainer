$p = Get-Process -Name "Battle_Realms_F"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MWatch {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [MWatch]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [MWatch]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$b2 = 0x20FB3D6C # Dragon Watchtower in screenshot
Write-Host "Bldg[2] (Watchtower) fields:"
Write-Host ("  tag (+6A0): 0x{0:X}" -f (R32 ($b2 + 0x6A0)))
Write-Host ("  +04: 0x{0:X8}" -f (R32 ($b2 + 0x04)))
Write-Host ("  +14: {0}" -f (R32 ($b2 + 0x14)))
Write-Host ("  +78 (archetype): {0}" -f (R32 ($b2 + 0x78)))
Write-Host ("  +7C (team): {0}" -f (R32 ($b2 + 0x7C)))
Write-Host ("  +80 (fire accumulator): {0}" -f (R32 ($b2 + 0x80)))
Write-Host ("  +88 (maxHp): 0x{0:X8} ({1})" -f (R32 ($b2 + 0x88)), ((R32 ($b2 + 0x88))/65536.0))
Write-Host ("  +8C (curHp): 0x{0:X8} ({1})" -f (R32 ($b2 + 0x8C)), ((R32 ($b2 + 0x8C))/65536.0))
Write-Host ("  +90 (prog): 0x{0:X8}" -f (R32 ($b2 + 0x90)))
Write-Host ("  +CC (isConstructed): {0}" -f (R32 ($b2 + 0xCC)))
Write-Host ("  +2E8 (flames): {0}" -f (R32 ($b2 + 0x2E8)))

[MWatch]::CloseHandle($h)
