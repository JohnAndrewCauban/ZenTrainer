$p = Get-Process -Name "Battle_Realms_F"
$base = $p.MainModule.BaseAddress.ToInt64()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class M9 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [M9]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [M9]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

$bldg23 = 0x20FBC8E0 # Dragon Dojo (player's placed building)
Write-Host "Searching for player-related pointers or IDs in Bldg[23]..."
$pPlayer = R32 ($base + 0x513228)

for ($off = 0; $off -lt 0x6A4; $off += 4) {
    $v = R32 ($bldg23 + $off)
    if ($v -eq $pPlayer) {
        Write-Host ("Found pPlayer pointer at offset +0x{0:X3}!" -f $off)
    }
}

[M9]::CloseHandle($h)
