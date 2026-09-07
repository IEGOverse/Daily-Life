# Developer Prompt Template

## Purpose

This prompt template is used by the orchestrator to invoke OpenCode for implementation tasks. It provides the context, constraints, and expectations for the implementation.

## Template

```
You are implementing a task for the Daily Life project.

## Project Context

- Daily Life is a Flutter/Dart mobile application.
- Core philosophy: Plan → Do → Record → Analyze → Improve
- Architecture: Feature-based with core/ and features/ directories.
- State management: Riverpod.
- Navigation: GoRouter.
- Database: drift + drift_flutter (SQLite).
- UI: Material 3 with custom theme.

## Engineering Rules (from AGENTS.md)

1. Read relevant documentation before changing code.
2. Do not implement unspecified features.
3. Inspect the existing codebase before modifying it.
4. Keep features modular and avoid unrelated changes.
5. Keep UI, business logic, and data access separated.
6. Database access must go through repositories/data sources.
7. Do not hard-code user data into UI.
8. Prefer reusable components over duplicated UI.
9. Preserve existing architecture unless a change is justified.
10. Add or update tests for important business logic.
11. Do not expose secrets or API keys in source code.
12. Prefer offline-first behavior for core personal data.

## Task Description

{{TASK_DESCRIPTION}}

## Required Documentation

Read these files before implementing:
- docs/ROADMAP.md
- docs/PROGRESS.md
- docs/ARCHITECTURE.md
- docs/DATABASE.md
- docs/PRD.md
- docs/AI_WORKFLOW.md
- docs/AI_DECISION_POLICY.md
- docs/AI_REVIEW.md

## Implementation Requirements

1. Read the relevant documentation and existing code.
2. Inspect the current implementation.
3. Identify affected files and dependencies.
4. Implement only the approved scope.
5. Run formatter, analyzer, tests, and build/check.
6. Summarize files changed, tests run, and remaining issues.

## Validation Requirements

After implementation, the following must pass:
- `dart format --output=none .` (0 files changed)
- `dart analyze lib/` (no issues)
- `dart test` (all tests pass)
- `dart compile kernel lib/main.dart` (compiles successfully)

## Constraints

- Do NOT add or remove Daily Life product features.
- Do NOT change the Flutter application implementation unnecessarily.
- Do NOT replace OpenCode.
- Do NOT invent an AI provider/API.
- Do NOT hard-code secrets.
- Do NOT create unsafe infinite loops.
- Maximum retry limit: 3 attempts.
- Stop when HUMAN_DECISION_REQUIRED or unresolved critical blocker.

## Definition of Done

A feature is done when:
- Requirements are implemented.
- Existing behavior is not unintentionally broken.
- Code is formatted.
- Static analysis passes.
- Relevant tests pass.
- Empty/loading/error states are handled where applicable.
- Documentation is updated when behavior or architecture changes.
```

## Usage

The orchestrator reads this template and replaces `{{TASK_DESCRIPTION}}` with the actual task from `docs/ROADMAP.md` and `docs/PROGRESS.md`. It then invokes OpenCode with the completed prompt.

## Safety

- The prompt does not include any hard-coded secrets.
- The prompt does not include any API keys.
- The prompt does not invent any AI providers.
- The prompt enforces the maximum retry limit.
- The prompt includes explicit stop conditions.
