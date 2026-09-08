# Daily Life — Project Progress

> This file is the recovery/checkpoint state for AI coding agents.
> The repository, Git history, and this file are authoritative. Do not rely on previous chat memory.

## Current Phase
Phase 7 — Smart Features (IN PROGRESS — implementation complete, checkpoint in progress)

## Current Sprint
Sprint 7 — Smart Features (IN PROGRESS)

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
- [x] Phase 7 — Smart Features (notifications, meal recommendations, local personal insights; validation; docs; checkpoint) — implemented, validation passed

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
- `flutter test`: 130 tests pass (110 prior + 20 Phase 7: reminders, recommendations, insight generator)
- `flutter build bundle`: exit 0
- `flutter build apk --debug`: exit 0
- `build_runner`: generates successfully

## Current Task
Phase 7 — Smart Features fully implemented and validated; checkpoint commit pending.

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

## Phase 6 — Habits & Analytics Status
COMPLETE — custom habits, daily logs, streaks, a transparent daily score, time
analytics, and a cross-module insights dashboard delivered and validated.

- Domain models: `Habit`, `HabitLog`, `HabitWithStatus`, `DailyScore`,
  `TimeAnalytics`, `WeeklySummary`
- HabitRepository: CRUD + DERIVED streaks (current/best from logs), toggle
  today's completion; habits are independent recurring behaviors (not tied to
  the activity/schedule bridge)
- InsightsRepository: derives EVERYTHING from existing authoritative records
  (activities, study sessions, workout sessions, transactions, meals, habit
  logs); no analytics rows stored, no data duplicated
- Daily Score (transparent indicator): documented scoring rule in DATABASE.md §4 —
  taskScore(50) + habitScore(50); never based on body appearance/weight/
  calories/restrictive targets; "no data" when nothing planned
- Database: added habits/habit_logs CRUD + `getStudySessionsForRange`,
  `getWorkoutSessionsForRange`, `getMealsForRange`, habit log range queries
  (no schema change)
- UI: HabitsScreen (toggle today, streak display, add/delete habit dialog,
  loading/empty states); InsightsScreen (Today's score with transparent
  breakdown, This week summary, Time distribution, module links)
- Tests: habit CRUD, toggle, streak math (consecutive/gap/alive-after-today/
  best streak), DailyScore math, derived daily score, weekly summary +
  time analytics from records, empty states, both screen renders

## Phase 2 — Workout Status
COMPLETE — all five approved tasks delivered and validated.

## Phase 3 — Study Status
- [x] Task 1 — Study sessions (CRUD screen + repository — COMPLETE)
- [x] Task 2 — Topics
- [x] Task 3 — Notes
- [x] Task 4 — History
- [x] Task 5 — Basic study statistics

## Phase 7 — Smart Features Status
COMPLETE — configurable local notifications, variety-aware meal
recommendations, and locally-generated personal insights delivered and
validated; checkpoint commit in progress.

- Notifications: `NotificationRules` table (schema v3, additive migration),
  `NotificationRulesRepository` (seeded defaults), `ReminderScheduler`
  (pure `buildReminders` decision logic: N-min-before-activity one-shots +
  fixed daily habit/finance reminders; id 9100/9200 reserved for daily),
  `NotificationService` (flutter_local_notifications ^22 + timezone +
  flutter_timezone; guarded no-op off-Android/on tests), `/reminders`
  screen (activity lead dropdown + daily time pickers, persisted),
  dashboard settings → reminders, manifest permissions + boot receivers,
  Android core-library desugaring enabled in app build.gradle.kts
- Meal recommendations: transparent local engine (meal type by clock,
  recent-food variety weighting, soft calorie estimate), recent-food
  window query, suggestions card on Nutrition screen labeled as estimates
- Local personal insights: `InsightGenerator` compares current vs previous
  `WeeklySummary` (study time, workouts, tasks, habits, daily score,
  income; typed directions, explainable), "Personal insights" card on
  Insights screen noting nothing leaves the device; no AI service used
- Tests: reminder scheduler+rules, recommendation engine + recent-food
  window, insight generator, notification_rules table persistence,
  schema version updated to 3, insights screen empty-state now scrolls

## Known Issues / Decisions Pending
- Recurrence/occurrence strategy not finalized (Phase 3+).
- Phase 7 processed entirely on-device; no external AI/cloud usage.
- Daily Score rule documented in DATABASE.md §4 (transparent; taskScore + habitScore).
- Next roadmap checkpoint: Phase 8 — Portfolio / Production (refactoring,
  automated tests hardening, performance checks, security review, README,
  architecture documentation, screenshots, demo video, release APK).

## Recovery Instructions
If an agent/session stops unexpectedly:
1. Read this file.
2. Run `git status`.
3. Inspect the current diff and relevant files.
4. Continue the first incomplete checklist item.
5. Update this file after meaningful progress.
6. Commit only when the increment is stable.

## Last Updated
2026-09-08 Phase 7 Smart Features complete (notifications, meal
recommendations, local personal insights; validation passed; checkpoint in progress).