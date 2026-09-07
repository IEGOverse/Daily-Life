# Daily Life — AI Development Reporting

## Purpose

Reports are the primary human-facing output of autonomous development. The human should be able to understand project progress without reading terminal output or implementation details.

## Checkpoint Report

Use this structure:

```text
DAILY LIFE — DEVELOPMENT REPORT

Checkpoint:
Sprint:
Task:
Status:

SUMMARY
- ...

IMPLEMENTED
- ...

VALIDATION
- Format: PASS/FAIL
- Static analysis: PASS/FAIL
- Tests: PASS/FAIL (count when available)
- Build/code generation: PASS/FAIL/N/A

REVIEW
- Product compliance: PASS/FAIL
- Architecture: PASS/FAIL
- Database: PASS/FAIL/N/A
- UI/UX: PASS/FAIL/N/A
- Security/privacy: PASS/FAIL/N/A
- Regression: PASS/FAIL

AUTOMATIC FIXES
- ...

TECHNICAL DEBT
- ...

GIT
- Commit: ...

NEXT ACTION
- ...

HUMAN DECISION
- NONE
```

## Sprint Completion Report

A sprint report should additionally include:

- sprint objective;
- completed tasks;
- incomplete/deferred tasks;
- quality summary;
- important architectural decisions;
- technical debt accumulated or resolved;
- files/modules materially changed;
- final review status;
- next sprint recommendation.

## Human Decision Report

When human approval is required, use:

```text
DAILY LIFE — HUMAN DECISION REQUIRED

DECISION
- ...

WHY
- ...

CURRENT REQUIREMENT
- ...

PROPOSED CHANGE
- ...

IMPACT
- Product:
- Architecture:
- Database:
- Privacy:
- Schedule/roadmap:

OPTIONS
1. ...
2. ...
3. ...

AI RECOMMENDATION
- ...

WORKFLOW STATUS
BLOCKED — waiting for human decision
```

## Reporting Principles

- Be concise but complete.
- Report facts, not vague claims.
- Distinguish implemented work from planned work.
- Never hide failures or unresolved issues.
- Clearly identify whether human action is required.
- Do not require the human to inspect logs to understand the result.
