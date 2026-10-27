$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$id = $p.Id

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class AllBldgs {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [AllBldgs]::OpenProcess(0x1F0FFF, $false, $id)

function ReadInt($addr) {
    $buf = New-Object byte[] 4
    $read = [IntPtr]::Zero
    [AllBldgs]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]4, [ref]$read) | Out-Null
    return [BitConverter]::ToInt32($buf, 0)
}

function ReadStrW($addr) {
    if ($addr -eq 0 -or $addr -lt 0x10000) { return "" }
    $buf = New-Object byte[] 128
    $read = [IntPtr]::Zero
    if (![AllBldgs]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]128, [ref]$read)) { return "" }
    $str = [System.Text.Encoding]::Unicode.GetString($buf)
    $nullIdx = $str.IndexOf("`0")
    if ($nullIdx -ge 0) { $str = $str.Substring(0, $nullIdx) }
    return $str
}

$pPlayer = [uint32](ReadInt ($base + 0x513228))
$playerId = ReadInt ($pPlayer + 0x6C)
$arrayBase = [uint32](ReadInt ($base + 0x553568))

$all = @{}
for ($i = 0; $i -lt 500; $i++) {
    $bldg = $arrayBase + $i * 0x6A4
    $tag = ReadInt ($bldg + 0x6A0)
    if ($tag -eq 0x68) {
        $owner = ReadInt ($bldg + 0x78)
        $typeDef = [uint32](ReadInt ($bldg + 0x258))
        if ($typeDef -ge 0x01000000) {
            $namePtr = [uint32](ReadInt ($typeDef + 0x04))
            $name = ReadStrW $namePtr
            $maxHp = ReadInt ($typeDef + 0x2C)
            $curHp = ReadInt ($bldg + 0x8C)
            $t1 = ReadInt ($bldg + 0x490)
            $t2 = ReadInt ($bldg + 0x4B4)
            if (-not $all.ContainsKey($name)) {
                $all[$name] = @{ MaxHp = $maxHp; Owner = $owner; Count = 0; T1 = $t1; T2 = $t2 }
            }
            $all[$name].Count++
            Write-Host ("Bldg [{0}] @ 0x{1:X}: Owner={2} (pId={3}) '{4}' MaxHP={5} CurHP={6} (0x{7:X}) T1=0x{8:X} T2=0x{9:X}" -f $i, $bldg, $owner, $playerId, $name, $maxHp, ($curHp -shr 16), $curHp, $t1, $t2)
        }
    }
}

Write-Host "`nAll building types on map:"
foreach ($k in $all.Keys) {
    Write-Host ("  {0}: MaxHP={1}, Count={2}" -f $k, $all[$k].MaxHp, $all[$k].Count)
}
