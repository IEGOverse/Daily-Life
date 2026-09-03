# Sprint 0 — Foundation

## Objective
Create a clean, runnable Flutter foundation for Daily Life without implementing business modules.

## In Scope
- Flutter project initialization
- Feature-based folder structure
- Riverpod
- GoRouter
- SQLite foundation
- Theme/design tokens
- Reusable UI foundation
- Navigation shell
- Basic Today screen
- Test structure
- Git hygiene

## Explicitly Out of Scope
- Workout
- Study
- Finance
- Nutrition
- Habits
- Analytics
- AI
- Notifications
- Cloud sync
- Authentication

## Acceptance Criteria
- App launches successfully.
- Navigation shell works.
- Today screen has the intended foundation layout.
- Architecture follows ARCHITECTURE.md.
- Database layer is isolated behind appropriate abstractions.
- Shared UI components use design tokens.
- No hard-coded user-specific records in presentation code.
- `flutter analyze` passes.
- Relevant tests pass.
- Build check succeeds.
- PROGRESS.md is updated.
- A focused Git commit exists.

## Agent Strategy
Do not attempt the whole sprint in one giant operation.
Break implementation into recoverable checkpoints:
1. Flutter project + Git
2. Architecture + dependencies
3. Theme + shared UI
4. Routing + navigation shell
5. Database foundation
6. Today foundation
7. Tests + verification
8. Documentation checkpoint + commit
