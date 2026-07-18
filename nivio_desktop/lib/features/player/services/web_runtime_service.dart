import 'package:webview_all/webview_all.dart';
import 'package:webview_all_linux/webview_all_linux.dart';

import 'playback_runtime_diagnostics.dart';

final class WebRuntimeService {
  WebRuntimeService._();

  static final WebRuntimeService instance = WebRuntimeService._();

  bool _registered = false;

  WebViewController createController() {
    _ensureRegistered();
    PlaybackRuntimeDiagnostics.webViewsCreated++;
    PlaybackRuntimeDiagnostics.webLog(
      'WebView Created count=${PlaybackRuntimeDiagnostics.webViewsCreated}',
    );
    PlaybackRuntimeDiagnostics.snapshot('after WebView create');
    return WebViewController.fromPlatformCreationParams(
      const LinuxWebViewControllerCreationParams(
        javascriptCanOpenWindowsAutomatically: false,
        mediaPlaybackRequiresUserGesture: false,
        mediaPlaybackAllowsInline: true,
        pageCacheEnabled: true,
      ),
    );
  }

  void markReused() {
    PlaybackRuntimeDiagnostics.webViewReuseCount++;
    PlaybackRuntimeDiagnostics.webLog(
      'WebView Reused count=${PlaybackRuntimeDiagnostics.webViewReuseCount}',
    );
  }

  void markDestroyed() {
    PlaybackRuntimeDiagnostics.webViewsDestroyed++;
    PlaybackRuntimeDiagnostics.webLog(
      'WebView Destroyed count=${PlaybackRuntimeDiagnostics.webViewsDestroyed}',
    );
    PlaybackRuntimeDiagnostics.snapshot('after WebView destroy');
  }

  String limitationsSummary() {
    return 'webview_all_linux does not expose WebContext, WebsiteDataManager, '
        'UserContentManager, renderer PID, GPU memory, CPU usage, or explicit '
        'persistent cache/storage directory configuration.';
  }

  void _ensureRegistered() {
    if (_registered) return;
    LinuxWebViewPlatform.registerWith();
    _registered = true;
    PlaybackRuntimeDiagnostics.webLog(
      'WebRuntimeService initialized with shared Dart runtime; native '
      'WebContext/DataManager reuse is plugin-managed.',
    );
  }
}
