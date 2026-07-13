import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class WatchPartyIdentity {
  const WatchPartyIdentity({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
  });

  final String userId;
  final String userName;
  final String? userPhotoUrl;
}

class WatchPartyIdentityStore {
  static const _idKey = 'desktop_watch_party_user_id';
  static const _nameKey = 'desktop_watch_party_user_name';

  Future<WatchPartyIdentity> load() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_idKey);
    if (id == null || id.trim().isEmpty) {
      id = _generateGuestId();
      await prefs.setString(_idKey, id);
    }

    var name = prefs.getString(_nameKey);
    if (name == null || name.trim().isEmpty) {
      name = 'Guest ${id.substring(0, 6).toUpperCase()}';
      await prefs.setString(_nameKey, name);
    }

    return WatchPartyIdentity(userId: id, userName: name.trim());
  }

  String _generateGuestId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
