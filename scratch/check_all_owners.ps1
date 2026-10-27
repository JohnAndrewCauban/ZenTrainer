$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class MAll {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [MAll]::OpenProcess(0x1F0FFF, $false, $p.Id)

function ReadI32($addr) {
    $b = New-Object byte[] 4; $r = [IntPtr]::Zero
    [MAll]::ReadProcessMemory($h, [IntPtr]$addr, $b, [IntPtr]4, [ref]$r) | Out-Null
    return [BitConverter]::ToInt32($b, 0)
}
function ReadStrW($addr) {
    if ($addr -lt 0x10000) { return "" }
    $b = New-Object byte[] 64; $r = [IntPtr]::Zero
    [MAll]::ReadProcessMemory($h, [IntPtr]$addr, $b, [IntPtr]64, [ref]$r) | Out-Null
    $s = [System.Text.Encoding]::Unicode.GetString($b)
    $z = $s.IndexOf([char]0)
    return if ($z -ge 0) { $s.Substring(0, $z) } else { $s }
}

$arr = [uint32](ReadI32 ($base + 0x553568))

for ($i = 0; $i -lt 500; $i++) {
    $b = $arr + $i * 0x6A4
    if ((ReadI32 ($b + 0x6A0)) -eq 0x68) {
        $td = [uint32](ReadI32 ($b + 0x258))
        if ($td -ge 0x01000000) {
            $name = ReadStrW (ReadI32 ($td + 4))
            if ($name -ne "") {
                $f78 = ReadI32 ($b + 0x78)
                $f7C = ReadI32 ($b + 0x7C)
                $f84 = ReadI32 ($b + 0x84)
                $f64 = ReadI32 ($b + 0x64)
                Write-Host ("Bldg [{0,2}] '{1,-25}': +0x64={2,2}, +0x78=0x{3:X8} ({3,3}), +0x7C={4,2}, +0x84={5,2}" -f $i, $name, $f64, $f78, $f7C, $f84)
            }
        }
    }
}
