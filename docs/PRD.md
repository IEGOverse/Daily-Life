# Daily Life — Product Requirements Document

## 1. Product Vision
Daily Life is a personal life management application that helps the user plan, execute, record, and understand daily activities in one place.

The application should answer:
"What should I do today, what have I actually done, what did I learn, how did I spend my time, what did I eat, and where did my money go?"

## 2. Product Positioning
- Personal-first
- Built primarily for one user
- Production-quality engineering
- Portfolio-worthy documentation
- Designed so it can be expanded to public use later

## 3. Core Modules
### P0 — Core
- Today dashboard
- Schedule
- Activity tracking
- Activity completion
- Calendar/history

### P1 — Personal Modules
- Workout
- Study journal
- Finance
- Nutrition
- Habits

### P2 — Analytics
- Productivity score
- Time analytics
- Study analytics
- Finance analytics
- Workout history/statistics

### P3 — Smart Features
- Notifications
- Meal recommendations
- AI-generated personal insights
- Optional cloud synchronization

## 4. Core UX Principle
Recording information should take as few actions as possible.

Examples:
- Expense: Add → amount → category → save
- Activity: Add → name → time → save
- Meal: Add → food → portion → save

## 5. Daily Schedule
The initial recurring university schedule is:

Monday & Wednesday:
- 10:10–11:30 — Business Process Reengineering
- 13:10–14:30 — Data Mining and Warehousing
- 14:40–16:00 — Research Method & Scientific Writing

Tuesday & Thursday:
- 07:10–08:30 — System Analysis and Design
- 13:10–14:30 — Front-End Web Development
- 14:40–16:00 — Information System Security

Thursday only:
- 10:10–11:30 — Kuliah Umum

Friday:
- 13:10–15:00 — Indonesian Civics
- 15:10–17:00 — Youth and the World

## 6. Activity Model
Activity is the central entry point for scheduled actions.

Activity states:
- Scheduled
- Upcoming
- In Progress
- Completed
- Skipped

Specialized activities can open:
- Workout session
- Study session
- Finance action
- Meal/nutrition action
- Habit action

## 7. Workout Requirements
- Workout plans
- Exercise library
- Exercise instructions
- Sets
- Reps
- Weight
- Rest time
- Workout completion
- Workout history

The schedule should be able to open the relevant workout plan, e.g. "Leg Day", and show its exercises.

## 8. Study Requirements
A study session can record:
- Subject
- Start/end time
- Duration
- Topics learned
- Notes
- Self-rated understanding

Study history must be searchable by subject/date.

## 9. Finance Requirements
Support:
- Income
- Expense
- Categories
- Amount
- Description
- Date
- Transaction history
- Real-time totals

Balance should be derived from transactions:
Balance = total income - total expenses

## 10. Nutrition Requirements
Support:
- Food database
- Serving/portion
- Meal records
- Estimated calories
- Protein
- Carbohydrates
- Fat
- Daily nutrition summary
- Meal recommendations

Nutrition values are estimates and should not be presented as medical-grade measurements.

## 11. Habit Requirements
Support:
- Custom habits
- Frequency
- Target
- Daily logs
- Completion
- Streak/history

## 12. Analytics
The system should derive:
- Daily/weekly completion
- Time spent by category
- Study time
- Workout frequency
- Finance totals
- Nutrition summaries
- Habit consistency

## 13. Notifications
Examples:
- Upcoming workout
- Study session
- Finance recording reminder
- Habit reminder

Notifications must be configurable.

## 14. AI Insights
AI is a later feature. The app should first aggregate and summarize data locally/server-side, then send only the minimum relevant summary to an AI service.

Example insight:
"Your study time increased this week compared with last week."

AI must not be treated as a medical or financial authority.

## 15. Privacy
The app contains personal activity, learning, nutrition, and financial data. Minimize data collection, protect credentials, and keep cloud sync optional until needed.

## 16. MVP Success Criteria
The first usable release must:
- Show today's schedule
- Generate recurring university activities
- Add/edit activities
- Mark activities complete
- Store history
- Work after the app is restarted
- Provide a clean, consistent mobile UI
- Pass relevant tests and static analysis
