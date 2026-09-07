# Daily Life — AI Workflow

## Purpose

This document defines how the local autonomous development orchestrator manages the Daily Life project's AI-assisted development lifecycle. It provides the contract between the orchestrator, OpenCode, the review system, and human oversight.

## Workflow Overview

```
Read Roadmap + Progress
        │
        ▼
Determine Next Task
        │
        ▼
Invoke OpenCode (Implementation)
        │
        ▼
Validate (format, analyze, test, build)
        │
        ▼
Invoke Review
        │
        ▼
Fix Issues (if any, up to max_retries)
        │
        ▼
Commit + Update Progress
        │
        ▼
Continue to Next Task or Stop
```

## Stages

### Stage 1: Read & Determine
1. Read `docs/ROADMAP.md` for approved phases and tasks.
2. Read `docs/PROGRESS.md` for current status and next task.
3. Read `docs/GIT_WORKFLOW.md` for commit guidelines.
4. Determine the next approved task from the roadmap.
5. Check `automation/state/` for any previous checkpoint state.

### Stage 2: Invoke OpenCode
1. Use `opencode` command to invoke OpenCode for implementation.
2. Pass the task description, relevant docs, and architecture context.
3. OpenCode implements the task following AGENTS.md engineering rules.

### Stage 3: Validate
1. Run `dart format --output=none .`
2. Run `dart analyze lib/`
3. Run `dart test`
4. Run `dart compile kernel lib/main.dart` or `flutter analyze`
5. Any failure triggers Stage 4 (Fix).

### Stage 4: Fix & Retry
1. On validation failure, invoke OpenCode to fix issues.
2. Retry limit: **3 attempts** per task.
3. After 3 failed attempts, escalate to `HUMAN_DECISION_REQUIRED`.
4. Do NOT loop infinitely.

### Stage 5: Invoke Review
1. After validation passes, invoke the review stage.
2. Review checks: code quality, architecture compliance, test coverage.
3. Review uses the `review` skill or `review-bugbot` skill.
4. If review fails, go back to Stage 4 (fix).

### Stage 6: Commit & Update
1. Update `docs/PROGRESS.md` with completed tasks.
2. Update `automation/state/checkpoint.json` with current state.
3. Commit with appropriate message (see `docs/GIT_WORKFLOW.md`).

### Stage 7: Continue or Stop
- **Continue**: If more tasks exist in the roadmap, go to Stage 1.
- **Stop**: If `HUMAN_DECISION_REQUIRED` or unresolved critical blocker.

## Invocation of OpenCode

OpenCode is invoked via the `opencode` command available in the system PATH.

```powershell
# Check availability
Get-Command opencode

# Invoke OpenCode for a task
opencode --task "<task description>" --context "<project context>"

# Or in the project directory
cd C:\Users\USER\daily_life
opencode "Implement Sprint 1: Today dashboard with actual drift database data"
```

If `opencode` is not available in the PATH, the orchestrator must document the blocker instead of inventing an integration.

## Human Decision Required

The orchestrator must stop and request human input when:
- Validation fails after 3 retry attempts.
- A task requires architectural decisions not covered in existing docs.
- The roadmap needs updating for a new feature.
- A critical blocker cannot be resolved by the orchestrator.

See `docs/AI_DECISION_POLICY.md` for the full decision framework.

## Stop Conditions

The orchestrator MUST stop when:
1. `HUMAN_DECISION_REQUIRED` is triggered.
2. An unresolved critical blocker occurs (e.g., OpenCode unavailable, SDK incompatibility).
3. Maximum retries exceeded for 3 consecutive tasks.
4. The roadmap has no more approved tasks for the current phase.

The orchestrator MUST NOT stop for:
- Individual test failures (go to fix/retry).
- Formatting issues (go to fix/retry).
- Analyzer warnings (go to fix/retry).
- Missing optional documentation (note and continue).

## State Persistence

The orchestrator persists state in `automation/state/checkpoint.json`:

```json
{
  "current_phase": "Phase 1 — Daily Core",
  "current_sprint": "Sprint 1 — Daily Core",
  "current_task": "Implement Today dashboard with drift database",
  "completed_tasks": ["Sprint 0 — Project Initialization"],
  "retry_count": 0,
  "last_updated": "2026-09-07",
  "status": "IN_PROGRESS",
  "stop_reason": null
}
```

After interruption, the orchestrator reads `checkpoint.json` and `docs/PROGRESS.md` to resume from where it left off.
