$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class PlayerCheck {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [PlayerCheck]::OpenProcess(0x1F0FFF, $false, $id)

function ReadInt($addr) {
    $buf = New-Object byte[] 4
    $read = [IntPtr]::Zero
    [PlayerCheck]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]4, [ref]$read) | Out-Null
    return [BitConverter]::ToInt32($buf, 0)
}

$pPlayer = [uint32](ReadInt ($base + 0x513228))
$playerId = ReadInt ($pPlayer + 0x6C)
$rice = ReadInt ($pPlayer + 0xD4)
$water = ReadInt ($pPlayer + 0xD8)
$yin = ReadInt ($pPlayer + 0x2E4)
$yang = ReadInt ($pPlayer + 0x2E8)
Write-Host ("pPlayer: 0x{0:X}, playerId: {1}, Rice: {2}, Water: {3}, Yin: {4}, Yang: {5}" -f $pPlayer, $playerId, $rice, $water, $yin, $yang)

$arrayBase = [uint32](ReadInt ($base + 0x553568))
Write-Host ("arrayBase: 0x{0:X}" -f $arrayBase)

# Check buildings for this player
$playerBldgs = 0
for ($i = 0; $i -lt 500; $i++) {
    $bldg = $arrayBase + $i * 0x6A4
    $tag = ReadInt ($bldg + 0x6A0)
    if ($tag -eq 0x68) {
        $owner = ReadInt ($bldg + 0x78)
        $typeDef = [uint32](ReadInt ($bldg + 0x258))
        $maxHp = 0
        if ($typeDef -ge 0x01000000) { $maxHp = ReadInt ($typeDef + 0x2C) }
        $curHp = ReadInt ($bldg + 0x8C)
        $t1 = ReadInt ($bldg + 0x490)
        $t2 = ReadInt ($bldg + 0x4B4)
        if ($owner -eq $playerId) {
            $playerBldgs++
            Write-Host ("Player Bldg [{0}] @ 0x{1:X}: MaxHP={2}, CurHP={3} (0x{4:X}), T1=0x{5:X}, T2=0x{6:X}" -f $i, $bldg, $maxHp, ($curHp -shr 16), $curHp, $t1, $t2)
        }
    }
}
Write-Host ("Player buildings: {0}" -f $playerBldgs)
