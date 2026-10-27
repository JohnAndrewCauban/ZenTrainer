$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class FindPlayer {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [FindPlayer]::OpenProcess(0x1F0FFF, $false, $id)

function ReadInt($addr) {
    $buf = New-Object byte[] 4
    $read = [IntPtr]::Zero
    [FindPlayer]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]4, [ref]$read) | Out-Null
    return [BitConverter]::ToInt32($buf, 0)
}

function ReadStrW($addr) {
    if ($addr -eq 0 -or $addr -lt 0x10000) { return "" }
    $buf = New-Object byte[] 128
    $read = [IntPtr]::Zero
    if (![FindPlayer]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]128, [ref]$read)) { return "" }
    $str = [System.Text.Encoding]::Unicode.GetString($buf)
    $nullIdx = $str.IndexOf("`0")
    if ($nullIdx -ge 0) { $str = $str.Substring(0, $nullIdx) }
    return $str
}

$pPlayer = [uint32](ReadInt ($base + 0x513228))
$playerId = ReadInt ($pPlayer + 0x6C)
$arrayBase = [uint32](ReadInt ($base + 0x553568))
Write-Host ("pPlayer: 0x{0:X}, playerId: {1}, arrayBase: 0x{2:X}" -f $pPlayer, $playerId, $arrayBase)

for ($i = 0; $i -lt 500; $i++) {
    $bldg = $arrayBase + $i * 0x6A4
    $tag = ReadInt ($bldg + 0x6A0)
    if ($tag -eq 0x68) {
        $owner = ReadInt ($bldg + 0x78)
        $typeDef = [uint32](ReadInt ($bldg + 0x258))
        if ($typeDef -ge 0x01000000) {
            $namePtr = [uint32](ReadInt ($typeDef + 0x04))
            $name = ReadStrW $namePtr
            $curHp = ReadInt ($bldg + 0x8C)
            $t1 = ReadInt ($bldg + 0x490)
            $t2 = ReadInt ($bldg + 0x4B4)
            Write-Host ("Bldg [{0}] @ 0x{1:X}: Owner={2} Name='{3}' CurHP={4} T1=0x{5:X} T2=0x{6:X}" -f $i, $bldg, $owner, $name, ($curHp -shr 16), $t1, $t2)
        }
    }
}
