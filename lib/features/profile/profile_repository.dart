import 'package:shared_preferences/shared_preferences.dart';

/// Local, lightweight profile persistence backed by SharedPreferences.
///
/// Stores a single user-facing display name keyed under this app's
/// preferences. No users table, no authentication, no cloud storage —
/// consistent with the local-first Activus architecture.
class ProfileRepository {
  static const _displayNameKey = 'profile.display_name';

  /// Shown until the user sets a custom name, so the More row is never blank.
  static const defaultDisplayName = 'Pengguna Activus';

  Future<String> loadDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_displayNameKey) ?? defaultDisplayName;
  }

  Future<void> saveDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, name);
  }
}
