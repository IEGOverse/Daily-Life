import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/workout_session.dart';
import 'workout_providers.dart';

class WorkoutSessionsScreen extends ConsumerWidget {
  const WorkoutSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(workoutSessionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesi Olahraga'),
        actions: [
          IconButton(
            tooltip: 'Riwayat olahraga',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.push('/workout/history'),
          ),
        ],
      ),
      body: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Gagal memuat sesi olahraga.')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Belum ada sesi olahraga.'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final session = items[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          session.completed ? Icons.check : Icons.play_arrow,
                        ),
                      ),
                      title: Text(session.plan?.name ?? 'Sesi olahraga'),
                      subtitle: Text(_subtitle(session)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push('/workout/sessions/${session.id}'),
                    ),
                  );
                },
              ),
      ),
    );
  }

  static String _subtitle(WorkoutSession session) {
    final status = session.completed ? 'Selesai' : 'Berlangsung';
    final duration = session.durationSeconds == null
        ? ''
        : ' • ${session.durationSeconds}s';
    return '$status$duration';
  }
}
