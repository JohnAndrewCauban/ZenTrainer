$p = Get-Process -Name "Battle_Realms_F*"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MOwner {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$h = [MOwner]::OpenProcess(0x1F0FFF, $false, $p.Id)
function R32($a) { $b = New-Object byte[] 4; $o = 0; [MOwner]::ReadProcessMemory($h, [IntPtr]$a, $b, 4, [ref]$o) | Out-Null; return [BitConverter]::ToInt32($b, 0) }

# Let's inspect fields of Bldg[0] (Dragon), Bldg[2] (Lotus), Bldg[6] (Serpent), Bldg[48] (Wolf)
$b0 = 0x26AFE024 # Dragon
$b2 = 0x26AFED6C # Lotus
$b6 = 0x26B007FC # Serpent
$b48 = 0x26B11EE4 # Wolf

Write-Host "Comparing building fields for different players:"
for ($off = 0; $off -lt 0x200; $off += 4) {
    $v0 = R32 ($b0 + $off)
    $v2 = R32 ($b2 + $off)
    $v6 = R32 ($b6 + $off)
    $v48 = R32 ($b48 + $off)
    if ($v0 -ne $v2 -or $v0 -ne $v6 -or $v0 -ne $v48) {
        # Check if values are small integers like 0, 1, 2, 3 (player IDs!)
        if ($v0 -ge 0 -and $v0 -le 8 -and $v2 -ge 0 -and $v2 -le 8 -and $v6 -ge 0 -and $v6 -le 8) {
            Write-Host ("POTENTIAL PLAYER ID at +0x{0:X3}: B0={1}, B2={2}, B6={3}, B48={4}" -f $off, $v0, $v2, $v6, $v48)
        }
    }
}

[MOwner]::CloseHandle($h)
