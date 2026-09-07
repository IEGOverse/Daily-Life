# Daily Life — Reporting

## Purpose

This document defines how the local autonomous development orchestrator generates development reports. Reports capture the state of the project, progress made, issues encountered, and next steps.

## Report Types

### 1. Task Report
Generated after each task is completed.

```markdown
## Task Report: <Task Name>

**Date**: <YYYY-MM-DD>
**Phase**: <Phase Name>
**Sprint**: <Sprint Name>
**Status**: COMPLETED | PARTIAL | FAILED

### Changes Made
- <list of files changed>

### Validation Results
- Format: PASS/FAIL
- Analyze: PASS/FAIL
- Test: PASS/FAIL
- Build: PASS/FAIL
- Review: PASS/FAIL

### Issues
- <list of issues found, if any>

### Notes
- <additional context>
```

### 2. Sprint Report
Generated after all tasks in a sprint are completed.

```markdown
## Sprint Report: <Sprint Name>

**Phase**: <Phase Name>
**Start Date**: <YYYY-MM-DD>
**End Date**: <YYYY-MM-DD>
**Status**: COMPLETED | IN_PROGRESS | BLOCKED

### Tasks Completed
- [x] <task 1>
- [x] <task 2>

### Tasks Remaining
- [ ] <task 3>

### Validation Summary
- Total tasks: <n>
- Passed: <n>
- Failed: <n>
- Retries: <n>

### Issues Encountered
- <list of issues>

### Next Sprint
- <next sprint name and tasks>
```

### 3. Phase Report
Generated after all sprints in a phase are completed.

```markdown
## Phase Report: <Phase Name>

**Status**: COMPLETED | IN_PROGRESS | BLOCKED

### Sprints
- <sprint 1>: COMPLETED
- <sprint 2>: COMPLETED

### Metrics
- Total tasks completed: <n>
- Total retries: <n>
- Total human interventions: <n>

### Documentation Updated
- <list of docs updated>

### Next Phase
- <next phase name>
```

### 4. Incident Report
Generated when the orchestrator stops due to a critical issue.

```markdown
## Incident Report: <Issue Type>

**Date**: <YYYY-MM-DD>
**Severity**: CRITICAL | HIGH | MEDIUM | LOW
**Stop Reason**: <HUMAN_DECISION_REQUIRED | CRITICAL_BLOCKER | RETRY_EXHAUSTED>

### Description
<description of the issue>

### Affected Tasks
- <list of affected tasks>

### Actions Taken
- <list of actions taken before stopping>

### Recovery Instructions
1. <step 1>
2. <step 2>
3. <step 3>

### Required Human Action
<specific action needed from human>
```

## Report Storage

Reports are stored in `automation/state/reports/`:
- `task_<task_name>_<date>.md`
- `sprint_<sprint_name>_<date>.md`
- `phase_<phase_name>_<date>.md`
- `incident_<date>_<description>.md`

## Report Generation Triggers

| Trigger | Report Type |
|---------|-------------|
| Task completed | Task Report |
| Sprint completed | Sprint Report |
| Phase completed | Phase Report |
| Orchestrator stops | Incident Report |
| Human intervention | Incident Report |
| Validation failure after retries | Incident Report |

## Report Format

All reports follow the markdown format defined above. Reports must include:
- Accurate dates
- Clear status indicators
- Complete validation results
- Actionable next steps
- No hard-coded secrets or sensitive information

## Report Integration

Reports are referenced in:
- `docs/PROGRESS.md` — summary of completed work
- `automation/state/checkpoint.json` — current state and stop reason
- Git commits — commit messages reference report IDs when applicable
