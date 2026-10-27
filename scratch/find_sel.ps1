$zenPath = 'C:\Users\HP\.gemini\antigravity-ide\brain\8e642745-f1c6-4a2b-9f65-be99f4018930\scratch\zen.asm'
Select-String -Path $zenPath -Pattern 'RegisterBuildingSelected' -Context 0,25 | ForEach-Object {
    Write-Host $_.Line
    $_.Context.PostContext | ForEach-Object { Write-Host $_ }
}
