$p = Get-Process Battle_Realms_F
$base = [int64]$p.MainModule.BaseAddress
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class InspectB {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
}
"@
Add-Type -TypeDefinition $pinvoke -ErrorAction SilentlyContinue
$h = [InspectB]::OpenProcess(0x1F0FFF, $false, $p.Id)

function ReadBuf($a, $n) {
    $b = New-Object byte[] $n
    $r = [IntPtr]::Zero
    [InspectB]::ReadProcessMemory($h, [IntPtr]$a, $b, [IntPtr]$n, [ref]$r) | Out-Null
    return $b
}
function ReadI32($a) { return [BitConverter]::ToInt32((ReadBuf $a 4), 0) }
function ReadFloat($a) { return [BitConverter]::ToSingle((ReadBuf $a 4), 0) }

$pl = [uint32](ReadI32 ($base + 0x513228))
$me = ReadI32 ($pl + 0x6C)
$arr = [uint32](ReadI32 ($base + 0x553568))

Write-Host "Local Player ID: $me"
for ($i = 0; $i -lt 500; $i++) {
    $b = $arr + $i * 0x6A4
    if ((ReadI32 ($b + 0x6A0)) -eq 0x68 -and (ReadI32 ($b + 0x78)) -eq $me) {
        $td = [uint32](ReadI32 ($b + 0x258))
        $name = ""
        $maxHp = 0
        if ($td -ge 0x01000000) {
            $maxHp = ReadI32 ($td + 0x2C)
            $np = [uint32](ReadI32 ($td + 4))
            $nb = ReadBuf $np 40
            $name = [System.Text.Encoding]::Unicode.GetString($nb)
            $z = $name.IndexOf([char]0)
            if ($z -ge 0) { $name = $name.Substring(0, $z) }
        }
        Write-Host ("--- Building [{0}] 0x{1:X} '{2}' MaxHP={3} ---" -f $i, $b, $name, $maxHp)
        for ($off = 0x80; $off -le 0xB0; $off += 4) {
            $raw = ReadI32 ($b + $off)
            $flt = ReadFloat ($b + $off)
            Write-Host ("  +0x{0:X2}: 0x{1:X8} (int={2}, >>16={3}, float={4:F4})" -f $off, $raw, $raw, ($raw -shr 16), $flt)
        }
    }
}
