$p = Get-Process -Name "Battle_Realms_F"
$base = $p.MainModule.BaseAddress.ToInt64()

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class M {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, int s, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@

$h = [M]::OpenProcess(0x1F0FFF, $false, $p.Id)

function Read-Int32($addr) {
    $b = New-Object byte[] 4
    $out = 0
    [M]::ReadProcessMemory($h, [IntPtr]$addr, $b, 4, [ref]$out) | Out-Null
    return [BitConverter]::ToInt32($b, 0)
}

function Read-Bytes($addr, $len) {
    $b = New-Object byte[] $len
    $out = 0
    [M]::ReadProcessMemory($h, [IntPtr]$addr, $b, $len, [ref]$out) | Out-Null
    return $b
}

$pPlayer = Read-Int32 ($base + 0x513228)
$localPlayerId = -1
if ($pPlayer -ne 0) {
    $localPlayerId = Read-Int32 ($pPlayer + 0x6C)
}

$selPtr = Read-Int32 ($base + 0x554AC0)
Write-Host ("pPlayer: 0x{0:X8}, localPlayerId: {1}, selPtr: 0x{2:X8}" -f $pPlayer, $localPlayerId, $selPtr)

if ($selPtr -ne 0) {
    $tag = Read-Int32 ($selPtr + 0x6A0)
    $owner78 = Read-Int32 ($selPtr + 0x78)
    $team7c = Read-Int32 ($selPtr + 0x7C)
    $curHp = Read-Int32 ($selPtr + 0x8C)
    $maxHp = Read-Int32 ($selPtr + 0x88)
    $prog90 = Read-Int32 ($selPtr + 0x90)
    $td = Read-Int32 ($selPtr + 0x258)
    Write-Host ("Selected: tag=0x{0:X}, +78(owner)={1}, +7C(team)={2}, CurHP={3} ({4:F1}), MaxHP={5} ({6:F1}), +90(prog)=0x{7:X8}, TD=0x{8:X8}" -f `
        $tag, $owner78, $team7c, $curHp, ($curHp / 65536.0), $maxHp, ($maxHp / 65536.0), $prog90, $td)
    if ($td -ge 0x01000000) {
        $namePtr = Read-Int32 ($td + 4)
        if ($namePtr -ge 0x01000000) {
            $nb = Read-Bytes $namePtr 40
            $name = [System.Text.Encoding]::Unicode.GetString($nb)
            Write-Host ("Selected Name: " + $name)
        }
    }
}

# Now inspect all active buildings in arrayBase
$arrayBase = Read-Int32 ($base + 0x553568)
Write-Host ("arrayBase: 0x{0:X8}" -f $arrayBase)
for ($i = 0; $i -lt 500; $i++) {
    $bldg = $arrayBase + ($i * 0x6A4)
    $tag = Read-Int32 ($bldg + 0x6A0)
    if ($tag -ne 0x68) { continue }
    $owner78 = Read-Int32 ($bldg + 0x78)
    $team7c = Read-Int32 ($bldg + 0x7C)
    $curHp = Read-Int32 ($bldg + 0x8C)
    $maxHp = Read-Int32 ($bldg + 0x88)
    $prog90 = Read-Int32 ($bldg + 0x90)
    $td = Read-Int32 ($bldg + 0x258)
    $name = "Unknown"
    if ($td -ge 0x01000000) {
        $namePtr = Read-Int32 ($td + 4)
        if ($namePtr -ge 0x01000000) {
            $nb = Read-Bytes $namePtr 40
            $name = [System.Text.Encoding]::Unicode.GetString($nb).Trim([char]0)
        }
    }
    Write-Host ("Bldg[{0}]: addr=0x{1:X8}, name={2}, +78(owner)={3}, +7C(team)={4}, HP={5:F0}/{6:F0}, prog90=0x{7:X8}" -f `
        $i, $bldg, $name, $owner78, $team7c, ($curHp / 65536.0), ($maxHp / 65536.0), $prog90)
}

[M]::CloseHandle($h)
