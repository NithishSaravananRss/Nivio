import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivio/core/debug_log.dart';

final newTvBypassProvider = ChangeNotifierProvider<NewTvBypassService>((ref) {
  return NewTvBypassService();
});

class NewTvBypassService extends ChangeNotifier {
  InAppWebViewController? Function()? _controllerGetter;
  
  String _userAgent = 'Mozilla/5.0 (Linux; Android 13; Pixel 7 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Mobile Safari/537.36';
  Map<String, String> _cookies = {};
  
  bool _isBypassing = false;
  bool _isBypassed = false;
  Completer<void>? _bypassCompleter;
  
  String get userAgent => _userAgent;
  Map<String, String> get cookies => _cookies;
  bool get isReady => _isBypassed;
  bool get isBypassing => _isBypassing;
  
  String get cookieString {
    return _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  void registerWebViewController({required InAppWebViewController? Function() controllerGetter}) {
    _controllerGetter = controllerGetter;
  }

  Future<void> init() async {
    if (_isBypassed || _isBypassing) return;
    appDebugLog('🛡️ Initializing NewTvBypassService...');
    await _startBypass();
  }

  Future<void> forceRefresh() async {
    appDebugLog('🛡️ Manual refresh of NewTV bypass requested...');
    await _startBypass(forceRefresh: true);
  }
  
  Future<void> _startBypass({bool forceRefresh = false}) async {
    if (_isBypassing && !forceRefresh) return;
    _isBypassing = true;
    _bypassCompleter = Completer<void>();
    Future.microtask(() => notifyListeners()); // Tell the Widget to render the WebView
    
    appDebugLog('🛡️ Triggering invisible WebView widget to bypass on net11.cc...');
    
    try {
      CookieManager cookieManager = CookieManager.instance();
      if (forceRefresh) {
        await cookieManager.deleteAllCookies();
        _isBypassed = false;
      }
      
      final cookies = await cookieManager.getCookies(url: WebUri('https://net11.cc/'));
      if (cookies.isNotEmpty && !forceRefresh) {
        appDebugLog('🛡️ Found existing NewTV cookies!');
        _cookies.clear();
        for (var cookie in cookies) {
          _cookies[cookie.name] = cookie.value.toString();
        }
        _isBypassed = true;
        _isBypassing = false;
        Future.microtask(() => notifyListeners());
        _bypassCompleter?.complete();
        return;
      }
      
      final controller = _controllerGetter?.call();
      if (controller != null) {
         await controller.loadUrl(urlRequest: URLRequest(url: WebUri('https://net11.cc/')));
      }
      
    } catch (e) {
      appDebugLog('🛡️ NewTV Bypass error: $e');
      _isBypassing = false;
      Future.microtask(() => notifyListeners());
      
      if (_bypassCompleter != null && !_bypassCompleter!.isCompleted) {
        final completer = _bypassCompleter;
        _bypassCompleter = null;
        completer?.completeError(e);
      }
    }
  }

  Future<void> onBypassSuccess(String url) async {
    appDebugLog('🛡️ NewTV bypass successful! URL: $url');
    await _extractCookies(url);
    
    _isBypassed = true;
    _isBypassing = false;
    Future.microtask(() => notifyListeners()); // Hide the WebView
    
    if (_bypassCompleter != null && !_bypassCompleter!.isCompleted) {
      _bypassCompleter!.complete();
    }
  }

  Future<String?> fetchViaWebView(String url) async {
    final controller = _controllerGetter?.call();
    if (controller == null) return null;
    
    try {
      appDebugLog('🛡️ Executing Fetch via NewTV WebView for: $url');
      final result = await controller.callAsyncJavaScript(functionBody: """
        return fetch(url, {
          headers: {
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'X-Requested-With': 'XMLHttpRequest'
          }
        })
        .then(response => {
          if (!response.ok) {
            return response.text().then(text => 'ERROR: HTTP ' + response.status + ' - ' + text).catch(e => 'ERROR: HTTP ' + response.status);
          }
          return response.text();
        })
        .catch(err => {
          return 'ERROR: Fetch failed - ' + err.toString();
        });
      """, arguments: {'url': url}).timeout(const Duration(seconds: 20));
      
      appDebugLog('🛡️ Fetch completed. Value starts with: ${(result?.value as String?)?.substring(0, (result?.value as String?)?.length.clamp(0, 50) ?? 0)}...');
      return result?.value as String?;
    } catch (e) {
      appDebugLog('🛡️ fetchViaWebView threw an exception: $e');
      return null;
    }
  }

  Future<void> _extractCookies(String url) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      CookieManager cookieManager = CookieManager.instance();
      final uri = WebUri(url);
      List<Cookie> cookies = await cookieManager.getCookies(url: uri);
      
      if (cookies.isEmpty) {
        cookies = await cookieManager.getCookies(url: WebUri('https://net11.cc'));
      }
      
      _cookies.clear();
      for (var cookie in cookies) {
        _cookies[cookie.name] = cookie.value.toString();
      }
      appDebugLog('🛡️ Extracted ${_cookies.length} cookies from $url');
    } catch (e) {
      appDebugLog('🛡️ Error extracting cookies: $e');
    }
  }
}
