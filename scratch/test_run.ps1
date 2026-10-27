$p = [System.Diagnostics.Process]::Start("scratch\test_trimmed\BRTrainer.exe")
Start-Sleep -Milliseconds 1500
$running = -not $p.HasExited
Write-Host "Process running: $running (PID $($p.Id))"
if ($running) { $p.Kill() }
