import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import 'data/study_session_repository.dart';
import 'domain/study_session.dart';

final studySessionRepositoryProvider = Provider<StudySessionRepository>(
  (ref) => StudySessionRepository(ref.watch(databaseProvider)),
);

final studySessionsProvider = FutureProvider<List<StudySession>>((ref) {
  return ref.watch(studySessionRepositoryProvider).getAll();
});

final studySessionByIdProvider = FutureProvider.family<StudySession?, String>((
  ref,
  id,
) {
  return ref.watch(studySessionRepositoryProvider).byId(id);
});
