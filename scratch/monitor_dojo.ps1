$p = Get-Process Battle_Realms_F
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class MonitorDojo {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [MonitorDojo]::OpenProcess(0x1F0FFF, $false, $id)

function ReadInt($addr) {
    $buf = New-Object byte[] 4
    $read = [IntPtr]::Zero
    [MonitorDojo]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]4, [ref]$read) | Out-Null
    return [BitConverter]::ToInt32($buf, 0)
}

$dojo = 0x22F6DFD4
for ($k = 0; $k -lt 5; $k++) {
    $t1 = ReadInt ($dojo + 0x490)
    $t2 = ReadInt ($dojo + 0x4B4)
    Write-Host ("Tick {0}: T1=0x{1:X8} ({2}) T2=0x{3:X8}" -f $k, $t1, $t1, $t2)
    Start-Sleep -Milliseconds 500
}
