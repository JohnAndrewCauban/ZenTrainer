$p = Get-Process -Name Battle_Realms_F -ErrorAction Stop
$base = $p.MainModule.BaseAddress.ToInt64()
Write-Host ("Base: 0x{0:X}" -f $base)

$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class MemCheck {
    [DllImport("kernel32.dll")]
    public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")]
    public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke
$h = [MemCheck]::OpenProcess(0x1F0FFF, $false, $p.Id)

function ReadInt($addr) {
    $buf = New-Object byte[] 4
    $read = [IntPtr]::Zero
    [MemCheck]::ReadProcessMemory($h, [IntPtr]$addr, $buf, [IntPtr]4, [ref]$read) | Out-Null
    return [BitConverter]::ToInt32($buf, 0)
}

$pMgrPtr = $base + 0x553568
$pMgr = [uint32](ReadInt $pMgrPtr)
Write-Host ("pMgr: 0x{0:X}" -f $pMgr)

if ($pMgr -ne 0) {
    $arrBase = [uint32](ReadInt $pMgr)
    Write-Host ("arrBase: 0x{0:X}" -f $arrBase)
    
    $found = 0
    for ($i = 0; $i -lt 500; $i++) {
        $slot = $arrBase + $i * 0x6A4
        $tag = ReadInt ($slot + 0x6A0)
        if ($tag -eq 0x68) {
            $typeDef = [uint32](ReadInt ($slot + 0x258))
            $curHp = ReadInt ($slot + 0x8C)
            $maxHp = 0
            if ($typeDef -ne 0) { $maxHp = ReadInt ($typeDef + 0x2C) }
            $t1 = ReadInt ($slot + 0x490)
            $t2 = ReadInt ($slot + 0x4B4)
            Write-Host ("Slot {0}: Addr=0x{1:X}, Tag=0x{2:X}, TypeDef=0x{3:X}, MaxHP={4}, CurHP={5} (0x{6:X}), T1=0x{7:X}, T2=0x{8:X}" -f $i, $slot, $tag, $typeDef, $maxHp, ($curHp -shr 16), $curHp, $t1, $t2)
            $found++
        }
    }
    Write-Host ("Total active buildings found: {0}" -f $found)
}
