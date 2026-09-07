# Daily Life — AI Context Summary

**Purpose**: Personal-first mobile app (Flutter/Dart) helping one user plan, record, and analyze daily life.

**Architecture**:
- Flutter 3.47.2 / Dart 3.13.2
- Riverpod 2.6.1 for state management
- GoRouter for navigation
- Drift 2.34.4 for SQLite (code-generated)
- Feature-based project structure under `lib/features/`

**Current Phase**: Phase 3 — Study  
**Current Sprint**: Sprint 3 — Study (COMPLETE - Task 1 done)  
**Status**: All Phase 3 Task 1 (Study sessions CRUD) implemented and validated. Phase 3 Task 2-5 planned.

**Completed Milestones**:
- Sprint 1 (Phase 1 — Daily Core): 6/6 tasks APPROVED after 2 CHANGES_REQUIRED rounds. 53 tests pass, `flutter build bundle` exit 0.
- Sprint 2 (Phase 2 — Workout): 5/5 tasks completed and pushed. Exercise library, workout plans, sessions, set logging, history all delivered.
- Sprint 3 (Phase 3 — Study): Task 1 — Study sessions CRUD implemented. Repository supports insert, update, delete via `StudySession` entity. All 79 tests pass, `flutter build bundle` exit 0.
- Database schema v2: nullable fields + FKs per `docs/DATABASE.md`; UTC-normalized local-day boundaries.

**Current Task**: Phase 3 — Study Task 2: Topics; Task 3: Notes; Task 4: History; Task 5: Basic study statistics.

**Important Architectural Decisions**:
- Write-side builds local `DateTime` then `.toUtc()` to preserve wall-clock (Drift reader returns local).
- Single-flight seed lock prevents concurrent first-launch inserts.
- Riverpod `overrideWithValue` works only on providers; `ref.invalidate(family)` invalidates all instances.
- No `uuid`/`intl` packages; IDs generated with timestamps + slugs.
- `StudySession` entity stored directly; `update()` delegates to `insert()` with `onConflictReplace`.

**Important Constraints**:
- Offline-first behavior for core personal data.
- Supabase/cloud sync intentionally deferred.
- AI features intentionally deferred.
- Flutter/Dart SDK compatibility note: `flutter test` passes with +4 framework errors (not code-level).

**Latest Checkpoint**: Commit `1023120 feat(workout): add workout history` (Phase 2 complete), plus Study Sessions CRUD implementation.

**Validation Status**:
- `dart analyze lib/ test/`: No issues found
- `dart format --output=none lib test`: clean
- `flutter test`: 79 tests pass (53 Sprint 1 + 26 Phase 2-3)
- `flutter build bundle`: exit 0

**Known Blockers / Debt**:
- Study session CRUD verified with end-to-end tests (79 tests pass).
- Recurrence/occurrence strategy not finalized (Phase 3+).
- Phase 3 Tasks 2-5 (Topics, Notes, History, Statistics) not yet started.

**Instructions for Resuming Work**:
1. Read `docs/AI_CONTEXT.md` first.
2. Read `AGENTS.md` for autonomous development rules.
3. Read `docs/PROGRESS.md` for current sprint state.
4. Read `docs/ROADMAP.md` for phase overview.
5. Inspect `git status` and relevant source files.
6. Continue first incomplete checklist item in `docs/PROGRESS.md`.
7. Update `docs/PROGRESS.md` after meaningful progress.
8. Commit only when increment is stable.