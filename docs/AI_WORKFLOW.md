# Daily Life — Autonomous AI Development Workflow

## Purpose

Daily Life uses an autonomous development workflow. AI agents are responsible for planning, implementation, validation, review, documentation, and progression through the approved roadmap.

The human acts primarily as Product Owner. Human intervention is required only for material product or scope decisions.

## Core Loop

```text
Read Source of Truth
        ↓
Plan Task
        ↓
Implement
        ↓
Validate
        ↓
AI Review
        ↓
 ┌──────┴────────┐
 │               │
Fix Required   Approved
 │               │
 └──→ Re-review  ↓
             Checkpoint
                 ↓
          Update Progress
                 ↓
            Next Task
```

## Source of Truth

Agents must read and respect, in order of relevance:

1. `AGENTS.md`
2. `docs/PRD.md`
3. `docs/ARCHITECTURE.md`
4. `docs/DATABASE.md`
5. `docs/UI_UX.md`
6. `docs/ROADMAP.md`
7. `docs/PROGRESS.md`
8. Relevant sprint/feature documentation

If these documents conflict, the agent must not silently choose a product-level interpretation. It should resolve the conflict using the decision policy or request human approval when necessary.

## Autonomous Responsibilities

AI may independently:

- implement approved roadmap tasks;
- fix bugs and regressions;
- refactor implementation without changing product behavior;
- add and improve tests;
- fix analyzer, formatter, build, and code-generation failures;
- resolve implementation-level technical debt;
- improve loading, empty, and error states within existing requirements;
- update documentation to reflect approved behavior;
- create focused Git checkpoints;
- continue to the next approved task after a successful review.

## Validation Gate

A task is not complete until applicable checks pass:

- formatting;
- static analysis;
- relevant tests;
- generated code when applicable;
- relevant build/check;
- review of the final diff.

Failures should normally be diagnosed and fixed autonomously. Re-run validation after each fix.

## Review Gate

Every meaningful checkpoint must be reviewed against:

- product requirements;
- architecture;
- database design;
- UI/UX rules;
- code quality;
- tests;
- security/privacy;
- regression risk;
- scope compliance.

Review outcomes are defined in `docs/AI_REVIEW.md`.

## Human Gate

AI must stop and request a human decision before:

- adding a product feature not already approved;
- removing an existing product feature;
- materially changing product requirements;
- materially changing the roadmap or scope;
- changing the core architecture without an approved architectural decision;
- replacing a primary technology or framework;
- introducing a paid external service;
- introducing cloud infrastructure that changes the privacy/data model;
- materially changing data ownership, retention, or privacy behavior;
- making an irreversible or destructive product decision.

Technical implementation choices that stay inside approved requirements do not require human approval.

## Interruption and Recovery

If an agent is interrupted, it must inspect:

- `git status`;
- `git diff`;
- recent Git history;
- `docs/PROGRESS.md`;
- the relevant task/sprint documentation.

It must continue from the existing state rather than resetting or discarding unrelated work.

## Reporting

At each meaningful checkpoint or sprint completion, produce a report using `docs/REPORTING.md`.

Reports must clearly distinguish:

- work completed;
- validation results;
- review findings;
- automatic fixes;
- remaining technical debt;
- next task;
- human decisions required, if any.

## Operating Principle

> AI decides how to build the approved product. The human decides what the product should become.
