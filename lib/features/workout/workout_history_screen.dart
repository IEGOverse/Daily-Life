import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/workout_history.dart';
import 'workout_providers.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Olahraga')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Gagal memuat riwayat olahraga.')),
        data: (summary) => _HistoryContent(summary: summary),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  final WorkoutHistory summary;

  const _HistoryContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.completedSessions.isEmpty) {
      return const Center(
        child: Text('Selesaikan olahraga untuk membangun riwayat.'),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _Stat(label: 'Olahraga', value: '${summary.sessionCount}'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Stat(
                label: 'Menit',
                value: '${summary.totalDurationSeconds ~/ 60}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Stat(label: 'Set', value: '${summary.completedSets}'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Olahraga yang selesai',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final session in summary.completedSessions)
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.check)),
              title: Text(session.plan?.name ?? 'Sesi olahraga'),
              subtitle: Text(
                '${session.date.year}-${session.date.month.toString().padLeft(2, '0')}-${session.date.day.toString().padLeft(2, '0')}  •  ${session.durationSeconds ?? 0}s',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/workout/sessions/${session.id}'),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
