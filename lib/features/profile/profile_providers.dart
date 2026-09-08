import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// The user's local display name. Invalidate after saving to refresh.
final displayNameProvider = FutureProvider<String>((ref) {
  return ref.watch(profileRepositoryProvider).loadDisplayName();
});
