import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/study_session.dart';
import 'study_providers.dart';

class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(studySessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Study')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/study/add'),
        icon: const Icon(Icons.add),
        label: const Text('Study session'),
      ),
      body: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Failed to load study sessions.')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No study sessions yet.'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final session = items[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                      title: Text(session.subject),
                      subtitle: Text(_subtitle(session)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/study/session/${session.id}'),
                    ),
                  );
                },
              ),
      ),
    );
  }

  static String _subtitle(StudySession session) =>
      '${session.date.year}-${session.date.month.toString().padLeft(2, '0')}-${session.date.day.toString().padLeft(2, '0')} • ${session.durationSeconds == null ? 'Open session' : '${session.durationSeconds! ~/ 60} min'}';
}
