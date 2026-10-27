$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class DiffW {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [DiffW]::OpenProcess(0x1F0FFF, $false, $p.Id)
function ReadBuf($a, $n) { $b = New-Object byte[] $n; $r = [IntPtr]::Zero; [DiffW]::ReadProcessMemory($h, [IntPtr]$a, $b, [IntPtr]$n, [ref]$r) | Out-Null; return $b }
function ReadI32($a) { return [BitConverter]::ToInt32((ReadBuf $a 4), 0) }
$arr = [uint32](ReadI32 ($base + 0x553568))
$targets = @()
for ($i = 0; $i -lt 500; $i++) {
    $b = $arr + $i * 0x6A4
    if ((ReadI32 ($b + 0x6A0)) -ne 0x68) { continue }
    $td = [uint32](ReadI32 ($b + 0x258)); if ($td -lt 0x1000000) { continue }
    $np = [uint32](ReadI32 ($td + 4)); $nb = ReadBuf $np 80
    $name = [System.Text.Encoding]::Unicode.GetString($nb); $z = $name.IndexOf([char]0); if ($z -ge 0) { $name = $name.Substring(0, $z) }
    if ($name -like "*Warlock*") { $targets += [pscustomobject]@{ B = $b; N = $name; I = $i } }
}
foreach ($t in $targets) {
    $snaps = @()
    for ($k = 0; $k -lt 4; $k++) { $snaps += ,(ReadBuf $t.B 0x6A4); Start-Sleep -Milliseconds 1000 }
    Write-Host ("== {0} [{1}] 0x{2:X}" -f $t.N, $t.I, $t.B)
    for ($i = 0; $i -lt 0x6A0; $i += 4) {
        $v = $snaps | ForEach-Object { [BitConverter]::ToUInt32($_, $i) }
        if (($v | Select-Object -Unique).Count -gt 1) { Write-Host ("  +0x{0:X3}: {1}" -f $i, (($v | ForEach-Object { "0x{0:X}" -f $_ }) -join " -> ")) }
    }
    Write-Host "  nonzero 0x470-0x4F0:"
    for ($i = 0x470; $i -lt 0x4F0; $i += 4) { $x = [BitConverter]::ToUInt32($snaps[3], $i); if ($x -ne 0) { Write-Host ("   +0x{0:X3}=0x{1:X}" -f $i, $x) } }
}
