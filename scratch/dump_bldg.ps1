$p = Get-Process Battle_Realms_F
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class BldgFields {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [BldgFields]::OpenProcess(0x1F0FFF, $false, $id)

function ReadBytes($addr, $len) {
    $buf = New-Object byte[] $len
    $read = [IntPtr]::Zero
    [BldgFields]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]$len, [ref]$read) | Out-Null
    return $buf
}

$bldg = 0x22F79320
$bytes = ReadBytes $bldg 0x6A4
Write-Host ("Dumping nonzero fields of building at 0x{0:X}:" -f $bldg)
for ($i = 0; $i -lt 0x6A4; $i += 4) {
    $val = [BitConverter]::ToUInt32($bytes, $i)
    $flt = [BitConverter]::ToSingle($bytes, $i)
    if ($val -ne 0) {
        Write-Host ("  +0x{0:X3}: 0x{1:X8} ({2,10}) [flt: {3:F3}]" -f $i, $val, $val, $flt)
    }
}
