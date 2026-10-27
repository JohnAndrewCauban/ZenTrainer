$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class TdInspect3 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [TdInspect3]::OpenProcess(0x1F0FFF, $false, $id)

function ReadStr($addr) {
    $buf = New-Object byte[] 64
    $read = [IntPtr]::Zero
    [TdInspect3]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]64, [ref]$read) | Out-Null
    $len = 0
    while ($len -lt 64 -and $buf[$len] -ne 0) { $len++ }
    return [System.Text.Encoding]::ASCII.GetString($buf, 0, $len)
}

Write-Host ("+0x04: " + (ReadStr 0x0BF9A1F0))
Write-Host ("+0x08: " + (ReadStr 0x0BF9A160))
