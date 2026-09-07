import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// Provides the application [AppDatabase] instance.
///
/// Override in tests with an in-memory database:
/// ```dart
/// databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory()))
/// ```
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Convenience override that constructs an in-memory database for tests and
/// previews.
Override inMemoryDatabaseOverride() {
  return databaseProvider.overrideWithValue(
    AppDatabase(NativeDatabase.memory()),
  );
}
