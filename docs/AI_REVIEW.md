# Daily Life — AI Review Standard

## Purpose

The AI reviewer acts as an independent quality gate. A successful implementation is not automatically accepted merely because tests pass.

## Review Areas

### 1. Product Compliance

- Does the implementation match the PRD and approved sprint scope?
- Was any unapproved feature added?
- Was any approved feature removed or materially changed?

### 2. Architecture

- Does code follow the documented architecture?
- Are UI, business logic, repositories, and data sources appropriately separated?
- Are dependencies flowing in the intended direction?
- Is there unnecessary complexity or duplication?

### 3. Database

- Does implementation match `docs/DATABASE.md`?
- Are nullability and relationships correct?
- Are migrations safe?
- Are derived values calculated rather than incorrectly stored as authoritative data?

### 4. Flutter / Dart

- Correct state management usage;
- correct navigation;
- lifecycle and async handling;
- reusable widgets where appropriate;
- no avoidable rebuilds or hard-coded user data;
- sensible error handling.

### 5. UI / UX

- Consistent with `docs/UI_UX.md`;
- usable on the intended mobile viewport;
- loading states;
- empty states;
- error states;
- sensible interaction flow;
- no accidental scope expansion.

### 6. Testing

- Relevant business logic has tests;
- existing tests remain passing;
- important edge cases are covered;
- generated code is up to date when applicable.

### 7. Security / Privacy

- No secrets committed;
- no unsafe handling of personal data;
- offline-first expectations preserved for core personal data;
- new external services identified and gated when necessary.

### 8. Regression / Maintainability

- Existing functionality remains intact;
- implementation is understandable and maintainable;
- technical debt is recorded;
- unrelated files are not changed unnecessarily.

## Review Outcomes

### APPROVED

No blocking issues. The workflow may continue to the next approved task.

### APPROVED_WITH_FOLLOW_UP

No blocking issues, but non-critical technical debt or improvements should be recorded for later work. The workflow may continue.

### CHANGES_REQUIRED

A technical or quality issue must be fixed before the checkpoint is accepted. The agent should fix it autonomously and request another review.

### HUMAN_DECISION_REQUIRED

The issue requires a product/scope/architecture decision outside the autonomous boundary. Stop and request human approval using `docs/AI_DECISION_POLICY.md`.

## Severity

- **BLOCKER** — unsafe, broken, scope violation, data corruption risk, or fundamental architecture/product problem.
- **HIGH** — significant defect or requirement violation that should be fixed before acceptance.
- **MEDIUM** — meaningful quality issue or technical debt; may require follow-up depending on impact.
- **LOW** — minor improvement with no meaningful impact on correctness.

## Review Report Requirements

Every review report must contain:

1. checkpoint/task;
2. status;
3. summary;
4. implemented changes;
5. validation results;
6. findings grouped by severity;
7. automatic fixes performed;
8. remaining technical debt;
9. scope changes, if any;
10. next action;
11. human decision request when required.

## Reviewer Independence

The reviewer should evaluate the resulting implementation and diff against the source of truth rather than simply trusting the implementing agent's summary.
