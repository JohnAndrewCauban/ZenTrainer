$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class TestF5 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr w);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [TestF5]::OpenProcess(0x1F0FFF, $false, $id)

function ReadInt($addr) {
    $buf = New-Object byte[] 4
    $read = [IntPtr]::Zero
    [TestF5]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]4, [ref]$read) | Out-Null
    return [BitConverter]::ToInt32($buf, 0)
}
function WriteInt($addr, $v) {
    $buf = [BitConverter]::GetBytes([int]$v)
    $w = [IntPtr]::Zero
    [TestF5]::WriteProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]4, [ref]$w) | Out-Null
}

$selPtr = [uint32](ReadInt ($base + 0x554AC0))
Write-Host ("Selected entity: 0x{0:X}" -f $selPtr)

if ($selPtr -ne 0) {
    $tag = ReadInt ($selPtr + 0x6A0)
    $t1 = ReadInt ($selPtr + 0x490)
    $t2 = ReadInt ($selPtr + 0x4B4)
    Write-Host ("Tag: 0x{0:X}, T1: 0x{1:X}, T2: 0x{2:X}" -f $tag, $t1, $t2)
}
