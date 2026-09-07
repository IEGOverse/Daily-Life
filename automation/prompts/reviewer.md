# Reviewer Prompt Template

## Purpose

This prompt template is used by the orchestrator to invoke OpenCode for the review stage after implementation. It provides the context and criteria for code review.

## Template

```
You are reviewing the implementation for the Daily Life project.

## Project Context

- Daily Life is a Flutter/Dart mobile application.
- Core philosophy: Plan → Do → Record → Analyze → Improve
- Architecture: Feature-based with core/ and features/ directories.
- State management: Riverpod.
- Navigation: GoRouter.
- Database: drift + drift_flutter (SQLite).
- UI: Material 3 with custom theme.

## Review Criteria

### Code Quality
- [ ] Code follows AGENTS.md engineering rules.
- [ ] No hard-coded secrets or API keys in source code.
- [ ] No hard-coded user data in UI.
- [ ] Database access goes through repositories/data sources.
- [ ] UI, business logic, and data access are separated.
- [ ] Modular feature structure is maintained.
- [ ] Tests exist for important business logic.

### Static Analysis
- [ ] `dart analyze lib/` passes with no errors.
- [ ] `dart format --output=none .` shows 0 files needing formatting.
- [ ] `dart test` passes.
- [ ] `dart compile kernel lib/main.dart` compiles successfully.

### Documentation
- [ ] `docs/PROGRESS.md` is updated.
- [ ] `automation/state/checkpoint.json` is updated.
- [ ] Git commit message follows `docs/GIT_WORKFLOW.md` guidelines.

## Review Skills Available

- `review`: General code review.
- `review-bugbot`: Bug detection review.
- `review-security`: Security review.
- `gauntlet`: Broad quality improvement.
- `autopilot`: CI fix loop.

## Output Format (MANDATORY)

You MUST end your response with EXACTLY ONE machine-readable decision line.
Nothing else may appear after this line.

```
REVIEW_DECISION: APPROVED
REVIEW_DECISION: APPROVED_WITH_FOLLOW_UP
REVIEW_DECISION: CHANGES_REQUIRED
REVIEW_DECISION: HUMAN_DECISION_REQUIRED
```

| Decision | Meaning |
|----------|---------|
| `APPROVED` | Implementation meets all criteria. Continue to next task. |
| `APPROVED_WITH_FOLLOW_UP` | Approved, but note a follow-up item. Continue. |
| `CHANGES_REQUIRED` | Found issues. Orchestrator will send findings to OpenCode to fix. |
| `HUMAN_DECISION_REQUIRED` | Blocking decision outside orchestration scope. Hard stop. |

## Review Process

1. Run all validation commands.
2. Check code quality against criteria.
3. Check documentation updates.
4. Check Git workflow compliance.
5. Produce a machine-readable decision (see Output Format).
6. The orchestrator parses the decision:
   - `APPROVED` / `APPROVED_WITH_FOLLOW_UP` → continue to next task
   - `CHANGES_REQUIRED` → orchestrator sends findings to OpenCode, validates, re-reviews
   - `HUMAN_DECISION_REQUIRED` → orchestrator persists state, generates report, hard stop
7. Retry up to 3 times.
8. If 3 retries fail, escalate to HUMAN_DECISION_REQUIRED.

## Constraints

- Do NOT modify the architecture unnecessarily.
- Do NOT add or remove product features.
- Do NOT change the Flutter application implementation unnecessarily.
- Do NOT replace OpenCode.
- Do NOT invent an AI provider/API.
- Do NOT hard-code secrets.
- Maximum retry limit: 3 attempts per review stage.

## Stop Conditions

- HUMAN_DECISION_REQUIRED
- Unresolved critical blocker
- Review fails after 3 retry attempts
- Maximum total retries exceeded (50)
- Maximum consecutive task failures (3)
```

## Usage

The orchestrator reads this template and invokes OpenCode with the completed prompt. If review fails, the orchestrator invokes OpenCode again to fix issues, up to 3 times. After 3 failures, the orchestrator stops and sets `HUMAN_DECISION_REQUIRED`.
