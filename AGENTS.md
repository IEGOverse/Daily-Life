# Activus — AI Agent Instructions

## Project
Activus is a personal-first, production-quality mobile application built with Flutter and Dart. It helps one primary user plan, record, and analyze daily life.

Core modules:
- Schedule
- Activity
- Workout
- Study
- Finance
- Nutrition
- Habits
- Analytics / Insights

Core philosophy:
Plan → Do → Record → Analyze → Improve

## Source of Truth

Before changing code, read the relevant project documentation. The primary sources of truth are:

- `docs/PRD.md`
- `docs/ARCHITECTURE.md`
- `docs/DATABASE.md`
- `docs/UI_UX.md`
- `docs/ROADMAP.md`
- `docs/PROGRESS.md`
- relevant sprint/feature documents
- `docs/AI_WORKFLOW.md`
- `docs/AI_DECISION_POLICY.md`
- `docs/AI_REVIEW.md`
- `docs/REPORTING.md`

## Engineering Rules

1. Read relevant documentation before changing code.
2. Do not implement unspecified product features.
3. Inspect the existing codebase before modifying it.
4. Keep features modular and avoid unrelated changes.
5. Keep UI, business logic, and data access separated.
6. Database access must go through repositories/data sources.
7. Do not hard-code user data into UI.
8. Prefer reusable components over duplicated UI.
9. Preserve existing architecture unless a justified and approved change is required.
10. Add or update tests for important business logic.
11. Do not expose secrets or API keys in source code.
12. Prefer offline-first behavior for core personal data.
13. Never silently expand or reduce product scope.

## Context-Efficiency Rule

- **AI_CONTEXT.md is the first project-context document to read**. It provides a concise operational snapshot; do not consume context by rereading all documentation by default.
- **Detailed documents should be loaded selectively** based on the current task (PRD for requirements, ARCHITECTURE for design, DATABASE for schema, UI_UX for interactions).
- **Source code and authoritative detailed documents take precedence over summaries when resolving conflicts**.
- **Git history and `docs/PROGRESS.md` must be used to recover interrupted work**.
- Do not implement unspecified product features or materially change roadmap/MVP scope without human approval.

## Autonomous Development Mode

The agent is authorized to autonomously execute the approved roadmap and continue through approved tasks without waiting for user input after every task.

For each task:

1. Read the source of truth.
2. Inspect repository state and recent history.
3. Create an implementation plan.
4. Implement the approved scope.
5. Run formatting, analysis, tests, code generation, and relevant builds/checks.
6. Diagnose and fix implementation-level failures autonomously.
7. Review the resulting diff against the source of truth.
8. Update relevant documentation and `docs/PROGRESS.md`.
9. Create a focused Git checkpoint when the increment is stable.
10. Continue to the next approved task.

Do not stop merely because a task is complete. Continue to the next approved roadmap task unless a human decision, unresolved critical blocker, or explicit stop condition is reached.

## Autonomous Fix Policy

The agent may independently fix:

- bugs and regressions;
- analyzer/formatter/build failures;
- test failures;
- implementation-level technical debt;
- refactoring that preserves approved behavior;
- missing tests;
- loading/empty/error states within approved requirements;
- documentation inconsistencies that do not change product intent.

## Human Approval Gate

The agent MUST stop and request explicit human approval before:

- adding a new product feature not already approved;
- removing an existing product feature;
- materially changing product requirements;
- materially changing roadmap or MVP scope;
- materially changing an existing user workflow;
- changing core architecture;
- replacing a primary technology/framework/database/state-management approach;
- introducing paid external services;
- introducing cloud infrastructure that materially changes privacy or data handling;
- materially changing data ownership, retention, synchronization, or privacy behavior;
- performing an irreversible/destructive product decision when intent is uncertain.

Use `docs/AI_DECISION_POLICY.md` for the exact decision boundary and approval request format.

If ambiguity can be resolved without changing product intent, resolve it autonomously and document the interpretation. If resolving it would alter product scope or behavior materially, stop and ask.

## Review Gate

Do not treat successful tests as sufficient proof of completion. Meaningful checkpoints must pass the review standard in `docs/AI_REVIEW.md`.

If review finds a technical issue, fix it autonomously and re-run validation/review. If review identifies a product/scope decision, stop for human approval.

## Definition of Done

A task is done when:

- Requirements are implemented.
- Existing behavior is not unintentionally broken.
- Code is formatted.
- Static analysis passes.
- Relevant tests pass.
- Empty/loading/error states are handled where applicable.
- Relevant build/check passes.
- Documentation is updated when behavior or architecture changes.
- The final diff has been reviewed.
- No unresolved blocking issue remains.

## Reporting

At meaningful checkpoints and sprint completion, produce a report following `docs/REPORTING.md`.

Reports must state completed work, validation results, review findings, automatic fixes, technical debt, next action, and whether human approval is required.

The human should not need terminal logs or screenshots to understand development progress.

## Interruption and Recovery

If work is interrupted, do not reset or discard unrelated changes. Inspect:

- `git status`
- `git diff`
- recent Git history
- `docs/PROGRESS.md`
- relevant sprint/task documentation

Resume from the existing repository state.

## Core Principle

> AI decides how to build the approved product. The human decides what the product should become.
