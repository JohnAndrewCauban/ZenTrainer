$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class TdInspect2 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [TdInspect2]::OpenProcess(0x1F0FFF, $false, $id)

function ReadBytes($addr, $len) {
    $buf = New-Object byte[] $len
    $read = [IntPtr]::Zero
    [TdInspect2]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]$len, [ref]$read) | Out-Null
    return $buf
}

$buf = ReadBytes (0x22F79320 + 0x258) 4
$typeDef = [BitConverter]::ToUInt32($buf, 0)
Write-Host ("typeDef: 0x{0:X}" -f $typeDef)
$tdBytes = ReadBytes $typeDef 0x80
for ($i = 0; $i -lt 0x80; $i += 4) {
    $v = [BitConverter]::ToUInt32($tdBytes, $i)
    Write-Host ("+0x{0:X2}: 0x{1:X8}" -f $i, $v)
}
