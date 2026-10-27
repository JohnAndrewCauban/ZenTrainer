$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class TdInspect4 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [TdInspect4]::OpenProcess(0x1F0FFF, $false, $id)

function ReadStrW($addr) {
    $buf = New-Object byte[] 128
    $read = [IntPtr]::Zero
    [TdInspect4]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]128, [ref]$read) | Out-Null
    $str = [System.Text.Encoding]::Unicode.GetString($buf)
    $nullIdx = $str.IndexOf("`0")
    if ($nullIdx -ge 0) { $str = $str.Substring(0, $nullIdx) }
    return $str
}

Write-Host ("+0x04: " + (ReadStrW 0x0BF9A1F0))
