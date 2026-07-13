import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_environment.dart';

class WatchPartySupabaseConfig {
  static bool _initialized = false;

  static bool get isConfigured =>
      AppEnvironment.supabaseUrl.isNotEmpty &&
      AppEnvironment.supabaseAnonKey.isNotEmpty;

  static bool get isAvailable => _initialized && isConfigured;

  static Future<void> initializeIfConfigured() async {
    if (_initialized || !isConfigured) return;

    try {
      await Supabase.initialize(
        url: AppEnvironment.supabaseUrl,
        publishableKey: AppEnvironment.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
        realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 10),
      );
      _initialized = true;
      debugPrint('[party] Supabase initialized');
    } catch (error, stackTrace) {
      debugPrint('[party] Supabase init failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace, label: '[party] init stack');
      }
    }
  }
}
