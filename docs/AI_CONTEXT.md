# Daily Life — AI Context Summary

**Purpose**: Personal-first mobile app (Flutter/Dart) helping one user plan, record, and analyze daily life (Activus; package `daily_life`).

**Architecture**:
- Flutter 3.47.2 / Dart 3.13.2
- Riverpod 2.6.1 for state management
- GoRouter (`StatefulShellRoute.indexedStack` + custom bottom nav) for navigation
- Drift 2.34.4 for SQLite (code-generated)
- flutter_local_notifications ^22.3.0 / timezone ^0.11.1 / flutter_timezone ^5.1.0
- Feature-based project structure under `lib/features/`

**Current Phase**: Phase 8 — UI/UX Polish (IMPLEMENTED + VALIDATED; checkpoint commit in progress)
**Current Sprint**: Sprint 8 — UI Polish (COMPLETE)
**Status**: Dark-first Activus design system + full interface polish implemented; 135 tests pass; `flutter build bundle` and `flutter build apk --debug` exit 0; docs updated.

**Completed Milestones**:
- Sprint 1 (Phase 1 — Daily Core): 6/6 tasks. Dashboard, recurring schedule, activity model, completion, calendar/history, add activity.
- Sprint 2 (Phase 2 — Workout): Exercise library, plans, sessions, set logging, history.
- Sprint 3 (Phase 3 — Study): Sessions, topics, notes, history, statistics.
- Phase 4 (Finance): income/expense, categories, derived balance, history, stats.
- Phase 5 (Nutrition): foods, meals, portion-driven derived daily summary, add-meal flow.
- Phase 6 (Habits & Analytics): habits, streaks, transparent Daily Score, time analytics, cross-module insights dashboard.
- Phase 7 (Smart Features — prior session):
  - Notifications: DB schema v3 `notification_rules` (additive migration), `ReminderScheduler` pure `buildReminders` (activity N-min lead + daily habit/finance), `NotificationService`, `/reminders` screen, dashboard link, Android manifest permissions/receivers, core-library desugaring in app build.gradle.kts.
  - Meal recommendations: local `MealRecommendationEngine` (clock-based meal type, recent-food variety ranking, soft kcal estimate), suggestions card on Nutrition screen (labeled estimates, not medical advice).
  - Personal insights: `InsightGenerator` comparing current vs previous `WeeklySummary` (study/workouts/tasks/habits/score/income; typed directions; explainable). "Generated locally — nothing leaves this device."
- Phase 8 (UI/UX Polish — this session):
  - Theme: `ActivusColors` tokens + dark-first themes; dark mode default (`themeMode: ThemeMode.dark`).
  - Navigation: `StatefulShellRoute.indexedStack` (Today/Schedule/Insights/More branches, per-branch navigators) + custom bottom nav in `lib/core/navigation/navigation_shell.dart` (center circular "+" → `/add`; active=primary blue, inactive=gray). All prior routes preserved.
  - Dashboard: greeting/date header (calendar + notification affordances), circular Daily Progress gauge, NOW, NEXT UP, compact timeline with status pills + done/skip/reset, compact Finance/Study/Nutrition summaries (`todayStudyMinutesProvider`, `todayNutritionSummaryProvider`).
  - Screens: Schedule (day strip + compact rows), Finance (balance card + working All/Income/Expense segment filter + compact rows), Nutrition (kcal gauge + compact meals + Phase 7 suggestions), Habits (compact toggle rows + streaks), Insights (Overview/Analytics/Trends tabs + transparent daily score), More (Profile/Settings→`/reminders`/Data & Sync/Theme/Help/About dialog).

**Database schema**: v3 (added `notification_rules`).

**Current Task**: Phase 8 complete; create checkpoint commit and push, then next roadmap checkpoint (Phase 9 — Portfolio/Production).

**Important Architectural Decisions**:
- Write-side builds local `DateTime` then `.toUtc()` to preserve wall-clock (Drift reader returns local).
- Single-flight seed lock prevents concurrent first-launch inserts.
- Riverpod `overrideWithValue` works only on providers; `ref.invalidate(family)` invalidates all instances.
- No `uuid`/`intl` packages; IDs generated with timestamps + slugs.
- Daily Score is a transparent indicator: `score = round(taskScore×50 + habitScore×50)`; never a judgment or based on body/calories (DATABASE.md §4).
- All insights/recommendations/reminders computed LOCALLY; no external AI or cloud services (PRD §14–§15).
- NotificationService guards all platform calls off-Android (tests/no-op hosts).

**Important Constraints**:
- Offline-first behavior for core personal data.
- No paid external AI; errors are honest/no busy paths; Supabase/cloud sync deferred.

**Latest Checkpoint**: Phase 8 implementation complete; commit + push pending.

**Validation Status**:
- `dart analyze lib/ test/`: No issues found
- `dart format --output=none lib test`: clean
- `flutter test`: 135 tests pass (added Phase 8 more-screen/bottom-nav/finance-filter tests)
- `flutter build bundle`: exit 0
- `flutter build apk --debug`: exit 0

**Known Blockers / Debt**:
- Plain `flutter test` may print Flutter framework warnings; all code-level tests pass.
- Recurrence/occurrence strategy not finalized (Phase 3+).
- `flutter_timezone` plugin applies KGP (build warning only; future Flutter may require upgrade).

**Instructions for Resuming Work**:
1. Read `docs/AI_CONTEXT.md` first.
2. Read `AGENTS.md` for autonomous development rules.
3. Read `docs/PROGRESS.md` for current sprint state.
4. Read `docs/ROADMAP.md` for phase overview.
5. Inspect `git status` and relevant source files.
6. Continue first incomplete checklist item in `docs/PROGRESS.md`.
7. Update `docs/PROGRESS.md` after meaningful progress.
8. Commit only when increment is stable.