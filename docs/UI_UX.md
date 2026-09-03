# Daily Life — UI/UX Specification v0.1

## Design Direction
Minimalist, modern, calm, cozy, data-driven.

Principles:
- Important information visible at a glance.
- Minimal steps to record information.
- Consistent cards and components.
- Light and dark themes.
- Category accents without overwhelming the interface.

## Primary Navigation
- Today
- Schedule
- Add
- Insights

## Today Screen
Sections:
1. Greeting/date
2. Daily progress
3. NOW / current activity
4. NEXT UP
5. Today's timeline
6. Compact nutrition/finance/study summaries

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
- Balance
- Income
- Expenses
- Recent transactions
- Fast add transaction action

## Nutrition Screen
Show:
- Daily calories
- Protein/carbs/fat
- Meals
- Add meal
- Meal recommendations

Nutrition values should be labeled as estimates when appropriate.

## Insights Screen
Show:
- Weekly summary
- Time distribution
- Study
- Workout
- Finance
- Nutrition
- Habits
- Personal insights

## Reusable Components
- AppCard
- AppButton
- ActivityCard
- TimelineItem
- StatCard
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
