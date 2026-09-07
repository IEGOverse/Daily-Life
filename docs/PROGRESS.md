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

DONE (Second increment, committed): Task 2 — Recurring schedule.
`lib/features/schedule/` now contains the schedule feature. `ScheduleSeeder`
holds the 15 PRD §5 classes (Mon/Wed ×3, Tue/Thu ×3, Thu-only Kuliah Umum,
Fri ×2). `generateActivitiesForDay` creates activities from active weekly
schedules idempotently (`hasActivityForSchedule`). `ensureSeededAndGenerated`
runs once at app startup (via `useSeeding`/`_seedAndGenerateFutureProvider`)
seeding schedules if empty and generating the current week's activities.
`ScheduleScreen` shows a Mon–Sun chip selector (current weekday highlighted)
and the day's class list with time ranges; empty state for weekends.

## Next Task
Task 3 — Activity model: refine the `Activities` row semantics (status
lifecycle, schedule linkage, manual creation), and surface activities from the
Schedule screen. Expect to add a dedicated activity feature layer (domain
models already exist under `dashboard/`); may promote `TodayActivity` usage
across both dashboard and schedule features. Revisit `ActivityStatus` mapping
once completion (Task 4) and manual add (Task 6) are wired.

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
- [ ] 3. Activity model
- [ ] 4. Activity completion
- [ ] 5. Calendar/history
- [ ] 6. Add activity

## Verification Results (Task 2 increment)
- `dart analyze lib/ test/`: No issues found
- `dart format --output=none lib/ test/`: clean
- `flutter test`: All 34 tests passed (+34)
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
2026-09-07 (Sprint 1 increment — Task 2 Recurring schedule committed; analyze clean, tests 34/34, build bundle exit 0)
