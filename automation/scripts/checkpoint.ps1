<#
.SYNOPSIS
    Checkpoint Script for Daily Life Project.

.DESCRIPTION
    Manages state persistence, PROGRESS.md updates, and report generation
    for the autonomous development orchestrator.

.EXAMPLE
    .\checkpoint.ps1 -Action Status
    Show the current checkpoint state.

.EXAMPLE
    .\checkpoint.ps1 -Action Save -Task "Sprint 1" -Status "COMPLETED"
    Save a checkpoint for the current task.

.EXAMPLE
    .\checkpoint.ps1 -Action UpdateProgress -Task "Sprint 1" -Phase "Phase 1"
    Mark a task complete in docs/PROGRESS.md.

.NOTES
    State files:
    - automation/state/checkpoint.json: Current orchestrator state
    - automation/state/reports/: Generated reports
    - docs/PROGRESS.md: Project progress documentation

    Safety Rules:
    - Never reset or redo work automatically.
    - Always inspect state before resuming.
    - Only commit when the increment is stable.
#>
param(
    [string]$Action = "Status",
    [string]$Task = "",
    [string]$Status = "IN_PROGRESS",
    [string]$StopReason = "",
    [string]$Phase = ""
)

$ErrorActionPreference = "Stop"
$script:RootDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $script:RootDir) { $script:RootDir = (Get-Location).Path }
$script:CheckpointDir = Join-Path $script:RootDir "automation\state"
$script:CheckpointFile = Join-Path $script:CheckpointDir "checkpoint.json"
$script:ProgressFile = Join-Path $script:RootDir "docs\PROGRESS.md"
$script:ReportsDir = Join-Path $script:CheckpointDir "reports"
$script:Date = Get-Date -Format "yyyy-MM-dd"
$script:Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# --- Helpers ---

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = switch ($Level) {
        "PASS" { "[PASS]" }
        "FAIL" { "[FAIL]" }
        "WARN" { "[WARN]" }
        default { "[INFO]" }
    }
    Write-Host "$timestamp $prefix $Message"
}

function Read-Checkpoint {
    if (Test-Path $script:CheckpointFile) {
        try {
            $raw = Get-Content $script:CheckpointFile -Raw
            if ($raw -and $raw.Trim() -ne "" -and $raw.Trim() -ne "{}") {
                return ($raw | ConvertFrom-Json)
            }
        } catch {
            Write-Log "Could not read checkpoint.json: $_" "WARN"
        }
    }
    return $null
}

function Save-Checkpoint {
    param([hashtable]$State)

    if (-not (Test-Path $script:CheckpointDir)) {
        New-Item -ItemType Directory -Path $script:CheckpointDir -Force | Out-Null
    }

    $State | ConvertTo-Json -Depth 5 | Set-Content $script:CheckpointFile -Encoding UTF8
    Write-Log "Checkpoint saved: $($State.Status)" "PASS"
}

function Get-CompletedTasks {
    $completed = @()

    if (Test-Path $script:ProgressFile) {
        $lines = Get-Content $script:ProgressFile
        foreach ($line in $lines) {
            if ($line -match '^\s*-\s*\[x\]\s+(.+)') {
                $completed += $Matches[1].Trim()
            }
        }
    }

    $checkpoint = Read-Checkpoint
    if ($checkpoint -and $checkpoint.completed_tasks) {
        foreach ($t in $checkpoint.completed_tasks) {
            if ($t -and ($completed -notcontains $t)) {
                $completed += $t
            }
        }
    }

    return $completed
}

function Update-Progress {
    param([string]$Task = "", [string]$Phase = "")

    if (-not (Test-Path $script:ProgressFile)) {
        Write-Log "$script:ProgressFile not found." "WARN"
        return $false
    }

    $content = Get-Content $script:ProgressFile -Raw

    if ($Task) {
        $lines = $content -split "`n"
        $alreadyMarked = $false
        foreach ($line in $lines) {
            if ($line -match '^\s*-\s*\[x\]\s+' -and
                $line -match [regex]::Escape($Task)) {
                $alreadyMarked = $true
                break
            }
        }

        if (-not $alreadyMarked) {
            $taskLine = "- [x] $Task"
            $newLines = @()
            $inserted = $false
            foreach ($line in $lines) {
                if (-not $inserted -and $line -match '^\s*-\s*\[\s\]\s+') {
                    $newLines += $taskLine
                    $inserted = $true
                }
                $newLines += $line
            }
            if (-not $inserted) {
                $newLines += ""
                $newLines += $taskLine
            }
            $content = $newLines -join "`n"
        }
    }

    $content = $content -replace '## Last Updated\r?\n.*',
        "## Last Updated`n$($script:Timestamp)"

    if ($Phase) {
        $content = $content -replace '## Current Phase\r?\n.*',
            "## Current Phase`n$Phase"
    }

    $content | Set-Content $script:ProgressFile -Encoding UTF8
    Write-Log "PROGRESS.md updated." "PASS"
    return $true
}

function Generate-Report {
    param(
        [string]$TaskName,
        [string]$Status = "COMPLETED",
        [string]$ReviewDecision = "",
        [string]$StopReason = "",
        [string]$Phase = ""
    )

    if (-not (Test-Path $script:ReportsDir)) {
        New-Item -ItemType Directory -Path $script:ReportsDir -Force | Out-Null
    }

    $slug = ($TaskName -replace '[^a-zA-Z0-9]','_')
    if ($slug.Length -gt 60) { $slug = $slug.Substring(0, 60) }
    $reportFile = Join-Path $script:ReportsDir "task_${slug}_$($script:Date).md"

    $report = @"
## Task Report: $TaskName

**Date**: $($script:Date)
**Phase**: $(if ($Phase) { $Phase } else { 'Unknown' })
**Status**: $Status

### Review Result
$(if ($ReviewDecision) { "- Decision: $ReviewDecision" } else { "- Not reviewed" })

### Stop Condition
$(if ($StopReason) { $StopReason } else { "None (normal completion)" })

---
*Generated by automation/scripts/checkpoint.ps1*
"@

    $report | Set-Content $reportFile -Encoding UTF8
    Write-Log "Report generated: $reportFile" "PASS"
    return $reportFile
}

function Get-Status {
    $checkpoint = Read-Checkpoint
    if ($checkpoint) {
        Write-Log "=== Current Checkpoint ==="
        Write-Log "Status: $($checkpoint.Status)"
        Write-Log "Current Task: $($checkpoint.current_task)"
        Write-Log "Stop Reason: $($checkpoint.stop_reason)"
        Write-Log "Timestamp: $($checkpoint.timestamp)"
        if ($checkpoint.completed_tasks) {
            Write-Log "Completed Tasks: $($checkpoint.completed_tasks.Count)"
            $checkpoint.completed_tasks | ForEach-Object { Write-Log "  - $_" }
        }
        if ($checkpoint.human_decision_required) {
            Write-Log "HUMAN DECISION REQUIRED: TRUE" "WARN"
        }
        return $checkpoint
    } else {
        Write-Log "No checkpoint found." "WARN"
        return $null
    }
}

# --- Main ---

try {
    switch ($Action.ToLower()) {
        "save" {
            $checkpoint = Read-Checkpoint
            $completedTasks = @()
            if ($checkpoint -and $checkpoint.completed_tasks) {
                $completedTasks = @($checkpoint.completed_tasks)
            }
            $state = @{
                current_sprint           = $Phase
                current_task             = $Task
                task_status              = $Status
                completed_tasks          = $completedTasks
                validation_retries       = 0
                fix_retries              = 0
                review_retries           = 0
                last_review_decision     = ""
                last_validation_result   = ""
                global_retry_count       = 0
                consecutive_failures     = 0
                timestamp                = $script:Timestamp
                stop_reason              = $StopReason
                human_decision_required  = ($Status -eq "HUMAN_DECISION_REQUIRED")
            }
            Save-Checkpoint -State $state
        }
        "load" { Get-Status }
        "update-progress" {
            Update-Progress -Task $Task -Phase $Phase
        }
        "report" {
            Generate-Report -TaskName $Task -Status $Status `
                -ReviewDecision "" -StopReason $StopReason -Phase $Phase
        }
        "status" { Get-Status }
        default {
            Write-Log "Unknown action: $Action" "WARN"
            Write-Log "Available actions: save, load, update-progress, report, status" "WARN"
        }
    }
} catch {
    Write-Log "Checkpoint error: $_" "FAIL"
    exit 1
}
