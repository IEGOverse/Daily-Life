# Daily Life — AI Agent Instructions

## Project
Daily Life is a personal-first, production-quality mobile application built with Flutter and Dart. It helps one primary user plan, record, and analyze daily life.

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

## Engineering Rules
1. Read the relevant documentation before changing code.
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

## AI Agent Workflow
For a new feature:
1. Read PRD.md, ARCHITECTURE.md, DATABASE.md, and relevant feature docs.
2. Inspect the current implementation.
3. Identify affected files and dependencies.
4. Produce an implementation plan.
5. For major architectural changes, ask for approval before coding.
6. Implement only the approved scope.
7. Run formatter, analyzer, tests, and a relevant build/check.
8. Summarize files changed, tests run, and remaining issues.

## Definition of Done
A feature is done when:
- Requirements are implemented.
- Existing behavior is not unintentionally broken.
- Code is formatted.
- Static analysis passes.
- Relevant tests pass.
- Empty/loading/error states are handled where applicable.
- Documentation is updated when behavior or architecture changes.
