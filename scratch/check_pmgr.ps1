$p = Get-Process -Name Battle_Realms_F -ErrorAction Stop
$base = $p.MainModule.BaseAddress.ToInt64()

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class MemCheck2 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")]
    public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [MemCheck2]::OpenProcess(0x1F0FFF, $false, $p.Id)

function ReadBytes($addr, $len) {
    $buf = New-Object byte[] $len
    $read = [IntPtr]::Zero
    [MemCheck2]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]$len, [ref]$read) | Out-Null
    return $buf
}

$pMgr = [BitConverter]::ToUInt32((ReadBytes ($base + 0x553568) 4), 0)
Write-Host ("pMgr: 0x{0:X}" -f $pMgr)

$mgrBytes = ReadBytes $pMgr 0x80
for ($i = 0; $i -lt 0x80; $i += 4) {
    $val = [BitConverter]::ToUInt32($mgrBytes, $i)
    Write-Host ("+0x{0:X2}: 0x{1:X8}" -f $i, $val)
}
