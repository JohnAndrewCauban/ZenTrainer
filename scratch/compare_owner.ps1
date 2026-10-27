$p = Get-Process Battle_Realms_F
$id = $p.Id
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class MDump {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [MDump]::OpenProcess(0x1F0FFF, $false, $id)

function ReadBuf($a, $n) {
    $b = New-Object byte[] $n; $r = [IntPtr]::Zero
    [MDump]::ReadProcessMemory($h, [IntPtr]$addr, $b, [IntPtr]$n, [ref]$r) | Out-Null
    return $b
}

$wolf = 0x23799024  # Player's Wolf Keep
$lotus = 0x2379C544 # Enemy Lotus Watchtower

$wb = New-Object byte[] 0x100
$lb = New-Object byte[] 0x100
$r = [IntPtr]::Zero
[MDump]::ReadProcessMemory($h, [IntPtr]$wolf, $wb, [IntPtr]0x100, [ref]$r) | Out-Null
[MDump]::ReadProcessMemory($h, [IntPtr]$lotus, $lb, [IntPtr]0x100, [ref]$r) | Out-Null

Write-Host "Comparing Wolf Keep (Player) vs Lotus Watchtower (Enemy):"
for ($i = 0; $i -lt 0x100; $i += 4) {
    $wv = [BitConverter]::ToUInt32($wb, $i)
    $lv = [BitConverter]::ToUInt32($lb, $i)
    if ($wv -ne $lv) {
        Write-Host ("  +0x{0:X2}: Wolf=0x{1:X8} ({1}) | Lotus=0x{2:X8} ({2})" -f $i, $wv, $lv)
    }
}
