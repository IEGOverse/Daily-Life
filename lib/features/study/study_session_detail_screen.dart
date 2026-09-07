import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'study_providers.dart';

class StudySessionDetailScreen extends ConsumerWidget {
  final String sessionId;

  const StudySessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(studySessionByIdProvider(sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Study session')),
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Failed to load session.')),
        data: (value) => value == null
            ? const Center(child: Text('Study session not found.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    value.subject,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Date: ${value.date.year}-${value.date.month}-${value.date.day}',
                  ),
                  Text('Start: ${value.startTime}'),
                  if (value.endTime != null) Text('End: ${value.endTime}'),
                  if (value.durationSeconds != null)
                    Text('Duration: ${value.durationSeconds! ~/ 60} minutes'),
                  if (value.understanding != null)
                    Text('Understanding: ${value.understanding} / 5'),
                  if (value.notes != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(value.notes!),
                  ],
                ],
              ),
      ),
    );
  }
}
