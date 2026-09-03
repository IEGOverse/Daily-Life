# Daily Life — Architecture

## 1. Architectural Goals
- Feature modularity
- Offline-first core behavior
- Testability
- Clear separation of concerns
- Easy AI-assisted development
- Simple enough for a solo project

## 2. Proposed Stack
- Flutter
- Dart
- Riverpod for state management
- GoRouter for navigation
- SQLite for local persistence
- Supabase later for optional authentication/cloud sync
- Local notification package later
- Chart package later
- AI API later

## 3. Project Structure

lib/
  core/
    database/
    router/
    theme/
    utils/
    widgets/
  features/
    dashboard/
    schedule/
    activities/
    workout/
    study/
    finance/
    nutrition/
    habits/
    insights/
  main.dart

Within a mature feature, prefer:
feature/
  data/
  domain/
  presentation/

## 4. Layer Responsibilities
Presentation:
- Screens
- Widgets
- UI state

Domain:
- Entities
- Business rules
- Use cases where useful

Data:
- Models
- Local data sources
- Remote data sources
- Repositories

Core:
- Shared infrastructure and reusable components

## 5. Data Flow

UI
→ Riverpod state/provider
→ Use case/business logic
→ Repository
→ Local/remote data source
→ Database/API

Core personal data should be usable from local storage without an internet connection.

## 6. Activity Integration
Activity is the bridge between the schedule and specialized modules.

Example:
Schedule
→ Activity(category=workout, reference=WorkoutSession)
→ Workout screen

Study, finance, nutrition, and habits follow the same principle where appropriate.

## 7. Real-Time Updates
Derived dashboard values should be calculated from source records or reactive state.

For finance:
Balance = SUM(income) - SUM(expense)

Avoid storing derived totals as the authoritative source.

## 8. Offline-First Strategy
Phase 1:
- SQLite is authoritative for local use.

Future:
- Add synchronization layer
- Sync to Supabase
- Handle conflicts explicitly if multi-device support is ever added

## 9. Navigation
Primary destinations:
- Today
- Schedule
- Add
- Insights

Secondary:
- Profile
- Settings
- Module-specific history/detail screens

## 10. Testing Strategy
Unit tests:
- Calculations
- Repository logic
- Productivity rules
- Nutrition calculations

Widget tests:
- Important screens
- Empty/loading/error states

Integration tests later:
- Create activity → complete → history
- Create transaction → dashboard total updates
- Create study session → history/analytics update
