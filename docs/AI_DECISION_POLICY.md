# Daily Life — AI Decision Policy

## Purpose

This document defines the decision-making framework for the local autonomous development orchestrator. It specifies when the orchestrator must make autonomous decisions, when it must defer to human judgment, and how to handle conflicts between automation and project documentation.

## Decision Hierarchy

```
Human Decision Required    ← Highest priority, hard stop
    │
    ▼
Critical Blocker          ← Unresolvable, stop and document
    │
    ▼
Orchestrator Decision     ← Autonomous, follow rules
    │
    ▼
Default Behavior          ← Follow existing docs
```

## Autonomous Decisions

The orchestrator MAY make these decisions without human input:

1. **Task Selection**: Choose the next task from the approved roadmap.
2. **Implementation**: Invoke OpenCode to implement approved tasks.
3. **Validation**: Run format, analyze, test, and build checks.
4. **Retry**: Retry failed validation up to 3 times.
5. **Commit**: Commit with appropriate message when validation passes.
6. **Progress Update**: Update `docs/PROGRESS.md` and `automation/state/checkpoint.json`.
7. **Stop**: Stop when the roadmap has no more approved tasks.

## Human Decision Required (HARD STOP)

The orchestrator MUST stop and request human input when:

### 1. Architectural Changes
- A task requires changes to the overall architecture not defined in `docs/ARCHITECTURE.md`.
- A new module needs to be added that changes the project structure significantly.
- The data model needs fundamental changes to existing tables.

### 2. Missing Documentation
- A feature is needed that is not in `docs/ROADMAP.md`.
- The `docs/PRD.md` needs updating for a new feature scope.
- `docs/AI_WORKFLOW.md` needs updating for a new workflow stage.

### 3. SDK/Tool Issues
- The Flutter/Dart SDK has compatibility issues that cannot be resolved by the orchestrator.
- `opencode` is unavailable and no alternative invocation method exists.
- A critical dependency (e.g., `drift`, `build_runner`) has breaking changes.

### 4. Retry Exhaustion
- Validation fails after 3 retry attempts for the same task.
- Review fails after 3 retry attempts for the same task.
- The same critical error persists across multiple task iterations.

### 5. Scope Changes
- A task's scope needs to be expanded beyond the approved roadmap.
- A task's scope needs to be reduced, potentially affecting other tasks.
- A feature needs to be deferred or removed from the roadmap.

## Decision Process

When a decision is needed:

1. **Check existing documentation** (`docs/ROADMAP.md`, `docs/ARCHITECTURE.md`, `docs/AI_WORKFLOW.md`).
2. **Check `automation/state/checkpoint.json`** for previous decisions.
3. **Check `docs/PROGRESS.md`** for current status.
4. **If the decision is covered by existing docs**, proceed autonomously.
5. **If the decision is NOT covered**, determine the category:
   - **Minor**: Make the decision and document it.
   - **Major**: Set `HUMAN_DECISION_REQUIRED` and stop.
6. **If the decision affects the roadmap**, set `HUMAN_DECISION_REQUIRED` and stop.

## Retry Policy

| Stage | Max Retries | Action on Exhaustion |
|-------|-------------|---------------------|
| Validation (format/analyze/test) | 3 | Set `HUMAN_DECISION_REQUIRED` |
| Review | 3 | Set `HUMAN_DECISION_REQUIRED` |
| Build | 3 | Set `HUMAN_DECISION_REQUIRED` |
| Fix | 3 | Set `HUMAN_DECISION_REQUIRED` |
| **Total per task** | **Max 3 validation + 3 fix + 3 review** | **Stop and escalate** |

## Priority Order

When multiple rules apply, the following priority order is used:

1. `HUMAN_DECISION_REQUIRED` always wins.
2. Critical blockers always stop the orchestrator.
3. Existing documentation overrides default behavior.
4. `docs/GIT_WORKFLOW.md` commit guidelines are always followed.
5. `AGENTS.md` engineering rules are always followed.

## Documentation Updates

When the orchestrator makes an autonomous decision that affects the project:
- Update `docs/PROGRESS.md` to reflect the decision.
- Update `automation/state/checkpoint.json` to record the decision.
- Do NOT modify `docs/ROADMAP.md` without human approval.
- Do NOT modify `docs/ARCHITECTURE.md` without human approval.
