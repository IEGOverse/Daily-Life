# Daily Life — Database Design v0.1

## 1. Design Principles
- Store source data, derive statistics where practical.
- Use stable IDs.
- Keep module-specific data separate.
- Activity can reference specialized records.
- Timestamps should be stored consistently.
- Design for local SQLite first.

## 2. Core Tables

### schedules
- id: TEXT/UUID, PK
- title: TEXT
- type: TEXT
- day_of_week: INTEGER
- start_time: TEXT
- end_time: TEXT
- repeat_type: TEXT
- location: TEXT nullable
- notes: TEXT nullable
- is_active: INTEGER
- created_at: DATETIME

### activities
- id: TEXT/UUID, PK
- schedule_id: TEXT nullable, FK
- title: TEXT
- category: TEXT
- start_time: DATETIME
- end_time: DATETIME nullable
- status: TEXT
- reference_id: TEXT nullable
- reference_type: TEXT nullable
- notes: TEXT nullable
- created_at: DATETIME

### habits
- id: TEXT/UUID, PK
- name: TEXT
- frequency: TEXT
- target: INTEGER
- is_active: INTEGER
- created_at: DATETIME

### habit_logs
- id: TEXT/UUID, PK
- habit_id: TEXT, FK
- date: DATE
- completed: INTEGER

### exercises
- id: TEXT/UUID, PK
- name: TEXT
- muscle_group: TEXT
- description: TEXT nullable
- instructions: TEXT nullable

### workout_plans
- id: TEXT/UUID, PK
- name: TEXT
- description: TEXT nullable
- day_label: TEXT nullable

### workout_plan_exercises
- id: TEXT/UUID, PK
- workout_plan_id: TEXT, FK
- exercise_id: TEXT, FK
- sets: INTEGER
- reps: INTEGER
- rest_seconds: INTEGER nullable
- sort_order: INTEGER

### workout_sessions
- id: TEXT/UUID, PK
- workout_plan_id: TEXT, FK
- date: DATE
- start_time: DATETIME
- end_time: DATETIME nullable
- duration_seconds: INTEGER nullable
- completed: INTEGER
- notes: TEXT nullable

### workout_set_logs
- id: TEXT/UUID, PK
- workout_session_id: TEXT, FK
- exercise_id: TEXT, FK
- set_number: INTEGER
- reps: INTEGER
- weight: REAL nullable
- completed: INTEGER

### study_sessions
- id: TEXT/UUID, PK
- subject: TEXT
- date: DATE
- start_time: DATETIME
- end_time: DATETIME
- duration_seconds: INTEGER
- understanding: INTEGER nullable
- notes: TEXT nullable

### study_topics
- id: TEXT/UUID, PK
- study_session_id: TEXT, FK
- topic: TEXT

### transactions
- id: TEXT/UUID, PK
- type: TEXT  # income/expense
- category: TEXT
- amount: INTEGER
- description: TEXT nullable
- date: DATE
- created_at: DATETIME

### foods
- id: TEXT/UUID, PK
- name: TEXT
- serving_size: REAL
- serving_unit: TEXT
- calories: REAL
- protein: REAL
- carbohydrate: REAL
- fat: REAL

### meals
- id: TEXT/UUID, PK
- meal_type: TEXT
- date: DATE
- time: DATETIME
- notes: TEXT nullable

### meal_foods
- id: TEXT/UUID, PK
- meal_id: TEXT, FK
- food_id: TEXT, FK
- quantity: REAL
- unit: TEXT

## 3. Relationships

schedules 1 → many activities

workout_plans 1 → many workout_plan_exercises
exercises 1 → many workout_plan_exercises
workout_plans 1 → many workout_sessions
workout_sessions 1 → many workout_set_logs

study_sessions 1 → many study_topics

habits 1 → many habit_logs

meals 1 → many meal_foods
foods 1 → many meal_foods

## 4. Derived Values

Finance:
balance = total income - total expense

Nutrition:
meal calories/macros = sum of meal_foods × food nutrition per serving

Productivity:
derived from planned/completed activities according to a documented scoring rule.

## 5. Future Tables
Possible later additions:
- users
- sync_metadata
- notification_rules
- meal_preferences
- recommendation_history
- ai_insights
