# Local Autonomous Development Orchestrator

## Overview

This directory contains the local autonomous development orchestrator for the Daily Life project. The orchestrator safely manages the AI-assisted development lifecycle by reading the roadmap, invoking OpenCode for implementation, validating results, invoking review, and persisting state for recovery.

## Structure

```
automation/
├── README.md              # This file
├── config/
│   └── workflow.yaml      # Workflow configuration (max retries, stop conditions)
├── prompts/
│   ├── developer.md       # Prompt template for OpenCode implementation
│   ├── reviewer.md        # Prompt template for review stage
│   └── decision.md        # Prompt template for human decision escalation
├── scripts/
│   ├── run-task.ps1       # Main orchestrator entry point
│   ├── validate.ps1       # Validation script (format, analyze, test, build)
│   └── checkpoint.ps1     # State persistence and recovery script
└── state/
    ├── .gitkeep           # Placeholder for state directory
    ├── checkpoint.json    # Current orchestrator state
    └── reports/           # Generated reports
        └── .gitkeep
```

## Usage

### Running the Orchestrator

```powershell
# Run the full orchestrator (discovers next approved task)
./automation/scripts/run-task.ps1

# Run a specific task
./automation/scripts/run-task.ps1 -Task "Sprint 1: Today dashboard"

# Dry-run self-test (does NOT modify product code)
./automation/scripts/run-task.ps1 -DryRun

# Validate the project
./automation/scripts/validate.ps1

# Checkpoint state: read status
./automation/scripts/checkpoint.ps1 -Action Status
```

### Task Discovery

The orchestrator reads `docs/ROADMAP.md` and `docs/PROGRESS.md` to determine
the next actually-incomplete approved task. It does NOT use placeholder text.
Task ordering and completed progress (from `- [x]` markers) are respected.

### Autonomous Loop

The orchestrator loops:

```
task → implementation → validation → review → checkpoint → next task
```

It continues through all approved roadmap tasks. It stops ONLY on:
- `HUMAN_DECISION_REQUIRED`
- `CRITICAL_BLOCKER`
- Safety limits exhausted (max tasks/retries/consecutive failures)
- No approved tasks remaining

### Review Decisions

The review stage returns a machine-readable decision parsed from OpenCode output:
- `APPROVED` / `APPROVED_WITH_FOLLOW_UP` → continue
- `CHANGES_REQUIRED` → send findings to OpenCode → fix → validate → re-review
- `HUMAN_DECISION_REQUIRED` → persist state → generate decision report → hard stop

### OpenCode Invocation

Verified against OpenCode CLI 1.18.18. There is NO `--task`, `--context`, or
`--skill` flag. The correct invocation is:

```powershell
opencode run "<message>" --format json [--agent <agent>] [--auto]
```

The `--agent` flag selects an agent (e.g. `explorer`), `--format json` produces
machine-readable output, and `--auto` auto-approves non-denied permissions.

## Safety Rules

- **Maximum retries**: 3 per task for validation, fix, and review.
- **Hard stop**: `HUMAN_DECISION_REQUIRED` causes immediate termination.
- **No infinite loops**: All loops have explicit exit conditions.
- **State persistence**: Progress is saved after each task.
- **No feature changes**: The orchestrator does not add/remove product features.
- **No OpenCode replacement**: The orchestrator invokes OpenCode, it does not replace it.
- **No AI provider invention**: The orchestrator does not invent API providers.
- **No hard-coded secrets**: All configuration is in `config/workflow.yaml`.
- **Never commit unreviewed work**: Git commits only happen after review approves.

## Documentation

- `docs/AI_WORKFLOW.md` — Workflow stages and invocation details.
- `docs/AI_DECISION_POLICY.md` — Decision framework and human escalation.
- `docs/AI_REVIEW.md` — Review process and criteria.
- `docs/REPORTING.md` — Report generation and storage.
- `docs/GIT_WORKFLOW.md` — Git commit and checkpoint guidelines.
