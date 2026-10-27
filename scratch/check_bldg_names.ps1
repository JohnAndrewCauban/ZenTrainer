$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class BldgInspect {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [BldgInspect]::OpenProcess(0x1F0FFF, $false, $id)

function ReadInt($addr) {
    $buf = New-Object byte[] 4
    $read = [IntPtr]::Zero
    [BldgInspect]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]4, [ref]$read) | Out-Null
    return [BitConverter]::ToInt32($buf, 0)
}

function ReadString($addr) {
    $buf = New-Object byte[] 64
    $read = [IntPtr]::Zero
    [BldgInspect]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]64, [ref]$read) | Out-Null
    $len = 0
    while ($len -lt 64 -and $buf[$len] -ne 0) { $len++ }
    return [System.Text.Encoding]::ASCII.GetString($buf, 0, $len)
}

$pPlayer = [uint32](ReadInt ($base + 0x513228))
$playerId = ReadInt ($pPlayer + 0x6C)
$arrayBase = [uint32](ReadInt ($base + 0x553568))

for ($i = 0; $i -lt 500; $i++) {
    $bldg = $arrayBase + $i * 0x6A4
    $tag = ReadInt ($bldg + 0x6A0)
    if ($tag -eq 0x68) {
        $owner = ReadInt ($bldg + 0x78)
        $typeDef = [uint32](ReadInt ($bldg + 0x258))
        if ($owner -eq $playerId) {
            $namePtr = [uint32](ReadInt ($typeDef + 0x04))
            $name = ReadString $namePtr
            $curHp = ReadInt ($bldg + 0x8C)
            $maxHp = ReadInt ($typeDef + 0x2C)
            $t1 = ReadInt ($bldg + 0x490)
            $t2 = ReadInt ($bldg + 0x4B4)
            Write-Host ("Player Bldg [{0}] @ 0x{1:X}: Name='{2}' MaxHP={3} CurHP={4} (0x{5:X}) T1=0x{6:X} T2=0x{7:X}" -f $i, $bldg, $name, $maxHp, ($curHp -shr 16), $curHp, $t1, $t2)
        }
    }
}
