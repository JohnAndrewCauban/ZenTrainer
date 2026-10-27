$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class DiffX {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [DiffX]::OpenProcess(0x1F0FFF, $false, $p.Id)
function ReadBuf($a, $n) { $b = New-Object byte[] $n; $r = [IntPtr]::Zero; $ok = [DiffX]::ReadProcessMemory($h, [IntPtr]$a, $b, [IntPtr]$n, [ref]$r); if (-not $ok) { return $null }; return $b }
function ReadI32($a) { $b = ReadBuf $a 4; if ($b) { return [BitConverter]::ToInt32($b, 0) } else { return 0 } }
$arr = [uint32](ReadI32 ($base + 0x553568))
$tower = $arr + 68 * 0x6A4
# collect pointers inside the tower struct
$ptrs = @{}
$tb = ReadBuf $tower 0x6A4
for ($i = 0; $i -lt 0x6A0; $i += 4) {
    $v = [BitConverter]::ToUInt32($tb, $i)
    if ($v -gt 0x1000000 -and $v -lt 0x7FFF0000 -and ($v -lt $tower -or $v -gt $tower + 0x6A4)) {
        if (ReadBuf $v 0x80) { $ptrs[$i] = $v }
    }
}
Write-Host ("pointers: {0}" -f $ptrs.Count)
$snaps = @{}
for ($k = 0; $k -lt 3; $k++) {
    foreach ($o in $ptrs.Keys) { if (-not $snaps.ContainsKey($o)) { $snaps[$o] = @() }; $snaps[$o] += ,(ReadBuf $ptrs[$o] 0x80) }
    Start-Sleep -Milliseconds 1200
}
foreach ($o in ($ptrs.Keys | Sort-Object)) {
    $s = $snaps[$o]; if ($s.Count -lt 3 -or $s -contains $null) { continue }
    for ($i = 0; $i -lt 0x80; $i += 4) {
        $v = $s | ForEach-Object { [BitConverter]::ToUInt32($_, $i) }
        if (($v | Select-Object -Unique).Count -gt 1) { Write-Host ("tower+0x{0:X3} -> 0x{1:X} +0x{2:X2}: {3}" -f $o, $ptrs[$o], $i, (($v | ForEach-Object { "0x{0:X}" -f $_ }) -join " -> ")) }
    }
}
