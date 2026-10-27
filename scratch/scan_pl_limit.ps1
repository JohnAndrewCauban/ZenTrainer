$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class PlCheck {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [PlCheck]::OpenProcess(0x1F0FFF, $false, $p.Id)

function ReadI32($addr) {
    $b = New-Object byte[] 4; $r = [IntPtr]::Zero
    [PlCheck]::ReadProcessMemory($h, [IntPtr]$addr, $b, [IntPtr]4, [ref]$r) | Out-Null
    return [BitConverter]::ToInt32($b, 0)
}

$pl = [uint32](ReadI32 ($base + 0x513228))
$me = ReadI32 ($pl + 0x6C)
$curLimit = ReadI32 ($base + 0x539728 + 4 * $me)
Write-Host "Player Struct @ 0x$($pl.ToString('X')), playerId=$me, Current UnitLimit=$curLimit"

Write-Host "Scanning player struct for limit-like values (20, 25, 30, 35, 40, 50, 60, etc.):"
for ($i = 0; $i -lt 0x600; $i += 4) {
    $v = ReadI32 ($pl + $i)
    if ($v -ge 10 -and $v -le 100 -and ($i -ne 0x6C)) {
        Write-Host ("  +0x{0:X3}: {1}" -f $i, $v)
    }
}
