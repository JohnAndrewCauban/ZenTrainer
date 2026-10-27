$p = Get-Process Battle_Realms_F
$id = $p.Id
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class BurnTrack {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [BurnTrack]::OpenProcess(0x1F0FFF, $false, $id)

function ReadInt($addr) {
    $b = New-Object byte[] 4; $r = [IntPtr]::Zero
    [BurnTrack]::ReadProcessMemory($h, [IntPtr]$addr, $b, [IntPtr]4, [ref]$r) | Out-Null
    return [BitConverter]::ToInt32($b, 0)
}

$hut = 0x237996C8
Write-Host "Tracking Hut 0x$($hut.ToString('X')):"
for ($k = 0; $k -lt 5; $k++) {
    $curHp = ReadInt ($hut + 0x8C)
    $f80 = ReadInt ($hut + 0x80)
    $f84 = ReadInt ($hut + 0x84)
    $f88 = ReadInt ($hut + 0x88)
    $f90 = ReadInt ($hut + 0x90)
    $f94 = ReadInt ($hut + 0x94)
    Write-Host ("Tick {0}: CurHP=0x{1:X8} ({2}), +0x80=0x{3:X8} ({4}), +0x84=0x{5:X8}, +0x90=0x{6:X8}" -f $k, $curHp, ($curHp -shr 16), $f80, $f80, $f84, $f90)
    Start-Sleep -Milliseconds 600
}
