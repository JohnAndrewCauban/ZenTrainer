$lines = Get-Content 'C:\Users\HP\.gemini\antigravity-ide\brain\8e642745-f1c6-4a2b-9f65-be99f4018930\.system_generated\logs\transcript.jsonl'
foreach ($l in $lines) {
    if ($l -match '"step_index":(43[789])') {
        $obj = $l | ConvertFrom-Json
        Write-Host ("=== Step {0} ({1}) ===" -f $obj.step_index, $obj.type)
        if ($obj.tool_calls) {
            Write-Host $obj.tool_calls[0].args.CommandLine
        }
        if ($obj.content) {
            Write-Host $obj.content
        }
    }
}
