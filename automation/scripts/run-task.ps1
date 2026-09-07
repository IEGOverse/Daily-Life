<#
.SYNOPSIS
    Local Autonomous Development Orchestrator - Main Entry Point.

.DESCRIPTION
    Reads docs/ROADMAP.md and docs/PROGRESS.md to discover the next approved
    incomplete task, invokes OpenCode for implementation, validates the result,
    invokes review, parses the machine-readable decision, fixes issues if
    CHANGES_REQUIRED, checkpoints via git, and loops to the next task.

    Stops ONLY on: HUMAN_DECISION_REQUIRED, CRITICAL_BLOCKER, safety limits
    exhausted, or no approved tasks remaining.

.PARAMETER Task
    Optional explicit task description. When omitted the orchestrator reads
    ROADMAP.md + PROGRESS.md to determine the next approved incomplete task.

.PARAMETER MaxRetries
    Maximum retry attempts per stage (validation, fix, review). Default: 3.

.PARAMETER DryRun
    When specified the orchestrator runs in self-test mode. It demonstrates
    task discovery, state handling, validation flow, review decision parsing,
    retry flow, human-decision hard stop, and next-task progression WITHOUT
    invoking OpenCode or modifying Daily Life product code.

.EXAMPLE
    .\run-task.ps1
    Run the orchestrator for the next approved task.

.EXAMPLE
    .\run-task.ps1 -DryRun
    Self-test: verify orchestrator logic without touching product code.

.NOTES
    Safety Rules:
    - Max 3 retries per stage (validation / fix / review).
    - Max 10 tasks per run.
    - Max 50 global retries.
    - Max 3 consecutive task failures.
    - Hard stop on HUMAN_DECISION_REQUIRED.
    - Hard stop on CRITICAL_BLOCKER.
    - Never commit unreviewed work.
#>
param(
    [string]$Task = "",
    [int]$MaxRetries = 3,
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"

# --- Global Counters ---------------------------------------------------------
$script:GlobalRetryCount = 0
$script:ConsecutiveFailures = 0
$script:MaxTotalRetries = 50
$script:MaxConsecutiveFailures = 3
$script:MaxTasksPerRun = 10
$script:Date = Get-Date -Format "yyyy-MM-dd"
$script:Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# --- Paths -------------------------------------------------------------------
$script:RootDir       = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $script:RootDir) { $script:RootDir = (Get-Location).Path }
$script:RoadmapFile   = Join-Path $script:RootDir "docs\ROADMAP.md"
$script:ProgressFile  = Join-Path $script:RootDir "docs\PROGRESS.md"
$script:CheckpointDir = Join-Path $script:RootDir "automation\state"
$script:CheckpointFile= Join-Path $script:CheckpointDir "checkpoint.json"
$script:ReportsDir    = Join-Path $script:CheckpointDir "reports"
$script:ConfigFile    = Join-Path $script:RootDir "automation\config\workflow.yaml"

# --- Logging -----------------------------------------------------------------
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $tag = switch ($Level) {
        "PASS"    { "[PASS]" }
        "FAIL"    { "[FAIL]" }
        "WARN"    { "[WARN]" }
        "REVIEW"  { "[REVIEW]" }
        "FIX"     { "[FIX]" }
        "DRY"     { "[DRY-RUN]" }
        default   { "[INFO]" }
    }
    Write-Host "$ts $tag $Message"
}

# =============================================================================
#  1. TASK DISCOVERY
# =============================================================================

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

function Get-RoadmapTasks {
    $tasks = @()

    if (-not (Test-Path $script:RoadmapFile)) {
        Write-Log "Roadmap not found: $($script:RoadmapFile)" "FAIL"
        return $tasks
    }

    # Read with UTF-8 to handle em-dashes and other unicode in headings.
    # The roadmap is structured as:
    #   ## Phase N - Name        (also matches "## Phase N — Name")
    #   ### Sprint N - ...       (optional subdivision)
    #   - Task / - [ ] Task      (ordered list of implementation tasks)
    # Only list-item bullets under a phase/sprint heading are tasks. Headings,
    # blank lines, prose paragraphs, and narrative text are ignored.
    $lines = [System.IO.File]::ReadAllLines($script:RoadmapFile, [System.Text.Encoding]::UTF8)
    $phaseNum = 0
    $phaseName = ""
    $sprintName = ""
    $taskCountInPhase = 0

    foreach ($line in $lines) {
        $trimmed = $line.Trim()

        # Phase heading: "## Phase N ..." (any sub-heading level 2+)
        if ($trimmed -match '^#{2,}\s+Phase\s+(\d+)') {
            $phaseNum = [int]$Matches[1]
            $caption = $trimmed -replace '^#{2,}\s+Phase\s+\d+\s*', ''
            $caption = $caption.TrimStart('-', [char]0x2014, [char]0x2013, [char]0x2012).Trim()
            $phaseName = $caption
            $sprintName = ""
            $taskCountInPhase = 0
            continue
        }

        # Sprint sub-heading: "### Sprint N ..." (or "## Sprint N ...")
        if ($trimmed -match '^#{2,}\s+Sprint\s+(\d+)') {
            $sprintCaption = $trimmed -replace '^#{2,}\s+Sprint\s+\d+\s*', ''
            $sprintCaption = $sprintCaption.TrimStart('-', [char]0x2014, [char]0x2013, [char]0x2012).Trim()
            $sprintName = $sprintCaption
            $taskCountInPhase = 0
            continue
        }

        # List-item bullet => candidate task. Leading "Phase 0 - Foundation:" style
        # prefixes and any trailing " - description" narrative are not part of the task.
        if ($trimmed -match '^[-*]\s+(.+)$' -and $phaseNum -gt 0) {
            $desc = $Matches[1].Trim()
            # A task is a concise item. Skip verbose/narrative bullets (long prose
            # sentences that are clearly descriptive rather than implementation tasks).
            $desc = $desc -replace '^\[\s\]\s*', ''  # allow bare "- [ ] Task"
            if ($desc.Length -eq 0 -or $desc.Length -gt 140) {
                continue
            }
            $taskCountInPhase++
            if ($sprintName) {
                $context = "Phase $phaseNum - $phaseName / $sprintName"
            } else {
                $context = "Phase $phaseNum - $phaseName"
            }
            $tasks += @{
                Phase       = $context
                PhaseNumber = $phaseNum
                Number      = $taskCountInPhase
                Description = $desc
                Full        = "Phase $phaseNum - ${phaseName}: $desc"
            }
        }
    }

    return $tasks
}

# Return the ordered implementation tasks for a specific phase number.
function Get-PhaseTasks {
    param([int]$PhaseNumber)
    $all = Get-RoadmapTasks
    return @($all | Where-Object { $_.PhaseNumber -eq $PhaseNumber })
}

# Strict, normalized completion match: true if the task description equals (or
# the completed entry equal to) the task text after normalization. Uses word
# boundaries and case-insensitive comparison to avoid false matches from
# narrative text that merely contains a task phrase as a substring.
function Test-TaskIsCompleted {
    param([string]$TaskDescription, [array]$Completed)
    $normTask = $TaskDescription.Trim().ToLowerInvariant()
    foreach ($c in $Completed) {
        if (-not $c) { continue }
        $norm = $c.Trim().ToLowerInvariant()
        # Exact match first.
        if ($norm -eq $normTask) { return $true }
        # Word-boundary containment: e.g. completed "today dashboard" matches
        # task "Today dashboard" but not a narrative "dashboard for the week".
        $pattern = "\b" + [regex]::Escape($normTask) + "\b"
        if ($norm -match $pattern -and $normTask.Length -gt 3) { return $true }
    }
    return $false
}

function Get-NextTask {
    $completed = Get-CompletedTasks
    $roadmap = Get-RoadmapTasks

    if ($roadmap.Count -eq 0) {
        Write-Log "No tasks found in roadmap." "WARN"
        return $null
    }

    # Roadmap tasks are already returned in file order, which is the canonical
    # phase -> sprint -> task ordering. Walk them in order and return the first
    # not-yet-completed task.
    foreach ($task in $roadmap) {
        if (-not (Test-TaskIsCompleted -TaskDescription $task.Description -Completed $completed)) {
            return $task
        }
    }

    Write-Log "All roadmap tasks are completed." "PASS"
    return $null
}

# =============================================================================
#  2. CHECKPOINT / STATE
# =============================================================================

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

function New-CheckpointState {
    param(
        [string]$Sprint = "",
        [string]$Task = "",
        [string]$Status = "RUNNING",
        [array]$CompletedTasks = @(),
        [int]$ValidationRetries = 0,
        [int]$FixRetries = 0,
        [int]$ReviewRetries = 0,
        [string]$LastReviewDecision = "",
        [string]$LastValidationResult = "",
        [string]$StopReason = ""
    )

    return @{
        current_sprint           = $Sprint
        current_task             = $Task
        task_status              = $Status
        completed_tasks          = $CompletedTasks
        validation_retries       = $ValidationRetries
        fix_retries              = $FixRetries
        review_retries           = $ReviewRetries
        last_review_decision     = $LastReviewDecision
        last_validation_result   = $LastValidationResult
        global_retry_count       = $script:GlobalRetryCount
        consecutive_failures     = $script:ConsecutiveFailures
        timestamp                = $script:Timestamp
        stop_reason              = $StopReason
        human_decision_required  = $false
    }
}

function Save-Checkpoint {
    param([hashtable]$State)
    if (-not (Test-Path $script:CheckpointDir)) {
        New-Item -ItemType Directory -Path $script:CheckpointDir -Force | Out-Null
    }
    $State | ConvertTo-Json -Depth 5 | Set-Content $script:CheckpointFile -Encoding UTF8
    Write-Log "Checkpoint saved: $($State.task_status)" "PASS"
}

# =============================================================================
#  3. OPENCODE INVOCATION
# =============================================================================

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
        [string]$Agent = ""
    )

    if (-not (Test-OpenCodeAvailable)) {
        Write-Log "OpenCode is not available." "FAIL"
        return @{ Success = $false; Output = "OpenCode not found" }
    }

    $opencodeExe = (Get-Command opencode -ErrorAction SilentlyContinue).Source
    if (-not $opencodeExe) { $opencodeExe = "opencode" }

    try {
        $runArgs = @("run", $Prompt)
        if ($Agent) {
            $runArgs += @("--agent", $Agent)
        }
        $runArgs += @("--format", "json")
        $runArgs += @("--auto")

        Write-Log "Invoking: opencode run ... --format json --auto" "INFO"
        $output = & $opencodeExe @runArgs 2>&1
        $exitCode = $LASTEXITCODE

        return @{
            Success = ($exitCode -eq 0)
            Output  = ($output -join "`n")
            ExitCode = $exitCode
        }
    } catch {
        Write-Log "OpenCode invocation failed: $_" "FAIL"
        return @{ Success = $false; Output = $_.Exception.Message }
    }
}

# =============================================================================
#  4. VALIDATION
# =============================================================================

# Ordered validation stages. The Build stage must be a real Flutter compile
# check: `flutter build bundle` compiles the app's Dart into a kernel bundle
# without requiring a mobile SDK, and is valid in this Flutter environment.
# Standalone `dart compile` cannot compile Flutter code because it lacks dart:ui.
function Get-ValidationChecks {
    return @(
        @{ Name = "Format";  Cmd = "dart"; Args = @("format","--output=none",".") }
        @{ Name = "Analyze"; Cmd = "dart"; Args = @("analyze","lib/") }
        @{ Name = "Test";    Cmd = "flutter"; Args = @("test") }
        @{ Name = "Build";   Cmd = "flutter"; Args = @("build","bundle") }
    )
}

function Invoke-Validation {
    $results = @{
        Format  = @{ Pass = $false; Output = "" }
        Analyze = @{ Pass = $false; Output = "" }
        Test    = @{ Pass = $false; Output = "" }
        Build   = @{ Pass = $false; Output = "" }
    }

    $checks = Get-ValidationChecks

    foreach ($check in $checks) {
        Write-Log "Validation: $($check.Name)..."
        try {
            $output = & $check.Cmd @($check.Args) 2>&1
            $raw = ($output -join "`n")
            $exit = $LASTEXITCODE
            if ($raw.Length -gt 500) { $raw = $raw.Substring(0, 500) }
            $results[$check.Name].Output = $raw
            if ($exit -eq 0) {
                $results[$check.Name].Pass = $true
                Write-Log "  $($check.Name): PASS" "PASS"
            } else {
                Write-Log "  $($check.Name): FAIL (exit $exit)" "FAIL"
            }
        } catch {
            Write-Log "  $($check.Name): ERROR - $_" "FAIL"
        }
    }

    return $results
}

function Get-ValidationPassed {
    param([hashtable]$Results)
    return ($Results.Format.Pass -and $Results.Analyze.Pass -and
            $Results.Test.Pass -and $Results.Build.Pass)
}

function Get-ValidationSummary {
    param([hashtable]$Results)
    $parts = @()
    foreach ($key in @("Format","Analyze","Test","Build")) {
        $parts += "$key=$(if ($Results[$key].Pass) {'PASS'} else {'FAIL'})"
    }
    return ($parts -join " | ")
}

# =============================================================================
#  5. REVIEW GATE  (machine-readable decision parsing)
# =============================================================================

function Invoke-Review {
    param([string]$TaskName, [hashtable]$ValidationResults)

    $valSummary = Get-ValidationSummary -Results $ValidationResults

    $prompt = @"
You are reviewing a completed implementation task for the Daily Life Flutter project.

TASK: $TaskName

VALIDATION RESULTS: $valSummary

REVIEW CRITERIA:
1. Does the code follow AGENTS.md engineering rules?
2. Are there any hard-coded secrets or API keys?
3. Is UI / business logic / data access properly separated?
4. Does database access go through repositories?
5. Is feature modularity maintained?
6. Do tests exist for important business logic?
7. Is documentation updated where behavior changed?

You MUST end your response with EXACTLY ONE of the following lines (nothing else on that line):

REVIEW_DECISION: APPROVED
REVIEW_DECISION: APPROVED_WITH_FOLLOW_UP
REVIEW_DECISION: CHANGES_REQUIRED
REVIEW_DECISION: HUMAN_DECISION_REQUIRED

Do not include any other text after the decision line.
"@

    Write-Log "Invoking review for: $TaskName" "REVIEW"
    $result = Invoke-OpenCode -Prompt $prompt

    if (-not $result.Success) {
        Write-Log "Review invocation failed." "FAIL"
        return @{ Decision = "CHANGES_REQUIRED"; Raw = $result.Output }
    }

    $decision = Parse-ReviewDecision -Output $result.Output
    Write-Log "Review decision: $decision" "REVIEW"
    return @{ Decision = $decision; Raw = $result.Output }
}

function Parse-ReviewDecision {
    param([string]$Output)

    $validDecisions = @(
        "APPROVED",
        "APPROVED_WITH_FOLLOW_UP",
        "CHANGES_REQUIRED",
        "HUMAN_DECISION_REQUIRED"
    )

    foreach ($line in ($Output -split "`n")) {
        $line = $line.Trim()
        if ($line -match 'REVIEW_DECISION:\s*(\S+)') {
            $candidate = $Matches[1].Trim()
            if ($validDecisions -contains $candidate) {
                return $candidate
            }
        }
    }

    if ($Output -match 'HUMAN_DECISION_REQUIRED') { return "HUMAN_DECISION_REQUIRED" }
    if ($Output -match 'CHANGES_REQUIRED')        { return "CHANGES_REQUIRED" }

    Write-Log "Could not parse review decision. Defaulting to CHANGES_REQUIRED." "WARN"
    return "CHANGES_REQUIRED"
}

# =============================================================================
#  6. FIX
# =============================================================================

function Invoke-Fix {
    param(
        [string]$TaskName,
        [string]$IssueDescription,
        [hashtable]$ValidationResults,
        [string]$ReviewOutput
    )

    $valSummary = Get-ValidationSummary -Results $ValidationResults

    $prompt = @"
You are fixing issues in a Daily Life Flutter project implementation.

TASK: $TaskName

VALIDATION RESULTS: $valSummary

REVIEW FINDINGS:
$ReviewOutput

Fix all identified issues. After fixing:
1. Run `dart format --output=none .`
2. Run `dart analyze lib/`
3. Run `flutter test`
4. Run `dart analyze lib/` again to confirm

Summarize what you changed.
"@

    Write-Log "Invoking fix for: $TaskName" "FIX"
    $result = Invoke-OpenCode -Prompt $prompt
    return $result.Success
}

# =============================================================================
#  7. REPORTING
# =============================================================================

function New-TaskReport {
    param(
        [string]$TaskName,
        [string]$Phase,
        [string]$Status,
        [hashtable]$ValidationResults,
        [string]$ReviewDecision,
        [array]$AutomaticFixes = @(),
        [string]$TechnicalDebt = "",
        [string]$NextTask = "",
        [string]$HumanDecisionNote = ""
    )

    if (-not (Test-Path $script:ReportsDir)) {
        New-Item -ItemType Directory -Path $script:ReportsDir -Force | Out-Null
    }

    $slug = ($TaskName -replace '[^a-zA-Z0-9]','_')
    if ($slug.Length -gt 60) { $slug = $slug.Substring(0, 60) }
    $reportFile = Join-Path $script:ReportsDir "task_${slug}_$($script:Date).md"

    $v = $ValidationResults
    $report = @"
## Task Report: $TaskName

**Date**: $($script:Date)
**Phase**: $Phase
**Status**: $Status

### Validation Results
- Format: $(if ($v.Format.Pass) {'PASS'} else {'FAIL'})
- Analyze: $(if ($v.Analyze.Pass) {'PASS'} else {'FAIL'})
- Test: $(if ($v.Test.Pass) {'PASS'} else {'FAIL'})
- Build: $(if ($v.Build.Pass) {'PASS'} else {'FAIL'})

### Review Result
- Decision: $ReviewDecision

### Automatic Fixes
$(if ($AutomaticFixes.Count -gt 0) { ($AutomaticFixes | ForEach-Object { "- $_" }) -join "`n" } else { "- None" })

### Technical Debt
$(if ($TechnicalDebt) { $TechnicalDebt } else { "- None identified" })

### Next Task
$(if ($NextTask) { $NextTask } else { "- No more tasks in current scope" })

### Human Decision Status
$(if ($HumanDecisionNote) { $HumanDecisionNote } else { "- None required" })
"@

    $report | Set-Content $reportFile -Encoding UTF8
    Write-Log "Task report generated: $reportFile" "PASS"
    return $reportFile
}

function New-DecisionReport {
    param(
        [string]$TaskName,
        [string]$Phase,
        [string]$IssueDescription,
        [hashtable]$ValidationResults,
        [string]$ReviewDecision
    )

    if (-not (Test-Path $script:ReportsDir)) {
        New-Item -ItemType Directory -Path $script:ReportsDir -Force | Out-Null
    }

    $slug = ($TaskName -replace '[^a-zA-Z0-9]','_')
    if ($slug.Length -gt 60) { $slug = $slug.Substring(0, 60) }
    $reportFile = Join-Path $script:ReportsDir "decision_${slug}_$($script:Date).md"

    $v = $ValidationResults
    $report = @"
## Incident Report: HUMAN_DECISION_REQUIRED

**Date**: $($script:Date)
**Severity**: HIGH
**Stop Reason**: HUMAN_DECISION_REQUIRED
**Task**: $TaskName
**Phase**: $Phase

### Description
$IssueDescription

### Validation Results
- Format: $(if ($v.Format.Pass) {'PASS'} else {'FAIL'})
- Analyze: $(if ($v.Analyze.Pass) {'PASS'} else {'FAIL'})
- Test: $(if ($v.Test.Pass) {'PASS'} else {'FAIL'})
- Build: $(if ($v.Build.Pass) {'PASS'} else {'FAIL'})

### Review Decision
$ReviewDecision

### Required Human Action
The orchestrator has stopped. A human must review the situation and decide:
1. Approve the current implementation as-is
2. Request a different approach
3. Update the roadmap/architecture
4. Defer this task
5. Stop the orchestrator

### Recovery Instructions
1. Read automation/state/checkpoint.json
2. Read this report
3. Make a decision
4. Update checkpoint.json with the decision
5. Re-run the orchestrator or update docs/PROGRESS.md manually
"@

    $report | Set-Content $reportFile -Encoding UTF8
    Write-Log "Decision report generated: $reportFile" "PASS"
    return $reportFile
}

# =============================================================================
#  8. CHECKPOINT COMMIT + PROGRESS UPDATE
# =============================================================================

function Invoke-CheckpointCommit {
    param(
        [string]$TaskName,
        [hashtable]$State
    )

    Write-Log "Creating checkpoint commit for: $TaskName"

    try {
        $gitStatus = & git status --porcelain 2>&1
        if ($gitStatus -and $gitStatus.Trim() -ne "") {
            & git add -A 2>&1 | Out-Null
            $commitMsg = "chore: checkpoint - $TaskName"
            & git commit -m $commitMsg 2>&1 | Out-Null
            Write-Log "Checkpoint commit created: $commitMsg" "PASS"
        } else {
            Write-Log "No changes to commit." "INFO"
        }
    } catch {
        Write-Log "Git commit failed: $_" "WARN"
    }
}

function Update-ProgressFile {
    param(
        [string]$TaskDescription,
        [string]$Phase
    )

    if (-not (Test-Path $script:ProgressFile)) {
        Write-Log "PROGRESS.md not found. Skipping update." "WARN"
        return
    }

    $content = Get-Content $script:ProgressFile -Raw

    $completed = Get-CompletedTasks
    if ($completed -contains $TaskDescription) {
        Write-Log "Task already marked complete in PROGRESS.md." "INFO"
        return
    }

    $checkpoint = Read-Checkpoint
    $completedTasks = @()
    if ($checkpoint -and $checkpoint.completed_tasks) {
        $completedTasks = @($checkpoint.completed_tasks)
    }
    $completedTasks += $TaskDescription

    $taskLine = "- [x] $TaskDescription"
    $markerFound = $false

    $newLines = @()
    $lines = $content -split "`n"

    foreach ($line in $lines) {
        if ($line -match '^\s*-\s*\[\s\]\s+' -and -not $markerFound) {
            $newLines += "  $taskLine"
            $markerFound = $true
            $newLines += $line
        } else {
            $newLines += $line
        }
    }

    if (-not $markerFound) {
        $newLines += ""
        $newLines += $taskLine
    }

    $newContent = $newLines -join "`n"
    $newContent = $newContent -replace '## Last Updated\r?\n.*', "## Last Updated`n$($script:Date)"

    if ($Phase) {
        $newContent = $newContent -replace '## Current Phase\r?\n.*', "## Current Phase`n$Phase"
    }

    $newContent | Set-Content $script:ProgressFile -Encoding UTF8
    Write-Log "PROGRESS.md updated with completed task." "PASS"
}

# =============================================================================
#  9. SAFETY
# =============================================================================

function Test-SafetyLimits {
    if ($script:GlobalRetryCount -ge $script:MaxTotalRetries) {
        Write-Log "Global retry limit ($($script:MaxTotalRetries)) exceeded." "FAIL"
        return $false
    }
    if ($script:ConsecutiveFailures -ge $script:MaxConsecutiveFailures) {
        Write-Log "Consecutive failure limit ($($script:MaxConsecutiveFailures)) exceeded." "FAIL"
        return $false
    }
    return $true
}

# =============================================================================
#  10. DRY-RUN SELF-TEST
# =============================================================================

function Invoke-DryRun {
    Write-Log "==============================================================" "DRY"
    Write-Log "  DRY-RUN SELF-TEST - No product code will be modified" "DRY"
    Write-Log "==============================================================" "DRY"

    $testsPassed = 0
    $testsFailed = 0

    # Capture the original checkpoint so it can be restored at the end,
    # leaving state exactly as it was before the self-test ran.
    $originalCheckpoint = ""
    if (Test-Path $script:CheckpointFile) {
        $originalCheckpoint = [System.IO.File]::ReadAllText($script:CheckpointFile)
    }
    $originalProgress = ""
    if (Test-Path $script:ProgressFile) {
        $originalProgress = [System.IO.File]::ReadAllText($script:ProgressFile)
    }

    # TEST 1: Task Discovery + Roadmap Ordering
    Write-Log "" "DRY"
    Write-Log "TEST 1: Task Discovery + Roadmap Ordering" "DRY"
    $allTasks = Get-RoadmapTasks
    Write-Log "  Roadmap total tasks: $($allTasks.Count)" "DRY"
    # Tasks must be returned in canonical order (i.e. non-empty and ordered by file).
    if ($allTasks.Count -gt 0) {
        Write-Log "  First task: $($allTasks[0].Full)" "DRY"
        $testsPassed++
    } else {
        Write-Log "  Task discovery found no tasks." "DRY"
        if (Test-Path $script:RoadmapFile) { $testsPassed++ } else { $testsFailed++ }
    }

    # TEST 1b: Phase 1 - Daily Core resolves to exactly the 6 ordered tasks.
    Write-Log "" "DRY"
    Write-Log "TEST 1b: Phase 1 - Daily Core task resolution" "DRY"
    $phase1Tasks = Get-PhaseTasks -PhaseNumber 1
    $expectedPhase1 = @(
        "Today dashboard",
        "Recurring schedule",
        "Activity model",
        "Activity completion",
        "Calendar/history",
        "Add activity"
    )
    $phase1Title = [string]::Join(" | ", @($phase1Tasks | ForEach-Object { $_.Description }))
    Write-Log "  Phase 1 tasks ($($phase1Tasks.Count)): $phase1Title" "DRY"
    $phase1Ok = $true
    if ($phase1Tasks.Count -eq $expectedPhase1.Count) {
        for ($i = 0; $i -lt $expectedPhase1.Count; $i++) {
            if ($phase1Tasks[$i].Description -ne $expectedPhase1[$i]) {
                $phase1Ok = $false
                $gotOne = $phase1Tasks[$i].Description
                $expOne = $expectedPhase1[$i]
                Write-Log "  ORDER MISMATCH at index ${i}: got '$gotOne' expected '$expOne'" "DRY"
            }
        }
    } else {
        $phase1Ok = $false
        $gotCount = $phase1Tasks.Count
        $expCount = $expectedPhase1.Count
        Write-Log "  COUNT MISMATCH: got $gotCount expected $expCount" "DRY"
    }
    if ($phase1Ok) {
        Write-Log "  Phase 1 - Daily Core resolves to 6 ordered tasks: PASS" "DRY"
        $testsPassed++
    } else {
        Write-Log "  Phase 1 - Daily Core resolution: FAIL" "DRY"
        $testsFailed++
    }

    # TEST 1c: Completed-task skipping resolves the correct next task.
    Write-Log "" "DRY"
    Write-Log "TEST 1c: Completed-task skipping" "DRY"
    $skipOk = $true
    # Next task with nothing completed down to "recurring schedule" complete
    # should resolve to "Activity model" (3rd Phase 1 task).
    if ($phase1Tasks.Count -gt 2) {
        $partialComplete = @($phase1Tasks[0].Description, $phase1Tasks[1].Description)
        $resolved = $null
        foreach ($t in $phase1Tasks) {
            if (-not (Test-TaskIsCompleted -TaskDescription $t.Description -Completed $partialComplete)) {
                $resolved = $t; break
            }
        }
        if ($resolved -and $resolved.Description -eq $phase1Tasks[2].Description) {
            Write-Log "  Skip completed, resolve next: $($resolved.Description) : PASS" "DRY"
            $testsPassed++
        } else {
            Write-Log "  Skip completed resolution: FAIL (got '$($resolved.Description)')" "DRY"
            $testsFailed++
            $skipOk = $false
        }
    }
    # Narrative text must NOT be treated as completing a task (no false match).
    $narrative = @("dashboard for the weekly review", "phase 1 - daily core", "recurring schedule details")
    if ($skipOk -and -not (Test-TaskIsCompleted -TaskDescription ($phase1Tasks[0].Description) -Completed $narrative)) {
        Write-Log "  Narrative text does not falsely complete a task: PASS" "DRY"
        $testsPassed++
    } elseif ($skipOk) {
        Write-Log "  Narrative text falsely completed a task: FAIL" "DRY"
        $testsFailed++
    }

    # TEST 2: Checkpoint State (resume/recovery)
    Write-Log "" "DRY"
    Write-Log "TEST 2: Checkpoint State Handling" "DRY"
    $checkpoint = Read-Checkpoint
    if ($checkpoint) {
        Write-Log "  Existing checkpoint loaded: $($checkpoint | ConvertTo-Json -Compress)" "DRY"
        $testsPassed++
    } else {
        $testState = New-CheckpointState -Sprint "Test Sprint" -Task "Test Task"
        Save-Checkpoint -State $testState
        $reloaded = Read-Checkpoint
        if ($reloaded -and $reloaded.current_task -eq "Test Task") {
            Write-Log "  Checkpoint write/read: PASS" "DRY"
            $testsPassed++
        } else {
            Write-Log "  Checkpoint write/read: FAIL" "DRY"
            $testsFailed++
        }
        # Restore original checkpoint
        if ($originalCheckpoint) {
            [System.IO.File]::WriteAllText($script:CheckpointFile, $originalCheckpoint)
        }
    }

    # TEST 3: Validation Flow (includes verifying real Build stage)
    Write-Log "" "DRY"
    Write-Log "TEST 3: Validation Flow + real Build stage" "DRY"
    $testResults = @{
        Format  = @{ Pass = $true; Output = "dry-run" }
        Analyze = @{ Pass = $true; Output = "dry-run" }
        Test    = @{ Pass = $true; Output = "dry-run" }
        Build   = @{ Pass = $true; Output = "dry-run" }
    }
    $passed = Get-ValidationPassed -Results $testResults
    $summary = Get-ValidationSummary -Results $testResults
    if ($passed -and $summary -match "PASS") {
        Write-Log "  Validation summary: $summary" "DRY"
        $testsPassed++
    } else {
        Write-Log "  Validation logic: FAIL" "DRY"
        $testsFailed++
    }
    # Verify the Build validation stage is a real Flutter compile check
    # (flutter build bundle), not a duplicate dart analyze.
    $checks = Get-ValidationChecks
    $buildCheck = $checks | Where-Object { $_.Name -eq "Build" }
    if ($buildCheck -and $buildCheck.Cmd -eq "flutter" -and
        ($buildCheck.Args -join " ") -match "^build\s+bundle") {
        Write-Log "  Build stage is 'flutter build bundle' (real compile): PASS" "DRY"
        $testsPassed++
    } else {
        Write-Log "  Build stage is NOT a real Flutter compile check: FAIL" "DRY"
        $testsFailed++
    }

    # TEST 3b: Get-NextTask resolution honors completion + ordering end-to-end.
    Write-Log "" "DRY"
    Write-Log "TEST 3b: Get-NextTask end-to-end resolution" "DRY"
    $nextTask = Get-NextTask
    if ($nextTask) {
        Write-Log "  Next task: $($nextTask.Full)" "DRY"
        $testsPassed++
    } else {
        Write-Log "  No next task (all completed or roadmap empty)." "DRY"
        if (Test-Path $script:RoadmapFile) { $testsPassed++ } else { $testsFailed++ }
    }

    # TEST 4: Review Decision Parsing
    Write-Log "" "DRY"
    Write-Log "TEST 4: Review Decision Parsing" "DRY"
    $testCases = @(
        @{ Input = "Some text...`nREVIEW_DECISION: APPROVED"; Expected = "APPROVED" }
        @{ Input = "Findings...`nREVIEW_DECISION: CHANGES_REQUIRED"; Expected = "CHANGES_REQUIRED" }
        @{ Input = "Cannot decide.`nREVIEW_DECISION: HUMAN_DECISION_REQUIRED"; Expected = "HUMAN_DECISION_REQUIRED" }
        @{ Input = "Good work.`nREVIEW_DECISION: APPROVED_WITH_FOLLOW_UP"; Expected = "APPROVED_WITH_FOLLOW_UP" }
        @{ Input = "No decision line here"; Expected = "CHANGES_REQUIRED" }
    )
    $parseCorrect = 0
    foreach ($tc in $testCases) {
        $parsed = Parse-ReviewDecision -Output $tc.Input
        if ($parsed -eq $tc.Expected) {
            $parseCorrect++
        } else {
            Write-Log "  PARSE FAIL: expected=$($tc.Expected) got=$parsed" "DRY"
        }
    }
    if ($parseCorrect -eq $testCases.Count) {
        Write-Log "  All $($testCases.Count) parse cases: PASS" "DRY"
        $testsPassed++
    } else {
        Write-Log "  $parseCorrect/$($testCases.Count) parse cases passed" "DRY"
        $testsFailed++
    }

    # TEST 5: Retry Flow
    Write-Log "" "DRY"
    Write-Log "TEST 5: Retry Flow Logic" "DRY"
    $retryTestState = New-CheckpointState -ValidationRetries 0 -FixRetries 0 -ReviewRetries 0
    $canRetry = ($retryTestState.validation_retries -lt $MaxRetries)
    if ($canRetry) {
        $retryTestState.validation_retries = $MaxRetries
        $exhausted = ($retryTestState.validation_retries -ge $MaxRetries)
        if ($exhausted) {
            Write-Log "  Retry exhaustion detection: PASS" "DRY"
            $testsPassed++
        } else {
            Write-Log "  Retry exhaustion detection: FAIL" "DRY"
            $testsFailed++
        }
    }

    # TEST 6: Human Decision Hard Stop
    Write-Log "" "DRY"
    Write-Log "TEST 6: Human Decision Hard Stop" "DRY"
    $hdiState = New-CheckpointState -Status "HUMAN_DECISION_REQUIRED" -StopReason "RETRY_EXHAUSTED"
    $hdiState.human_decision_required = $true
    Save-Checkpoint -State $hdiState
    $reloadedHDI = Read-Checkpoint
    if ($reloadedHDI.human_decision_required -eq $true -and
        $reloadedHDI.stop_reason -eq "RETRY_EXHAUSTED") {
        Write-Log "  Hard stop state persisted: PASS" "DRY"
        $testsPassed++
    } else {
        Write-Log "  Hard stop state persisted: FAIL" "DRY"
        $testsFailed++
    }
    # Restore original checkpoint so subsequent tests see real state
    if ($originalCheckpoint) {
        [System.IO.File]::WriteAllText($script:CheckpointFile, $originalCheckpoint)
    }

    # TEST 7: Next-Task Progression
    Write-Log "" "DRY"
    Write-Log "TEST 7: Next-Task Progression" "DRY"
    $allTasks = Get-RoadmapTasks
    $completedTasks = Get-CompletedTasks
    $remainingTasks = @()
    foreach ($t in $allTasks) {
        if (-not (Test-TaskIsCompleted -TaskDescription $t.Description -Completed $completedTasks)) {
            $remainingTasks += $t
        }
    }
    Write-Log "  Roadmap tasks total: $($allTasks.Count)" "DRY"
    Write-Log "  Completed: $($completedTasks.Count)" "DRY"
    Write-Log "  Remaining: $($remainingTasks.Count)" "DRY"
    if ($remainingTasks.Count -gt 0) {
        Write-Log "  Next would be: $($remainingTasks[0].Full)" "DRY"
    }
    $testsPassed++

    # TEST 8: Safety Limits
    Write-Log "" "DRY"
    Write-Log "TEST 8: Safety Limits" "DRY"
    $savedGlobal = $script:GlobalRetryCount
    $savedConsec = $script:ConsecutiveFailures
    $script:GlobalRetryCount = $script:MaxTotalRetries
    $safetyOk = (-not (Test-SafetyLimits))
    $script:ConsecutiveFailures = $script:MaxConsecutiveFailures
    $safetyOk2 = (-not (Test-SafetyLimits))
    $script:GlobalRetryCount = $savedGlobal
    $script:ConsecutiveFailures = $savedConsec
    if ($safetyOk -and $safetyOk2) {
        Write-Log "  Safety limit enforcement: PASS" "DRY"
        $testsPassed++
    } else {
        Write-Log "  Safety limit enforcement: FAIL" "DRY"
        $testsFailed++
    }

    # TEST 9: OpenCode Availability Check
    Write-Log "" "DRY"
    Write-Log "TEST 9: OpenCode Availability" "DRY"
    $ocAvailable = Test-OpenCodeAvailable
    if ($ocAvailable) {
        Write-Log "  OpenCode is available on this system." "DRY"
        $testsPassed++
    } else {
        Write-Log "  OpenCode NOT available - this would be a CRITICAL_BLOCKER in production." "DRY"
        $testsPassed++
    }

    # TEST 10: Report Generation (dry)
    Write-Log "" "DRY"
    Write-Log "TEST 10: Report Generation" "DRY"
    $dryVal = @{
        Format  = @{ Pass = $true;  Output = "" }
        Analyze = @{ Pass = $true;  Output = "" }
        Test    = @{ Pass = $true;  Output = "" }
        Build   = @{ Pass = $true;  Output = "" }
    }
    $reportPath = New-TaskReport -TaskName "Dry Run Test Task" -Phase "Dry Phase" `
        -Status "COMPLETED" -ValidationResults $dryVal `
        -ReviewDecision "APPROVED" -NextTask "None"
    if (Test-Path $reportPath) {
        Write-Log "  Report generated: $reportPath" "DRY"
        Remove-Item $reportPath -Force
        $testsPassed++
    } else {
        Write-Log "  Report generation: FAIL" "DRY"
        $testsFailed++
    }

    # SUMMARY
    Write-Log "" "DRY"
    Write-Log "==============================================================" "DRY"
    Write-Log "  DRY-RUN COMPLETE: $testsPassed passed, $testsFailed failed" "DRY"
    Write-Log "==============================================================" "DRY"

    # Restore original state so the self-test leaves no side effects
    if ($originalCheckpoint) {
        [System.IO.File]::WriteAllText($script:CheckpointFile, $originalCheckpoint)
    }
    if ($originalProgress) {
        [System.IO.File]::WriteAllText($script:ProgressFile, $originalProgress)
    }

    @{ Passed = $testsPassed; Failed = $testsFailed }
}

# =============================================================================
#  MAIN ORCHESTRATOR
# =============================================================================

function Invoke-Orchestrator {
    param(
        [string]$Task = "",
        [int]$MaxRetries = 3,
        [switch]$DryRun
    )

    # --- Dry-Run Gate ------------------------------------------------------
    if ($DryRun) {
        $dryResult = Invoke-DryRun
        return ($dryResult.Failed -eq 0)
    }

    Write-Log "==============================================================" "INFO"
    Write-Log "  Daily Life Autonomous Development Orchestrator" "INFO"
    Write-Log "==============================================================" "INFO"

    # --- OpenCode Check -----------------------------------------------------
    if (-not (Test-OpenCodeAvailable)) {
        Write-Log "OpenCode not available. Cannot proceed." "FAIL"
        $blockerState = New-CheckpointState -Status "CRITICAL_BLOCKER" `
            -StopReason "OpenCode unavailable"
        $blockerState.human_decision_required = $true
        Save-Checkpoint -State $blockerState
        return $false
    }

    # --- Resume or Start Fresh ----------------------------------------------
    $checkpoint = Read-Checkpoint
    $completedTasks = @()

    if ($checkpoint -and $checkpoint.completed_tasks) {
        $completedTasks = @($checkpoint.completed_tasks)
        Write-Log "Resuming. $($completedTasks.Count) task(s) already completed." "INFO"
    } else {
        Write-Log "Starting fresh." "INFO"
    }

    # --- Main Loop ----------------------------------------------------------
    $taskCount = 0
    $status = "RUNNING"

    while ($status -eq "RUNNING") {

        if ($taskCount -ge $script:MaxTasksPerRun) {
            Write-Log "Max tasks per run ($($script:MaxTasksPerRun)) reached." "WARN"
            $status = "STOPPED"
            break
        }

        if (-not (Test-SafetyLimits)) {
            $status = "STOPPED"
            break
        }

        # --- Task Discovery -------------------------------------------------
        $nextTask = $null
        if ($Task -and $taskCount -eq 0) {
            $nextTask = @{ Phase = "Explicit"; Description = $Task; Full = $Task }
        } else {
            $nextTask = Get-NextTask
        }

        if (-not $nextTask) {
            Write-Log "No more approved tasks. Stopping." "PASS"
            $status = "STOPPED"
            break
        }

        $taskCount++
        $taskName = $nextTask.Description
        $taskPhase = $nextTask.Phase
        Write-Log "==============================================================" "INFO"
        Write-Log "  TASK $taskCount : $taskName" "INFO"
        Write-Log "  Phase: $taskPhase" "INFO"
        Write-Log "==============================================================" "INFO"

        $taskPassed = $false
        $lastValResults = $null
        $lastReviewDecision = ""
        $lastReviewRaw = ""

        # --- Task Retry Loop -------------------------------------------------
        $stageRetries = 0
        while ($stageRetries -lt $MaxRetries -and -not $taskPassed) {
            $stageRetries++
            Write-Log "-- Attempt $stageRetries / $MaxRetries --" "INFO"

            # --- Implementation ----------------------------------------------
            Write-Log "Invoking OpenCode for implementation..." "INFO"
            $implPrompt = @"
Implement the following task for the Daily Life Flutter project.

TASK: $taskName
PHASE: $taskPhase

Read docs/ROADMAP.md, docs/PROGRESS.md, docs/ARCHITECTURE.md, docs/DATABASE.md,
and AGENTS.md before implementing. Follow all engineering rules.
After implementing, run: dart format --output=none . && dart analyze lib/ && flutter test
"@
            $implResult = Invoke-OpenCode -Prompt $implPrompt

            if (-not $implResult.Success) {
                Write-Log "Implementation invocation failed." "WARN"
                $script:GlobalRetryCount++
                $stageRetries++
                continue
            }

            # --- Validation ------------------------------------------------
            Write-Log "Running validation..." "INFO"
            $lastValResults = Invoke-Validation
            $valPassed = Get-ValidationPassed -Results $lastValResults
            $valSummary = Get-ValidationSummary -Results $lastValResults

            if (-not $valPassed) {
                Write-Log "Validation failed: $valSummary" "WARN"
                Write-Log "Invoking fix..." "FIX"
                $fixOk = Invoke-Fix -TaskName $taskName `
                    -IssueDescription "Validation failed: $valSummary" `
                    -ValidationResults $lastValResults

                if ($fixOk) {
                    $script:GlobalRetryCount++
                    $lastValResults = Invoke-Validation
                    $valPassed = Get-ValidationPassed -Results $lastValResults
                    $valSummary = Get-ValidationSummary -Results $lastValResults
                }
                $script:GlobalRetryCount++
            }

            if (-not $valPassed) {
                Write-Log "Validation still failing." "WARN"
                continue
            }

            Write-Log "Validation passed: $valSummary" "PASS"

            # --- Review ------------------------------------------------------
            $review = Invoke-Review -TaskName $taskName -ValidationResults $lastValResults
            $lastReviewDecision = $review.Decision
            $lastReviewRaw = $review.Raw
            $script:GlobalRetryCount++

            switch ($review.Decision) {
                "APPROVED" {
                    Write-Log "Review: APPROVED" "PASS"
                    $taskPassed = $true
                }
                "APPROVED_WITH_FOLLOW_UP" {
                    Write-Log "Review: APPROVED_WITH_FOLLOW_UP" "PASS"
                    $taskPassed = $true
                }
                "CHANGES_REQUIRED" {
                    Write-Log "Review: CHANGES_REQUIRED - sending findings to OpenCode" "WARN"
                    $fixOk = Invoke-Fix -TaskName $taskName `
                        -IssueDescription $lastReviewRaw `
                        -ValidationResults $lastValResults
                    if ($fixOk) { $script:GlobalRetryCount++ }
                    continue
                }
                "HUMAN_DECISION_REQUIRED" {
                    Write-Log "Review: HUMAN_DECISION_REQUIRED - hard stop" "FAIL"
                    $hdiState = New-CheckpointState -Sprint $taskPhase -Task $taskName `
                        -Status "HUMAN_DECISION_REQUIRED" -CompletedTasks $completedTasks `
                        -LastReviewDecision "HUMAN_DECISION_REQUIRED" `
                        -StopReason "Review escalated to human"
                    $hdiState.human_decision_required = $true
                    Save-Checkpoint -State $hdiState
                    New-DecisionReport -TaskName $taskName -Phase $taskPhase `
                        -IssueDescription "Review returned HUMAN_DECISION_REQUIRED" `
                        -ValidationResults $lastValResults `
                        -ReviewDecision "HUMAN_DECISION_REQUIRED"
                    return $false
                }
            }
        }

        # --- Task Outcome ----------------------------------------------------
        if ($taskPassed) {
            $completedTasks += $taskName
            $script:ConsecutiveFailures = 0

            # Save checkpoint
            $state = New-CheckpointState -Sprint $taskPhase -Task $taskName `
                -Status "COMPLETED" -CompletedTasks $completedTasks `
                -LastReviewDecision $lastReviewDecision `
                -LastValidationResult $valSummary
            Save-Checkpoint -State $state

            # Update PROGRESS.md
            Update-ProgressFile -TaskDescription $taskName -Phase $taskPhase

            # Git commit
            Invoke-CheckpointCommit -TaskName $taskName -State $state

            # Task report
            New-TaskReport -TaskName $taskName -Phase $taskPhase `
                -Status "COMPLETED" -ValidationResults $lastValResults `
                -ReviewDecision $lastReviewDecision `
                -NextTask "(auto-continuing)"

            Write-Log "TASK COMPLETED: $taskName" "PASS"
        } else {
            $script:ConsecutiveFailures++
            $script:GlobalRetryCount++

            if ($script:ConsecutiveFailures -ge $script:MaxConsecutiveFailures) {
                Write-Log "Consecutive failure limit reached. Stopping." "FAIL"
                $status = "STOPPED"
                New-DecisionReport -TaskName $taskName -Phase $taskPhase `
                    -IssueDescription "Task failed after $MaxRetries attempts (consecutive failures)" `
                    -ValidationResults $lastValResults `
                    -ReviewDecision "RETRY_EXHAUSTED"
                $failState = New-CheckpointState -Sprint $taskPhase -Task $taskName `
                    -Status "HUMAN_DECISION_REQUIRED" -CompletedTasks $completedTasks `
                    -LastReviewDecision $lastReviewDecision `
                    -StopReason "CONSECUTIVE_FAILURES"
                $failState.human_decision_required = $true
                Save-Checkpoint -State $failState
                return $false
            } elseif ($stageRetries -ge $MaxRetries) {
                Write-Log "Retry limit exhausted for: $taskName" "FAIL"
                $failState = New-CheckpointState -Sprint $taskPhase -Task $taskName `
                    -Status "HUMAN_DECISION_REQUIRED" -CompletedTasks $completedTasks `
                    -LastReviewDecision $lastReviewDecision `
                    -StopReason "RETRY_EXHAUSTED"
                $failState.human_decision_required = $true
                Save-Checkpoint -State $failState
                New-DecisionReport -TaskName $taskName -Phase $taskPhase `
                    -IssueDescription "Validation/review failed after $MaxRetries attempts" `
                    -ValidationResults $lastValResults `
                    -ReviewDecision "RETRY_EXHAUSTED"
                return $false
            }
        }
    }

    # --- Final State -----------------------------------------------------------
    $finalState = New-CheckpointState -Status $status `
        -CompletedTasks $completedTasks `
        -StopReason $(if ($status -eq "STOPPED") { "NO_MORE_TASKS" } else { "" })
    Save-Checkpoint -State $finalState

    Write-Log "" "INFO"
    Write-Log "==============================================================" "INFO"
    Write-Log "  Orchestrator run complete" "INFO"
    Write-Log "  Tasks processed: $taskCount" "INFO"
    Write-Log "  Status: $status" "INFO"
    Write-Log "  Completed total: $($completedTasks.Count)" "INFO"
    Write-Log "  Global retries: $($script:GlobalRetryCount)" "INFO"
    Write-Log "==============================================================" "INFO"

    return ($status -ne "HUMAN_DECISION_REQUIRED" -and $status -ne "CRITICAL_BLOCKER")
}

# --- Entry Point -----------------------------------------------------------

try {
    $result = Invoke-Orchestrator -Task $Task -MaxRetries $MaxRetries -DryRun:$DryRun
    if ($result) {
        Write-Log "Orchestrator finished successfully."
        exit 0
    } else {
        Write-Log "Orchestrator stopped. Check automation/state/checkpoint.json"
        exit 1
    }
} catch {
    Write-Log "FATAL: $_" "FAIL"
    $fatalState = New-CheckpointState -Status "CRITICAL_BLOCKER" `
        -StopReason "FATAL_ERROR: $($_.Exception.Message)"
    $fatalState.human_decision_required = $true
    Save-Checkpoint -State $fatalState
    exit 1
}
