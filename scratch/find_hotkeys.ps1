$content = Get-Content 'Trainer\tools\ic.asm'
for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match 'GetAsyncKeyState') {
        Write-Host ("Line {0}: {1}" -f $i, $content[$i])
        for ($j = [Math]::Max(0, $i - 10); $j -le [Math]::Min($content.Length - 1, $i + 30); $j++) {
            Write-Host ("  {0,5}: {1}" -f $j, $content[$j])
        }
    }
}
