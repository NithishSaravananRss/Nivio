/// Contract for desktop app preferences and user-adjustable settings.
abstract class SettingsRepository {
  Future<Map<String, dynamic>> getSettings();

  Future<T?> getSetting<T>(String key);

  Future<void> saveSetting<T>(String key, T value);

  Future<void> resetSettings();
}
