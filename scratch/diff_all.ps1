$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class DiffC {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [DiffC]::OpenProcess(0x1F0FFF, $false, $p.Id)
function ReadBuf($a, $n) { $b = New-Object byte[] $n; $r = [IntPtr]::Zero; [DiffC]::ReadProcessMemory($h, [IntPtr]$a, $b, [IntPtr]$n, [ref]$r) | Out-Null; return $b }
function ReadI32($a) { return [BitConverter]::ToInt32((ReadBuf $a 4), 0) }
$pl = [uint32](ReadI32 ($base + 0x513228)); $me = ReadI32 ($pl + 0x6C)
$arr = [uint32](ReadI32 ($base + 0x553568))
$mine = @()
for ($i = 0; $i -lt 500; $i++) {
    $b = $arr + $i * 0x6A4
    if ((ReadI32 ($b + 0x6A0)) -eq 0x68 ) { $mine += $b }
}
Write-Host ("me={0}, my buildings={1}" -f $me, $mine.Count)
foreach ($b in $mine) {
    $snaps = @()
    for ($k = 0; $k -lt 3; $k++) { $snaps += ,(ReadBuf $b 0x6A4); Start-Sleep -Milliseconds 1000 }
    $out = @()
    for ($i = 0; $i -lt 0x6A0; $i += 4) {
        $v = $snaps | ForEach-Object { [BitConverter]::ToUInt32($_, $i) }
        if (($v | Select-Object -Unique).Count -gt 1) { $out += ("  +0x{0:X3}: {1}" -f $i, (($v | ForEach-Object { "0x{0:X}" -f $_ }) -join " -> ")) }
    }
    $td = [uint32](ReadI32 ($b + 0x258))
    $np = [uint32](ReadI32 ($td + 4)); $nb = ReadBuf $np 80
    $name = [System.Text.Encoding]::Unicode.GetString($nb); $z = $name.IndexOf([char]0); if ($z -ge 0) { $name = $name.Substring(0, $z) }
    Write-Host ("Bldg 0x{0:X} '{1}'" -f $b, $name)
    $out | ForEach-Object { Write-Host $_ }
}


