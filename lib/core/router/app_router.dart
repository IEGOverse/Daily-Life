import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_life/features/activities/calendar_history_screen.dart';
import 'package:daily_life/features/dashboard/dashboard_screen.dart';
import 'package:daily_life/features/schedule/schedule_screen.dart';
import 'package:daily_life/features/add/add_screen.dart';
import 'package:daily_life/features/insights/insights_screen.dart';
import 'package:daily_life/features/workout/add_exercise_screen.dart';
import 'package:daily_life/features/workout/workout_exercise_detail_screen.dart';
import 'package:daily_life/features/workout/add_workout_plan_screen.dart';
import 'package:daily_life/features/workout/workout_plan_detail_screen.dart';
import 'package:daily_life/features/workout/workout_plans_screen.dart';
import 'package:daily_life/features/workout/workout_session_detail_screen.dart';
import 'package:daily_life/features/workout/workout_sessions_screen.dart';
import 'package:daily_life/features/workout/workout_set_logging_screen.dart';
import 'package:daily_life/features/workout/workout_history_screen.dart';
import 'package:daily_life/features/workout/workout_screen.dart';
import 'package:daily_life/features/study/study_screen.dart';
import 'package:daily_life/features/finance/finance_screen.dart';
import 'package:daily_life/features/nutrition/nutrition_screen.dart';
import 'package:daily_life/features/habits/habits_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/today',
    routes: [
      GoRoute(
        path: '/today',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarHistoryScreen(),
      ),
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => const AddActivityScreen(),
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: '/workout',
        builder: (context, state) => const WorkoutScreen(),
        routes: [
          GoRoute(
            path: 'exercise/:exerciseId',
            builder: (context, state) => WorkoutExerciseDetailScreen(
              exerciseId: state.pathParameters['exerciseId']!,
            ),
          ),
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddExerciseScreen(),
          ),
          GoRoute(
            path: 'plans',
            builder: (context, state) => const WorkoutPlansScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddWorkoutPlanScreen(),
              ),
              GoRoute(
                path: ':planId',
                builder: (context, state) => WorkoutPlanDetailScreen(
                  planId: state.pathParameters['planId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'sessions',
            builder: (context, state) => const WorkoutSessionsScreen(),
            routes: [
              GoRoute(
                path: ':sessionId',
                builder: (context, state) => WorkoutSessionDetailScreen(
                  sessionId: state.pathParameters['sessionId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'sets',
                    builder: (context, state) => WorkoutSetLoggingScreen(
                      sessionId: state.pathParameters['sessionId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const WorkoutHistoryScreen(),
          ),
        ],
      ),
      GoRoute(path: '/study', builder: (context, state) => const StudyScreen()),
      GoRoute(
        path: '/finance',
        builder: (context, state) => const FinanceScreen(),
      ),
      GoRoute(
        path: '/nutrition',
        builder: (context, state) => const NutritionScreen(),
      ),
      GoRoute(
        path: '/habits',
        builder: (context, state) => const HabitsScreen(),
      ),
    ],
  );
});
