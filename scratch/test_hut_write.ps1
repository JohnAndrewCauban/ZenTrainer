$p = Get-Process Battle_Realms_F
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class HutTest {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr w);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [HutTest]::OpenProcess(0x1F0FFF, $false, $id)

function ReadInt($addr) {
    $buf = New-Object byte[] 4
    $read = [IntPtr]::Zero
    [HutTest]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]4, [ref]$read) | Out-Null
    return [BitConverter]::ToInt32($buf, 0)
}
function WriteInt($addr, $v) {
    $buf = [BitConverter]::GetBytes([int]$v)
    $w = [IntPtr]::Zero
    [HutTest]::WriteProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]4, [ref]$w) | Out-Null
}

$hut = 0x22F69D6C # Hut 2
Write-Host ("Before: T1=0x{0:X}, T2=0x{1:X}" -f (ReadInt ($hut + 0x490)), (ReadInt ($hut + 0x4B4)))
WriteInt ($hut + 0x490) 0x00FFFFFF
WriteInt ($hut + 0x4B4) 0x00FFFFFF
Start-Sleep -Milliseconds 100
Write-Host ("After 100ms: T1=0x{0:X}, T2=0x{1:X}" -f (ReadInt ($hut + 0x490)), (ReadInt ($hut + 0x4B4)))
