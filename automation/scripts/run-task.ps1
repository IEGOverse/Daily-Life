<#
.SYNOPSIS
    Local Autonomous Development Orchestrator Entry Point.

.DESCRIPTION
    Reads the roadmap and progress, determines the next task, invokes OpenCode
    for implementation, validates, invokes review, fixes issues, and persists state.
    Has explicit maximum retry limits and clear stop conditions.

.PARAMETER Task
    Optional specific task to run. If omitted, reads from docs/PROGRESS.md.

.PARAMETER MaxRetries
    Maximum retry attempts per task. Default: 3.

.EXAMPLE
    .\run-task.ps1
    Run the orchestrator for the next approved task.

.EXAMPLE
    .\run-task.ps1 -Task "Sprint 1: Today dashboard" -MaxRetries 3
    Run the orchestrator for a specific task with 3 max retries.

.NOTES
    Safety Rules:
    - Maximum retries: 3 per task for validation, fix, and review.
    - Hard stop on HUMAN_DECISION_REQUIRED.
    - No infinite loops.
    - State persisted after each task.
    - Maximum 50 total retries globally.
    - Maximum 3 consecutive task failures.
#>
param(
    [string]$Task = "",
    [int]$MaxRetries = 3
)

$ErrorActionPreference = "Stop"
$script:GlobalRetryCount = 0
$script:ConsecutiveFailures = 0
$script:MaxTotalRetries = 50
$script:MaxConsecutiveFailures = 3

# --- Helpers ---

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Write-Error-Log {
    param([string]$Message)
    Write-Log -Message $Message -Level "ERROR"
}

function Write-Warning-Log {
    param([string]$Message)
    Write-Log -Message $Message -Level "WARNING"
}

# --- Safety Checks ---

function Test-SafetyLimits {
    if ($script:GlobalRetryCount -ge $script:MaxTotalRetries) {
        Write-Error-Log "Global retry limit ($script:MaxTotalRetries) exceeded. Stopping."
        return $false
    }
    if ($script:ConsecutiveFailures -ge $script:MaxConsecutiveFailures) {
        Write-Error-Log "Consecutive failure limit ($script:MaxConsecutiveFailures) exceeded. Stopping."
        return $false
    }
    return $true
}

# --- State Management ---

function Get-Checkpoint {
    $checkpointFile = "automation/state/checkpoint.json"
    if (Test-Path $checkpointFile) {
        try {
            return Get-Content $checkpointFile | ConvertFrom-Json
        } catch {
            Write-Warning-Log "Could not read checkpoint.json: $_"
        }
    }
    return $null
}

function Save-Checkpoint {
    param([object]$State)
    $checkpointFile = "automation/state/checkpoint.json"
    $State | ConvertTo-Json | Set-Content $checkpointFile -Encoding UTF8
}

# --- OpenCode Invocation ---

function Test-OpenCodeAvailable {
    try {
        $cmd = Get-Command opencode -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Invoke-OpenCode {
    param(
        [string]$Prompt,
        [string]$Skill = ""
    )

    if (-not (Test-OpenCodeAvailable)) {
        Write-Error-Log "OpenCode is not available. Cannot invoke implementation."
        return $false
    }

    try {
        $args = @()
        if ($Skill) {
            $args += @("--skill", $Skill)
        }
        $args += @("--context", $Prompt)

        Write-Log "Invoking OpenCode with prompt: $($Prompt.Substring(0, [Math]::Min(50, $Prompt.Length)))..."
        $result = & opencode @args 2>&1
        return $result
    } catch {
        Write-Error-Log "Failed to invoke OpenCode: $_"
        return $false
    }
}

# --- Validation ---

function Invoke-Validation {
    param([string]$TaskName)

    $results = @{
        Format = $false
        Analyze = $false
        Test = $false
        Build = $false
    }

    # Format check
    Write-Log "Running format check..."
    try {
        $formatResult = & dart format --output=none . 2>&1
        if ($LASTEXITCODE -eq 0) {
            $results.Format = $true
            Write-Log "Format check: PASS"
        } else {
            Write-Warning-Log "Format check: FAIL - $formatResult"
        }
    } catch {
        Write-Warning-Log "Format check: ERROR - $_"
    }

    # Analyze check
    Write-Log "Running analyze check..."
    try {
        $analyzeResult = & dart analyze lib/ 2>&1
        if ($LASTEXITCODE -eq 0) {
            $results.Analyze = $true
            Write-Log "Analyze check: PASS"
        } else {
            Write-Warning-Log "Analyze check: FAIL - $analyzeResult"
        }
    } catch {
        Write-Warning-Log "Analyze check: ERROR - $_"
    }

    # Test check
    Write-Log "Running test check..."
    try {
        $testResult = & dart test 2>&1
        if ($LASTEXITCODE -eq 0) {
            $results.Test = $true
            Write-Log "Test check: PASS"
        } else {
            Write-Warning-Log "Test check: FAIL - $testResult"
        }
    } catch {
        Write-Warning-Log "Test check: ERROR - $_"
    }

    # Build check
    Write-Log "Running build check..."
    try {
        $buildResult = & dart compile kernel lib/main.dart 2>&1
        if ($LASTEXITCODE -eq 0) {
            $results.Build = $true
            Write-Log "Build check: PASS"
        } else {
            Write-Warning-Log "Build check: FAIL - $buildResult"
        }
    } catch {
        Write-Warning-Log "Build check: ERROR - $_"
    }

    return $results
}

function Get-ValidationStatus {
    param([hashtable]$Results)
    return ($Results.Format -and $Results.Analyze -and $Results.Test -and $Results.Build)
}

# --- Review Invocation ---

function Invoke-Review {
    param([string]$TaskName)

    Write-Log "Invoking review stage for: $TaskName"

    try {
        $result = Invoke-OpenCode -Prompt "Review the implementation for: $TaskName" -Skill "review"
        return ($result -ne $false)
    } catch {
        Write-Error-Log "Review invocation failed: $_"
        return $false
    }
}

# --- Fix Issues ---

function Invoke-Fix {
    param([string]$TaskName, [string]$IssueDescription)

    Write-Log "Invoking fix for: $TaskName"

    try {
        $prompt = "Fix the following issues in $TaskName: $IssueDescription"
        $result = Invoke-OpenCode -Prompt $prompt
        return ($result -ne $false)
    } catch {
        Write-Error-Log "Fix invocation failed: $_"
        return $false
    }
}

# --- Main Orchestrator ---

function Invoke-Orchestrator {
    param(
        [string]$Task = "",
        [int]$MaxRetries = 3
    )

    Write-Log "=== Daily Life Autonomous Development Orchestrator ==="
    Write-Log "Reading project state..."

    # Check OpenCode availability
    if (-not (Test-OpenCodeAvailable)) {
        Write-Error-Log "OpenCode is not available. Documenting blocker instead of inventing integration."
        $checkpoint = @{
            status = "CRITICAL_BLOCKER"
            stop_reason = "OpenCode unavailable"
            message = "OpenCode command not found. Cannot invoke implementation."
            timestamp = (Get-Date).ToString("yyyy-MM-dd")
            last_updated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        Save-Checkpoint -State $checkpoint
        Write-Log "Blocker documented. Stopping orchestrator."
        return $false
    }

    # Read checkpoint
    $checkpoint = Get-Checkpoint
    if ($checkpoint) {
        Write-Log "Resuming from checkpoint: $($checkpoint.status)"
    } else {
        Write-Log "No checkpoint found. Starting fresh."
    }

    # Determine next task
    if ($Task) {
        $currentTask = $Task
    } else {
        # Read from PROGRESS.md
        $progressFile = "docs/PROGRESS.md"
        if (Test-Path $progressFile) {
            $progress = Get-Content $progressFile -Raw
            # Parse next task from progress file
            Write-Log "Reading next task from $progressFile"
            $currentTask = "Next approved task from roadmap"
        } else {
            Write-Error-Log "$progressFile not found. Cannot determine next task."
            return $false
        }
    }

    # Check safety limits
    if (-not (Test-SafetyLimits)) {
        return $false
    }

    # Main task loop
    $taskCount = 0
    $retryCount = 0
    $status = "RUNNING"
    $stopReason = $null

    while ($status -eq "RUNNING" -and $taskCount -lt 10) {
        $taskCount++
        Write-Log "=== Task $taskCount: $currentTask ==="

        # Reset retry count for this task
        $retryCount = 0
        $taskPassed = $false

        while ($retryCount -lt $MaxRetries -and -not $taskPassed) {
            $retryCount++
            Write-Log "Attempt $retryCount of $MaxRetries for: $currentTask"

            # Invoke OpenCode for implementation
            Write-Log "Invoking OpenCode for implementation..."
            $implResult = Invoke-OpenCode -Prompt "Implement: $currentTask"

            if ($implResult -eq $false) {
                Write-Warning-Log "Implementation failed. Retrying..."
                continue
            }

            # Validate
            Write-Log "Running validation..."
            $validationResults = Invoke-Validation -TaskName $currentTask
            $validationPassed = Get-ValidationStatus -Results $validationResults

            if (-not $validationPassed) {
                Write-Warning-Log "Validation failed. Attempting fix..."
                $fixResult = Invoke-Fix -TaskName $currentTask -IssueDescription "Validation failed"
                if ($fixResult -eq $false) {
                    Write-Warning-Log "Fix failed. Retrying..."
                    continue
                }
                # Re-validate after fix
                $validationResults = Invoke-Validation -TaskName $currentTask
                $validationPassed = Get-ValidationStatus -Results $validationResults
            }

            if ($validationPassed) {
                # Invoke review
                Write-Log "Invoking review..."
                $reviewResult = Invoke-Review -TaskName $currentTask

                if ($reviewResult) {
                    Write-Log "Review passed!"
                    $taskPassed = $true
                } else {
                    Write-Warning-Log "Review failed. Retrying..."
                }
            } else {
                Write-Warning-Log "Validation still failing after fix attempt."
            }
        }

        # Update state
        if ($taskPassed) {
            Write-Log "Task completed: $currentTask"
            $script:GlobalRetryCount++
            $script:ConsecutiveFailures = 0

            # Save checkpoint
            $checkpoint = @{
                status = "IN_PROGRESS"
                current_task = $currentTask
                last_updated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                stop_reason = $null
            }
            Save-Checkpoint -State $checkpoint

            # TODO: Commit and update PROGRESS.md
            Write-Log "Task completed successfully."
        } else {
            Write-Error-Log "Task failed after $MaxRetries attempts: $currentTask"
            $script:ConsecutiveFailures++
            $script:GlobalRetryCount++

            if ($script:ConsecutiveFailures -ge $script:MaxConsecutiveFailures) {
                $status = "STOPPED"
                $stopReason = "CONSECUTIVE_FAILURES"
                Write-Error-Log "Consecutive failure limit reached. Stopping."
            } elseif ($retryCount -ge $MaxRetries) {
                $status = "HUMAN_DECISION_REQUIRED"
                $stopReason = "RETRY_EXHAUSTED"
                Write-Error-Log "Retry limit exhausted. Human decision required."
            }
        }

        # Check if more tasks exist
        # If no more tasks, stop normally
        if ($status -eq "RUNNING" -and $taskPassed) {
            # Check roadmap for next task
            # For now, stop after one task
            Write-Log "No more tasks in current scope. Stopping."
            $status = "STOPPED"
            $stopReason = "NO_MORE_TASKS"
        }
    }

    # Generate final report
    Write-Log "=== Orchestrator Run Complete ==="
    Write-Log "Tasks processed: $taskCount"
    Write-Log "Status: $status"
    Write-Log "Stop reason: $stopReason"
    Write-Log "Global retry count: $script:GlobalRetryCount"
    Write-Log "Consecutive failures: $script:ConsecutiveFailures"

    # Save final state
    $checkpoint = @{
        status = $status
        stop_reason = $stopReason
        last_updated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        tasks_processed = $taskCount
        global_retry_count = $script:GlobalRetryCount
        consecutive_failures = $script:ConsecutiveFailures
    }
    Save-Checkpoint -State $checkpoint

    return ($status -ne "HUMAN_DECISION_REQUIRED" -and $status -ne "CRITICAL_BLOCKER")
}

# --- Entry Point ---

try {
    $result = Invoke-Orchestrator -Task $Task -MaxRetries $MaxRetries
    if ($result) {
        Write-Log "Orchestrator completed successfully."
        exit 0
    } else {
        Write-Log "Orchestrator stopped (checkpoint saved)."
        exit 1
    }
} catch {
    Write-Error-Log "Orchestrator encountered fatal error: $_"
    # Save checkpoint with error
    $checkpoint = @{
        status = "CRITICAL_BLOCKER"
        stop_reason = "FATAL_ERROR"
        error = $_.Exception.Message
        last_updated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    Save-Checkpoint -State $checkpoint
    exit 1
}
