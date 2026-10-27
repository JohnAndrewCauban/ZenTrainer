$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class DiffB {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [DiffB]::OpenProcess(0x1F0FFF, $false, $p.Id)
function RB($a, $n) { $b = New-Object byte[] $n; $r = [IntPtr]::Zero; [DiffB]::ReadProcessMemory($h, [IntPtr]$a, $b, [IntPtr]$n, [ref]$r) | Out-Null; return $b }
$sel = [BitConverter]::ToUInt32((RB ($base + 0x554AC0) 4), 0)
Write-Host ("Selected: 0x{0:X}" -f $sel)
$snaps = @()
for ($k = 0; $k -lt 4; $k++) { $snaps += ,(RB $sel 0x6A4); Start-Sleep -Milliseconds 1500 }
for ($i = 0; $i -lt 0x6A0; $i += 4) {
    $vals = $snaps | ForEach-Object { [BitConverter]::ToUInt32($_, $i) }
    if (($vals | Select-Object -Unique).Count -gt 1) {
        Write-Host ("+0x{0:X3}: {1}" -f $i, (($vals | ForEach-Object { "0x{0:X}" -f $_ }) -join " -> "))
    }
}
