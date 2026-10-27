$p = Get-Process Battle_Realms_F
$id = $p.Id
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class MDiff {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [MDiff]::OpenProcess(0x1F0FFF, $false, $id)

function ReadBuf($a, $n) {
    $b = New-Object byte[] $n
    $r = [IntPtr]::Zero
    [MDiff]::ReadProcessMemory($h, [IntPtr]$a, $b, [IntPtr]$n, [ref]$r) | Out-Null
    return $b
}

$hut = 0x237996C8 # Burning Hut
$well = 0x237A3CCC # Well (Healthy)
$hb = ReadBuf $hut 0x6A4
$wb = ReadBuf $well 0x6A4

Write-Host "Nonzero differences between Burning Hut and Healthy Well:"
for ($i = 0; $i -lt 0x6A0; $i += 4) {
    $hv = [BitConverter]::ToUInt32($hb, $i)
    $wv = [BitConverter]::ToUInt32($wb, $i)
    if ($hv -ne $wv) {
        Write-Host ("  +0x{0:X3}: Hut=0x{1:X8} ({1}) | Well=0x{2:X8} ({2})" -f $i, $hv, $wv)
    }
}
