$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class HutInspect {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [HutInspect]::OpenProcess(0x1F0FFF, $false, $id)

function ReadInt($addr) {
    $buf = New-Object byte[] 4
    $read = [IntPtr]::Zero
    [HutInspect]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]4, [ref]$read) | Out-Null
    return [BitConverter]::ToInt32($buf, 0)
}

$arrayBase = [uint32](ReadInt ($base + 0x553568))

for ($i = 0; $i -lt 500; $i++) {
    $bldg = $arrayBase + $i * 0x6A4
    $tag = ReadInt ($bldg + 0x6A0)
    if ($tag -eq 0x68) {
        $typeDef = [uint32](ReadInt ($bldg + 0x258))
        if ($typeDef -ge 0x01000000) {
            $maxHp = ReadInt ($typeDef + 0x2C)
            if ($maxHp -eq 650) {
                $owner = ReadInt ($bldg + 0x78)
                $curHp = ReadInt ($bldg + 0x8C)
                $t1 = ReadInt ($bldg + 0x490)
                $t2 = ReadInt ($bldg + 0x4B4)
                Write-Host ("Hut [{0}] @ 0x{1:X}: Owner={2} CurHP={3} T1=0x{4:X} T2=0x{5:X}" -f $i, $bldg, $owner, ($curHp -shr 16), $t1, $t2)
            }
        }
    }
}
