# Daily Life — Project Progress

> This file is the recovery/checkpoint state for AI coding agents.
> The repository, Git history, and this file are authoritative. Do not rely on previous chat memory.

## Current Phase
Phase 6 — Habits & Analytics (next up)

## Current Sprint
Sprint 5 — Nutrition (COMPLETE)

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
- [x] Phase 1 Task 2 — Recurring schedule (university schedule seeded; weekly activity generation idempotent; Schedule screen with day selector)
- [x] Phase 1 Task 3 — Activity model (shared central model, status lifecycle, repository; dashboard/schedule rewire over it)
- [x] Phase 1 Task 4 — Activity completion (done/skip/reset inline actions on dashboard timeline; auto-refresh; persisted)
- [x] Phase 1 Task 5 — Calendar/history (month calendar grid + per-day activity list with completion actions; routed at `/calendar`)
- [x] Phase 1 Task 6 — Add activity (quick-add form; saves via `ActivityRepository.insert`; `/add` route + dashboard quick-add icon) — Phase 1 (Sprint 1) COMPLETE
- [x] Phase 2 Task 1 — Exercise library (`Exercise` domain, `ExerciseRepository`, lazy single-flight seed of 15 standard exercises with instructions, `/workout` library browser with muscle-group chips + search + empty state, detail screen, add form)
- [x] Phase 2 Task 2 — Workout plans (transactional plan/link repository, `/workout/plans` list/create/detail, exercise selection, default 3 sets / 10 reps / 60 s rest)
- [x] Phase 2 Task 3 — Workout sessions (session repository, start-from-plan flow, completion with duration validation, `/workout/sessions/:id` detail, history list)
- [x] Phase 2 Task 4 — Set logging (`WorkoutSetLogRepository`, concurrent-safe single-flight materialization, reps/weight editing, `/workout/sessions/:sessionId/sets` screen)
- [x] Phase 2 Task 5 — Workout history (completed-session summary, total minutes, completed-set count, chronological completed-workout list, `/workout/history`)

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
- [x] Run tests (flutter test passes)
- [x] Run build check (build_runner generates successfully)
- [x] Review implementation against project docs
- [x] Create stable Git commit
- [x] Create automation/orchestrator infrastructure
- [x] Create AI documentation (workflow, decision policy, review, reporting)
- [x] Validate all automation scripts

## Verification Results
- `dart analyze lib/ test/`: No issues found
- `dart format --output=none lib test`: clean
- `flutter test`: 92 tests pass (86 prior + 6 Finance-additions/Nutrition)
- `flutter build bundle`: exit 0
- `flutter build apk --debug`: exit 0
- `build_runner`: generates successfully

## Current Task
Phase 6 — Habits & Analytics (next approved phase; pending)

## Phase 4 — Finance Status
COMPLETE — income/expense transactions, categories, real-time derived balance,
transaction history, and basic finance statistics delivered and validated.

- Domain model: `Transaction` (type income/expense, category, amount, description, date)
- Repository: CRUD + derived statistics (balance = SUM(income) - SUM(expense))
- Database: added `getAllTransactions`, `getTransactionById`, `updateTransaction`,
  `deleteTransaction` (no schema change; balance never stored)
- UI: FinanceScreen with balance summary, income/expense totals, transaction
  history, add/edit dialog (income/expense selector, category, amount, date,
  description), delete, loading/empty states
- Tests: insert, retrieve, update, delete, income/expense/balance math (incl.
  5,000,000 - 1,500,000 = 3,500,000 example), empty state, Finance screen render

## Phase 5 — Nutrition Status
COMPLETE — food database, meal records, portion-driven daily summary, and
meal add flow delivered and validated.

- Domain models: `Food`, `Meal`, `MealFood`
- Repository: food/meal CRUD + DERIVED daily summary
  (meal macros = sum of meal_foods × food nutrition per serving)
- Database: added food/meal/meal_food CRUD + `getMealsForDay` (no schema change)
- UI: NutritionScreen with daily calories + protein/carbs/fat, meal list,
  add-meal dialog (meal type, food selection, portion), delete, empty/loading states
- Tests: food CRUD, meal + portion daily-summary math, day filtering, delete,
  empty state, Nutrition screen render

## Phase 2 — Workout Status
COMPLETE — all five approved tasks delivered and validated.

## Phase 3 — Study Status
- [x] Task 1 — Study sessions (CRUD screen + repository — COMPLETE)
- [x] Task 2 — Topics
- [x] Task 3 — Notes
- [x] Task 4 — History
- [x] Task 5 — Basic study statistics

## Known Issues / Decisions Pending
- Recurrence/occurrence strategy not finalized (Phase 3+).
- Finance (Phase 4), Nutrition (Phase 5) complete.

## Recovery Instructions
If an agent/session stops unexpectedly:
1. Read this file.
2. Run `git status`.
3. Inspect the current diff and relevant files.
4. Continue the first incomplete checklist item.
5. Update this file after meaningful progress.
6. Commit only when the increment is stable.

## Last Updated
2026-09-08 Phase 5 Nutrition complete (food db, meals, portion-derived daily summary).