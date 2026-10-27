$p = Get-Process Battle_Realms_F
$id = $p.Id
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class MComp {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [MComp]::OpenProcess(0x1F0FFF, $false, $id)

function Dump($name, $addr) {
    Write-Host "`n$name (@ 0x$($addr.ToString('X'))):"
    $buf = New-Object byte[] 64
    $r = [IntPtr]::Zero
    [MComp]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]64, [ref]$r) | Out-Null
    for ($i = 0; $i -lt 64; $i += 4) {
        $v = [BitConverter]::ToUInt32($buf, $i)
        $f = [BitConverter]::ToSingle($buf, $i)
        Write-Host ("  +0x{0:X2}: 0x{1:X8} ({2,10}) [flt: {3}]" -f ($i + 0x80), $v, $v, $f)
    }
}

Dump "Barrier (Healthy)" (0x237A28E0 + 0x80)
Dump "Hut (Burning)" (0x237996C8 + 0x80)
Dump "Well (Healthy)" (0x237A3CCC + 0x80)
