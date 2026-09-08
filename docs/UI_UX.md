ACTIVUS
Personal Life Operating System

Design philosophy:
PLAN → DO → RECORD → ANALYZE → IMPROVE

# Activus — UI/UX Specification v0.2

## Design Direction
Minimalist, modern, calm, cozy, data-driven.

Principles:
- Important information visible at a glance.
- Minimal steps to record information.
- Consistent cards and components.
- Dark-first theme (light theme supported).
- Category accents without overwhelming the interface.

## Visual Tokens (v0.2)
- Background: `#0A0E1A` (dark navy)
- Surface: `#131A2C`; surface alt: `#1A2236`
- Borders: `#232B40`
- Primary (blue): `#3B82F6`
- Success / income: `#22C55E`
- Danger / expense: `#EF4444`
- Warning: `#F59E0B`
- Category accents: `#8B5CF6` (violet), `#06B6D4` (cyan)
- Text: primary/secondary/tertiary tuned for dark contrast
- Cards: 16 px radius, ~1 px borders, no elevation
- Icon containers: 40x40 rounded, tinted with category color
- Spacing: compact (8–16 px), dense layout

## Primary Navigation
- Today
- Schedule
- + (Add — center, circular, Primary Blue, elevated; opens quick-add)
- Insights
- More

## Today Screen
Sections:
1. Greeting/date header with calendar + notification affordances
2. Daily progress (circular gauge + Done / In progress / Remaining)
3. NOW / current activity
4. NEXT UP
5. Today's timeline (compact rows: category icon, time, title, status pill, actions)
6. Compact nutrition/finance/study summaries (not oversized)

## Activity Card
Common fields:
- Icon
- Time
- Title
- Subtitle/detail
- Status
- Navigation affordance

Activity cards should open the appropriate specialized module.

## Workout Screen
Show:
- Workout name
- Date
- Exercise list
- Sets/reps
- Weight logging
- Completion state
- Complete Workout action

## Study Screen
Show:
- Subject
- Timer/session duration
- Topics
- Notes
- Understanding rating
- Save session

## Finance Screen
Show:
- Current balance
- Income / expenses (segment filter: All / Income / Expense)
- Recent transactions (compact rows, edit/delete)
- Fast add transaction action

## Nutrition Screen
Show:
- Daily calories vs target (circular gauge)
- Protein/carbs/fat legend
- Meals (compact rows)
- Add meal
- Meal recommendations (labeled as estimates)

Nutrition values should be labeled as estimates when appropriate.

## Insights Screen
Show (segmented: Overview / Analytics / Trends):
- Today's daily score (transparent gauge with task/habit split)
- Weekly summary
- Time distribution
- Study
- Workout
- Finance
- Nutrition
- Habits
- Personal insights

## More Screen
Compact rows grouped in sections:
- Profile
- Settings (Notifications & reminders)
- Data & Sync (local only — no cloud)
- Theme (dark default)
- Help & Support
- About Activus (version + privacy note)

## Reusable Components
- AppCard (16 px radius, bordered, no elevation)
- AppButton
- ActivityCard
- TimelineItem
- StatCard
- StatusPill
- CategoryIconContainer (40x40)
- CompactRow
- ProgressCard
- CategoryChip
- SectionHeader
- EmptyState
- LoadingState
- ErrorState

## Accessibility
- Sufficient contrast
- Touch targets large enough for comfortable use
- Do not rely on color alone to communicate status
- Support dynamic text sizing where practical

## Interaction
Use subtle feedback for:
- Completing activities
- Saving study sessions
- Recording transactions
- Completing workouts

Avoid excessive animation.
