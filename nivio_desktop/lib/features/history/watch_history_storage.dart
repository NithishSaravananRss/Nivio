import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract interface class WatchHistoryStorage {
  Listenable get changes;

  Iterable<String> get values;

  String? read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  Future<void> clear();
}

class HiveWatchHistoryStorage implements WatchHistoryStorage {
  HiveWatchHistoryStorage._(this._box);

  static const boxName = 'watch_history';

  final Box<String> _box;

  static Future<HiveWatchHistoryStorage> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(boxName);
    return HiveWatchHistoryStorage._(box);
  }

  @override
  Listenable get changes => _box.listenable();

  @override
  Iterable<String> get values => _box.values;

  @override
  String? read(String key) => _box.get(key);

  @override
  Future<void> write(String key, String value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<void> clear() => _box.clear();
}
