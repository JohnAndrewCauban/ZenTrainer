$p = Get-Process -Name "Battle_Realms_F"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MLine {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [MLine]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [MLine]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }
function RF($a) { $b = New-Object byte[] 4; $o = 0; [MLine]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToSingle($b, 0) }

$b2 = 0x20FB3D6C
Write-Host "Watchtower Bounding / Pos / Render fields:"
for ($off = 0x20; $off -lt 0x60; $off += 4) {
    Write-Host ("  +0x{0:X2}: int={1}, float={2:F2}" -f $off, (R32 ($b2 + $off)), (RF ($b2 + $off)))
}

Write-Host "HP & damage fields:"
Write-Host ("  +0x80: {0}" -f (R32 ($b2 + 0x80)))
Write-Host ("  +0x84: {0}" -f (R32 ($b2 + 0x84)))
Write-Host ("  +0x88 (maxHp): {0}" -f (R32 ($b2 + 0x88)))
Write-Host ("  +0x8C (curHp): {0}" -f (R32 ($b2 + 0x8C)))
Write-Host ("  +0x90 (prog): 0x{0:X8}" -f (R32 ($b2 + 0x90)))
Write-Host ("  +0x94: 0x{0:X8}" -f (R32 ($b2 + 0x94)))

[MLine]::CloseHandle($h)
