$lines = Get-Content 'Trainer\tools\ic.asm' -Encoding Unicode
$lines[300..500] | ForEach-Object { Write-Host $_ }
