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

DONE (First increment, committed): Task 1 — Today dashboard. The dashboard
(`lib/features/dashboard/`) now renders live data via drift: greeting +
calendar header, daily progress card (completed/total + progress bar),
NOW card, NEXT UP card, "Today's Timeline" (ordered ActivityCards),
and a Finance strip (balance/income/spent from the day's transactions).
Loading/empty/error/refresh states are handled. Backed by `clockProvider`
(overridable in tests) and `dashboardSummaryProvider` (FutureProvider).
New files: `data/dashboard_repository.dart`, `domain/dashboard_summary.dart`,
`domain/today_activity.dart`, `dashboard_providers.dart`,
`core/database/database_provider.dart`.

## Next Task
Task 2 — Recurring schedule: seed the PRD §5 initial university schedule;
generate today's activities from weekly schedules (idempotent via
`hasActivityForSchedule`); build the Schedule screen to view the week.
Requires reading the rest of PRD §5 and finalizing the recurrence strategy.

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
- [ ] 2. Recurring schedule
- [ ] 3. Activity model
- [ ] 4. Activity completion
- [ ] 5. Calendar/history
- [ ] 6. Add activity

## Verification Results (Task 1 increment)
- `dart analyze lib/ test/`: No issues found
- `dart format --output=none lib/ test/`: clean
- `flutter test`: All 23 tests passed (+23)
- `flutter build bundle`: exit 0, `build/flutter_assets` present

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
2026-09-07 (Sprint 1 increment — Task 1 Today dashboard committed; analyze clean, tests 23/23, build bundle exit 0)
