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
Sprint 1 in progress.

DONE (Fifth increment, committed): Task 5 — Calendar/history.
`CalendarHistoryScreen` (`/calendar`) shows a month calendar grid (weekday
headers, today outlined, selected day filled, per-day activity-count dots;
Prev/Next/Today controls) and the selected day's activity list with the same
Done/Skip/Reset actions as the dashboard. Initial month/day uses `clockProvider`
(for testability). Activity counts come from `activitiesForMonthProvider`;
the day list from `activitiesForDayProvider`. Reachable from the dashboard's
date-header calendar icon. Uses a lightweight in-house month grid (no new
third-party package).

## Next Task
Task 6 — Add activity: a form to manually create a one-off Activity (title,
category, date, start/end time, notes) reusing `ActivityRepository.insert`.
Wired to the existing `/add` route and Add screen placeholder. This completes
Phase 1 (Sprint 1). Decisions: whether the Add screen hosts only activities now
(finance/meals/etc. come in later phases) — keep it activity-only and modular.
After Task 6, run the full orchestration validation/review gate and update
checkpoint before closing the sprint.

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
- [ ] 6. Add activity

## Verification Results (Task 5 increment)
- `dart analyze lib/ test/`: No issues found
- `dart format --output=none lib/ test/`: clean
- `flutter test`: All 48 tests passed (+48)
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
2026-09-07 (Sprint 1 increment — Task 5 Calendar/history committed; analyze clean, tests 48/48, build bundle exit 0)
