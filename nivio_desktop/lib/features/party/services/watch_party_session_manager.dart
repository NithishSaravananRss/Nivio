import 'dart:async';

import 'watch_party_identity.dart';
import 'watch_party_service_supabase.dart';
import 'watch_party_supabase_config.dart';

class WatchPartySessionManager {
  WatchPartySessionManager._();

  static final WatchPartySessionManager instance = WatchPartySessionManager._();

  final WatchPartyIdentityStore _identityStore = WatchPartyIdentityStore();
  WatchPartyServiceSupabase? _service;

  WatchPartyServiceSupabase? get currentService => _service;

  Future<WatchPartyServiceSupabase?> ensureService() async {
    await WatchPartySupabaseConfig.initializeIfConfigured();
    if (!WatchPartySupabaseConfig.isAvailable) return null;

    final existing = _service;
    if (existing != null) return existing;

    final identity = await _identityStore.load();
    final service = WatchPartyServiceSupabase(
      userId: identity.userId,
      userName: identity.userName,
      userPhotoUrl: identity.userPhotoUrl,
    );
    _service = service;
    return service;
  }

  Future<void> leaveOrEndCurrentSession() async {
    final service = _service;
    if (service == null) return;
    if (service.isHost) {
      await service.endSession();
    } else {
      await service.leaveSession();
    }
  }

  Future<void> disposeService() async {
    final service = _service;
    _service = null;
    service?.dispose();
    await Future<void>.delayed(Duration.zero);
  }
}
