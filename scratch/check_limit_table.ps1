$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class PlTable {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [PlTable]::OpenProcess(0x1F0FFF, $false, $p.Id)

function ReadI32($addr) {
    $b = New-Object byte[] 4; $r = [IntPtr]::Zero
    [PlTable]::ReadProcessMemory($h, [IntPtr]$addr, $b, [IntPtr]4, [ref]$r) | Out-Null
    return [BitConverter]::ToInt32($b, 0)
}

$pl = [uint32](ReadI32 ($base + 0x513228))
$me = ReadI32 ($pl + 0x6C)
Write-Host "Player ID: $me"
for ($i = 0; $i -lt 8; $i++) {
    $addr = $pl + 0x4AC + $i * 0x28
    $val = ReadI32 $addr
    Write-Host ("Player [{0}] configured limit @ 0x{1:X}: {2}" -f $i, $addr, $val)
}
