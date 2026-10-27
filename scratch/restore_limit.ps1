$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class PlRestore {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr w);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [PlRestore]::OpenProcess(0x1F0FFF, $false, $p.Id)

function ReadI32($addr) {
    $b = New-Object byte[] 4; $r = [IntPtr]::Zero
    [PlRestore]::ReadProcessMemory($h, [IntPtr]$addr, $b, [IntPtr]4, [ref]$r) | Out-Null
    return [BitConverter]::ToInt32($b, 0)
}
function WriteI32($addr, $v) {
    $b = [BitConverter]::GetBytes([int]$v); $w = [IntPtr]::Zero
    [PlRestore]::WriteProcessMemory($h, [IntPtr]$addr, $b, [IntPtr]4, [ref]$w) | Out-Null
}

$pl = [uint32](ReadI32 ($base + 0x513228))
$me = ReadI32 ($pl + 0x6C)
$conf = ReadI32 ($pl + 0x4AC + $me * 0x28)
$limitAddr = $base + 0x539728 + 4 * $me
$cur = ReadI32 $limitAddr

Write-Host "Player ID: $me"
Write-Host "Configured limit for this mission/settings: $conf"
Write-Host "Current limit in memory: $cur"

if ($conf -gt 0 -and $conf -ne 500) {
    WriteI32 $limitAddr $conf
    Write-Host "Restored limit to configured scenario value: $conf"
}
