$lines = Get-Content 'Trainer\tools\ic.asm' -Encoding Unicode
Write-Host ("Lines in ic.asm: " + $lines.Count)
$lines | Select-Object -First 30 | ForEach-Object { Write-Host $_ }
