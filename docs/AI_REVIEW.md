# Daily Life — AI Review Process

## Purpose

This document defines how the local autonomous development orchestrator invokes the review stage after implementation. It specifies the review criteria, the review tools, and the review workflow.

## Review Overview

After OpenCode implements a task, the orchestrator invokes the review stage to verify:
1. Code quality and best practices.
2. Architecture compliance.
3. Test coverage and correctness.
4. Documentation accuracy.
5. No regressions in existing functionality.

## Review Stages

### Stage 1: Static Analysis
- **Tool**: `dart analyze lib/`
- **Criteria**: No errors, no warnings (only info/deprecation notes are acceptable).
- **Failure Action**: Invoke OpenCode to fix issues, retry up to 3 times.

### Stage 2: Formatting
- **Tool**: `dart format --output=none .`
- **Criteria**: 0 files need formatting.
- **Failure Action**: Run `dart format .` and re-check.

### Stage 3: Unit/Widget Tests
- **Tool**: `flutter test`
- **Criteria**: All tests pass.
- **Failure Action**: Invoke OpenCode to fix failing tests, retry up to 3 times.

### Stage 4: Build
- **Tool**: `flutter build bundle` (real Flutter compile check; needs no mobile SDK)
- **Criteria**: Compiles without errors.
- **Failure Action**: Invoke OpenCode to fix build errors, retry up to 3 times.

### Stage 5: Code Review
- **Tool**: `opencode` with the `review` skill or `review-bugbot` skill.
- **Criteria**: 
  - Code follows `AGENTS.md` engineering rules.
  - No hard-coded secrets or API keys.
  - No hard-coded user data in UI.
  - Database access goes through repositories/data sources.
  - UI, business logic, and data access are separated.
  - Modular feature structure is maintained.
  - Tests exist for important business logic.
- **Failure Action**: Invoke OpenCode to fix review findings, retry up to 3 times.

## Review Skills

The orchestrator uses the following skills for review:

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `review` | General code review | After implementation passes validation |
| `review-bugbot` | Bug detection review | After implementation, focused on bugs |
| `review-security` | Security review | After implementation, focused on security |
| `gauntlet` | Broad quality improvement | When major quality issues are found |
| `autopilot` | CI fix loop | When CI needs to be repaired |

## Review Invocation

The orchestrator invokes the review via OpenCode. There is NO `--skill` flag on
the installed OpenCode CLI (1.18.18); agents are selected with `--agent`.

```powershell
# Invoke review (general code review message)
opencode run "REVIEW_DECISION prompt..." --format json --auto

# Invoke with a specific review agent (if configured)
opencode run "REVIEW_DECISION prompt..." --agent <agent> --format json --auto
```

## Review Decision (machine-readable)

The reviewer MUST end its response with EXACTLY ONE machine-readable decision
line. The orchestrator parses this line to drive the gate.

```
REVIEW_DECISION: APPROVED
REVIEW_DECISION: APPROVED_WITH_FOLLOW_UP
REVIEW_DECISION: CHANGES_REQUIRED
REVIEW_DECISION: HUMAN_DECISION_REQUIRED
```

| Decision | Orchestrator Action |
|----------|---------------------|
| `APPROVED` | Continue to next task. |
| `APPROVED_WITH_FOLLOW_UP` | Record follow-up, continue. |
| `CHANGES_REQUIRED` | Send findings to OpenCode → fix → validate → re-review. |
| `HUMAN_DECISION_REQUIRED` | Persist state → generate decision report → hard stop. |

A successful invocation of the review agent is NOT approval. Only a parsed
`APPROVED` / `APPROVED_WITH_FOLLOW_UP` decision is treated as approval.

## Review Criteria Checklist

- [ ] All `dart analyze lib/` checks pass with no errors
- [ ] `dart format --output=none .` shows 0 files needing formatting
- [ ] All `dart test` tests pass
- [ ] `dart compile kernel lib/main.dart` succeeds
- [ ] No hard-coded secrets or API keys in source code
- [ ] No hard-coded user data in UI
- [ ] Database access goes through repositories/data sources
- [ ] UI, business logic, and data access are separated
- [ ] Feature modularity is maintained
- [ ] Tests exist for important business logic
- [ ] `docs/PROGRESS.md` is updated
- [ ] `automation/state/checkpoint.json` is updated
- [ ] Git commit message follows `docs/GIT_WORKFLOW.md` guidelines

## Review Failure Handling

When review fails:
1. Record the failure reason in `automation/state/checkpoint.json`.
2. Invoke OpenCode to fix the issues.
3. Re-run validation and review.
4. Retry up to 3 times.
5. If 3 retries fail, set `HUMAN_DECISION_REQUIRED`.

## Review Completion

When review passes:
1. Update `docs/PROGRESS.md`.
2. Update `automation/state/checkpoint.json`.
3. Commit with appropriate message.
4. Continue to the next task or stop if no more tasks exist.

## Stop Conditions

The review stage must stop and escalate when:
- Review fails after 3 retry attempts.
- A security vulnerability is found that cannot be fixed by the orchestrator.
- A architectural change is required that is not covered by existing documentation.
- `HUMAN_DECISION_REQUIRED` is triggered.
