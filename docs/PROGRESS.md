# Daily Life — Project Progress

> This file is the recovery/checkpoint state for AI coding agents.
> The repository, Git history, and this file are authoritative. Do not rely on previous chat memory.

## Current Phase
Phase 1 — Daily Core

## Current Sprint
Sprint 1 — Daily Core (IN PROGRESS)

## Overall Status
IN PROGRESS

## Completed
- [x] Product concept defined
- [x] Core philosophy defined: Plan → Do → Record → Analyze → Improve
- [x] PRD drafted
- [x] Architecture drafted
- [x] Database design drafted
- [x] UI/UX direction drafted
- [x] Roadmap drafted
- [x] AI-agent rules defined
- [x] Phase 1 Task 1 — Today dashboard (greeting, daily progress, NOW/NEXT UP, timeline, finance strip; driven by live drift data)
- [x] Phase 1 Task 2 — Recurring schedule (PRD §5 university schedule seeded; weekly activity generation idempotent; Schedule screen with day selector)
- [x] Phase 1 Task 3 — Activity model (shared `activities` feature: central model, status lifecycle, repository; dashboard/schedule rewire over it)
- [x] Phase 1 Task 4 — Activity completion (done/skip/reset inline actions on dashboard timeline; auto-refresh; persisted)
- [x] Phase 1 Task 5 — Calendar/history (month calendar grid + per-day activity list with completion actions; routed at `/calendar`, reachable from the dashboard date header)
- [x] Phase 1 Task 6 — Add activity (quick-add form: title, category, date, start/end time, notes; saves via `ActivityRepository.insert` and refreshes providers; `/add` route + dashboard quick-add icon) — Phase 1 (Sprint 1) COMPLETE

## Sprint 0 Checklist
- [x] Verify Flutter/Dart installation
- [x] Initialize Flutter application
- [x] Initialize/verify Git repository
- [x] Connect/verify GitHub repository
- [x] Create feature-based project structure
- [x] Configure Riverpod
- [x] Configure GoRouter
- [x] Establish SQLite/database foundation (drift + drift_flutter + build_runner code generation)
- [x] Establish theme/design tokens
- [x] Create reusable UI components foundation
- [x] Create basic Dashboard/Today screen
- [x] Create navigation shell
- [x] Create test structure
- [x] Run formatter (dart format passes, 0 changes)
- [x] Run analyzer (dart analyze lib/ passes with no issues)
- [x] Run tests (flutter test passes: +4: All tests passed!)
- [x] Run build check (build_runner generates successfully)
- [x] Review implementation against project docs
- [x] Create stable Git commit
- [x] Create automation/orchestrator infrastructure
- [x] Create AI documentation (workflow, decision policy, review, reporting)
- [x] Validate all automation scripts

## Automation & Orchestration
- `automation/config/workflow.yaml` — Workflow config with max_retries: 3, stop conditions, safety limits
- `automation/scripts/run-task.ps1` — Main orchestrator (`Invoke-Orchestrator`)
- `automation/scripts/validate.ps1` — Validation script with retry
- `automation/scripts/checkpoint.ps1` — State management, reports, resume
- `automation/prompts/developer.md` — OpenCode implementation prompt template
- `automation/prompts/reviewer.md` — Review prompt template
- `automation/prompts/decision.md` — Human decision escalation prompt template
- `automation/state/checkpoint.json` — State persistence (Phase 0 foundation marked complete, ready for orchestration)
- OpenCode available at `C:\Users\USER\AppData\Roaming\npm\opencode.ps1`

## Verification Results
- `dart analyze lib/`: No issues found
- `dart format --output=none .`: 0 changes
- `flutter test`: All tests passed
- `flutter build bundle`: Compiles successfully (real Flutter compile check, no mobile SDK needed)
- `build_runner`: 38 outputs generated successfully

## Current Task
Sprint 1 in progress. Phase 1 (Daily Core) is functionally complete; closing out
the sprint with documentation, the orchestration review gate, and a final
checkpoint.

DONE (Sixth increment): Task 6 — Add activity.
`AddActivityScreen` at `/add` is a minimal form (title, category dropdown,
date + start time pickers, optional end time via a switch, optional notes).
Save validates, builds an `Activity` with a timestamp-based id, persists via
`ActivityRepository.insert`, then invalidates the dashboard summary and the
activity day/month providers so today + calendar refresh automatically.
Reachable from a new quick-add icon on the dashboard date header (PRD §4: record
in as few actions as possible). Widget tests drive the full flow through the
real router + in-memory DB (quick-add lands on today and persists; validation
blocks empty titles without persisting).

## Next Task
Sprint 1 wrap-up. Run the full orchestration validation/review gate
(`docs/AI_REVIEW.md`) over the six committed increments, close out the sprint
checkpoint, and start Phase 2 (or the next approved roadmap item). Phase 2
will add specialized modules (workout/study/finance/nutrition/habits) wired to
the Activity entity via `referenceId`/`referenceType`.

## Orchestrator Review — Round 2 Fixes (COMPLETE)
Second round of orchestrator review fixes applied and verified. Sprint 1 must NOT
start until this section is reviewed and approved.

### Round 2 — Fixes Applied
1. [x] TASK DISCOVERY — Structured parser understands roadmap structure (## Phase N → ordered tasks); returns tasks with PhaseNumber + Number; Get-PhaseTasks helper; only counts list-item bullets (not narrative/prose); skips verbose bullets (>140 chars)
2. [x] VALIDATION BUILD CHECK — Replaced duplicate `dart analyze lib/` with real `flutter build bundle` (a valid Flutter compile check needing no mobile SDK). Updated run-task.ps1, validate.ps1, workflow.yaml, docs (AI_WORKFLOW.md, AI_REVIEW.md, developer.md)
3. [x] SELF-TEST — Expanded to 15 tests: roadmap ordering (TEST 1), Phase 1 - Daily Core 6-task resolution (TEST 1b), completed-task skipping + narrative false-match prevention (TEST 1c), validation flow + real Build stage assertion (TEST 3), Get-NextTask end-to-end (TEST 3b), review parsing (TEST 4), retry flow (TEST 5), human-decision hard stop (TEST 6), next-task progression (TEST 7), safety limits (TEST 8), OpenCode availability (TEST 9), report generation (TEST 10)
4. [x] SAFETY — All limits unchanged: MaxRetries=3/stage, MaxTasksPerRun=10, MaxTotalRetries=50, MaxConsecutiveFailures=3, human-decision hard stop, critical-blocker hard stop, never-commit-unreviewed-work
5. [x] NO SPRINT 1 WORK — No product code touched; stashed Sprint 1 work preserved

## Database Schema v2 (COMPLETED)
`lib/core/database/database.dart` upgraded to schemaVersion 2 under the
explicitly-authorized DB debt fix (nullable fields + foreign-key declarations
per `docs/DATABASE.md`):

- `Schedules.location`, `Schedules.notes` now nullable
- `Activities.scheduleId` nullable with FK → `Schedules(id)`; `endTime`,
  `referenceId`, `referenceType`, `notes` nullable
- `HabitLogs.habitId` FK → Habits; `WorkoutPlanExercises` FKs; `WorkoutSessions`
  FKs + nullable endTime/durationSeconds/notes/weight; `StudySessions`
  nullable fields + FK; `Transactions.description`, `Meals.notes`,
  `Foods`/`WorkoutPlans`/`Exercises` descriptions nullable + FKs
- Migration: `from < 2` → drop all tables + `createAll()` (safe pre-release,
  no user data exists yet)
- New query helpers: day/range queries for activities and transactions
  (UTC-normalized local-day boundaries), `hasActivityForSchedule`
  (idempotent recurrence), `setActivityStatus`, `getSchedulesByDay`,
  `getActiveSchedules`, `getScheduleById`, `getActivityById`
- `databaseProvider` (Riverpod, closes DB on dispose) + `inMemoryDatabaseOverride()`
  for tests

## Sprint 1 — Current Task Status
- [x] 1. Today dashboard — DONE (committed)
- [x] 2. Recurring schedule — DONE (committed)
- [x] 3. Activity model — DONE (committed)
- [x] 4. Activity completion — DONE (committed)
- [x] 5. Calendar/history — DONE (committed)
- [x] 6. Add activity — DONE (committed)
- Phase 1 (Daily Core) — COMPLETE; sprint closing in progress

## Verification Results (Task 6 increment)
- `dart analyze lib/ test/`: No issues found
- `dart format --output=none lib/ test/`: clean
- `flutter test`: All 50 tests passed (+50)
- `flutter build bundle`: exit 0

## Known Issues / Decisions Pending
- Flutter SDK has compatibility issues with Dart SDK 3.13.2 causing `dart test` to include framework errors (framework-level, not code-level). `flutter test` passes with +4: All tests passed!
- `dart compile kernel` requires Flutter Dart SDK (dart:ui not available on standalone Dart VM — expected behavior)
- Database recurrence strategy should be finalized before implementing recurring schedule logic.
- Activity generation/occurrence strategy should be finalized before implementing schedule-to-activity behavior.
- Supabase/cloud sync is intentionally deferred.
- AI features are intentionally deferred.

## Recovery Instructions
If an agent/session stops unexpectedly:
1. Read this file.
2. Run `git status`.
3. Inspect the current diff and relevant files.
4. Continue the first incomplete checklist item.
5. Update this file after meaningful progress.
6. Commit only when the increment is stable.

## Last Updated
2026-09-07 (Sprint 1 increment — Task 6 Add activity committed; analyze clean, tests 50/50, build bundle exit 0; Phase 1 Daily Core complete)
