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
      appBar: AppBar(title: const Text('Detail Sesi Belajar')),
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Gagal memuat sesi.')),
        data: (value) => value == null
            ? const Center(child: Text('Sesi belajar tidak ditemukan.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    value.subject,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tanggal: ${value.date.year}-${value.date.month}-${value.date.day}',
                  ),
                  Text('Mulai: ${value.startTime}'),
                  if (value.endTime != null) Text('Selesai: ${value.endTime}'),
                  if (value.durationSeconds != null)
                    Text('Durasi: ${value.durationSeconds! ~/ 60} menit'),
                  if (value.understanding != null)
                    Text('Pemahaman: ${value.understanding} / 5'),
                  if (value.notes != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Catatan',
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
