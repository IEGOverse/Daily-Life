## Sprint Report: Sprint 1 — Phase 1 Daily Core

**Phase**: Phase 1 — Daily Core
**Start Date**: 2026-09-07
**End Date**: 2026-09-08
**Status**: COMPLETED

### Tasks Completed
- [x] 1. Today dashboard
- [x] 2. Recurring schedule
- [x] 3. Activity model
- [x] 4. Activity completion
- [x] 5. Calendar/history
- [x] 6. Add activity
- [x] Database schema v2 (nullable fields + FKs) — authorized DB debt fix
- [x] Schedule seeding (PRD §5 university classes, 15 schedules) + idempotent weekly generation

### Tasks Remaining
- (none)

### Validation Summary
- Total tasks: 6
- Passed: 6
- Failed: 0
- Retries (validation/fix): 0
- Review retries: 2 (both CHANGES_REQUIRED rounds fixed and re-reviewed to APPROVED)

### Issues Encountered
1. HIGH — Generated activities stored the schedule wall-clock as a raw `DateTime.utc`
   value; drift reads timestamps back as local, shifting displayed times by the UTC
   offset and mis-placing calendar days in negative-offset zones. Fixed: store the
   UTC instant of a local DateTime (`DateTime(y,m,d,h,min).toUtc()`), matching the
   query-side `_localStartOfDay` and the quick-add path.
2. HIGH — First-launch race: `useSeeding` and the initial `/today` route both seeded
   on the same frame, double-inserting schedules → `UNIQUE constraint failed`.
   Fixed: single-flight `ensureSeededAndGenerated` lock.
3. MEDIUM — First-launch seeding never invalidated cached providers (empty dashboard
   until manual refresh). Fixed: seed future invalidates `dashboardSummaryProvider`
   and `activitiesForDayProvider` when done.
4. LOW — Current-week generation was one-shot at launch; later weeks were empty.
   Fixed: idempotent `ensureCurrentWeekActivities` on the dashboard/day/month read
   paths. Also: calendar "today" now watches `clockProvider`.

### Notes
- Drift 2.34.4 confirmed (mapping.dart:120,182): writer stores the absolute
  millisecond instant; reader returns a local DateTime. Date/time handling is now
  consistent end to end (write `.toUtc()` ⟷ query local-midnight UTC instants).
- Final state: `dart analyze` clean, 53/53 tests pass, `flutter build bundle` exit 0,
  Stage-5 code review APPROVED.

### Next Sprint
- Phase 2 — Workout: Exercise library, Workout plans, Workout sessions, Set logging,
  History (schema tables and the Activity `referenceId`/`referenceType` linkage
  already exist).