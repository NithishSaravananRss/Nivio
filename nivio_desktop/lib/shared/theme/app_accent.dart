import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

const String appAccentColorPreferenceKey = 'app_accent_color';

class AppAccentOption {
  const AppAccentOption({
    required this.key,
    required this.label,
    required this.color,
  });

  final String key;
  final String label;
  final Color color;
}

const List<AppAccentOption> appAccentOptions = [
  AppAccentOption(key: 'red', label: 'Red', color: AppColors.primary),
  AppAccentOption(key: 'blue', label: 'Blue', color: Color(0xFF3B82F6)),
  AppAccentOption(key: 'green', label: 'Green', color: Color(0xFF22C55E)),
  AppAccentOption(key: 'orange', label: 'Orange', color: Color(0xFFF97316)),
  AppAccentOption(key: 'pink', label: 'Pink', color: Color(0xFFEC4899)),
  AppAccentOption(key: 'purple', label: 'Purple', color: Color(0xFFA855F7)),
  AppAccentOption(key: 'teal', label: 'Teal', color: Color(0xFF14B8A6)),
  AppAccentOption(key: 'yellow', label: 'Yellow', color: Color(0xFFEAB308)),
  AppAccentOption(key: 'cyan', label: 'Cyan', color: Color(0xFF06B6D4)),
];

String appAccentLabelFromKey(String key) {
  for (final option in appAccentOptions) {
    if (option.key == key) return option.label;
  }
  if (key.startsWith('#')) return 'Custom ($key)';
  return appAccentOptions.first.label;
}

Color appAccentColorFromKey(String key) {
  for (final option in appAccentOptions) {
    if (option.key == key) return option.color;
  }
  if (key.startsWith('#')) {
    final hex = key.substring(1);
    if (hex.length == 6) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) return Color(value | 0xFF000000);
    }
  }
  return appAccentOptions.first.color;
}

class AppAccentController extends ChangeNotifier {
  AppAccentController._();

  static final AppAccentController instance = AppAccentController._();

  String _key = appAccentOptions.first.key;
  bool _loaded = false;

  String get key => _key;
  Color get color => appAccentColorFromKey(_key);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _setKey(prefs.getString(appAccentColorPreferenceKey) ?? _key);
    } catch (_) {
      _setKey(_key);
    }
  }

  Future<void> setAccentColor(String key) async {
    final normalized = _normalize(key);
    _setKey(normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(appAccentColorPreferenceKey, normalized);
  }

  void _setKey(String key) {
    final normalized = _normalize(key);
    if (_key == normalized) return;
    _key = normalized;
    notifyListeners();
  }

  String _normalize(String key) {
    for (final option in appAccentOptions) {
      if (option.key == key) return key;
    }
    if (key.startsWith('#')) return key;
    return appAccentOptions.first.key;
  }
}

extension NivioAccentContext on BuildContext {
  Color get appAccent => Theme.of(this).colorScheme.primary;
  Color get appAccentSecondary => Theme.of(this).colorScheme.secondary;
  Color appAccentFill(double alpha) => appAccent.withValues(alpha: alpha);
}
