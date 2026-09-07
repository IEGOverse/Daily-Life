import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/schedule/schedule_providers.dart';

void main() {
  runApp(const ProviderScope(child: DailyLifeApp()));
}

class DailyLifeApp extends ConsumerWidget {
  const DailyLifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Trigger initial schedule seeding + week activity generation once.
    useSeeding(ref);

    return MaterialApp.router(
      title: 'Daily Life',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
