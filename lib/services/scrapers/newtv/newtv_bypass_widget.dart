import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nivio/core/debug_log.dart';
import 'package:nivio/services/scrapers/newtv/newtv_bypass_service.dart';

class NewTvBypassWidget extends ConsumerStatefulWidget {
  const NewTvBypassWidget({super.key});

  @override
  ConsumerState<NewTvBypassWidget> createState() => _NewTvBypassWidgetState();
}

class _NewTvBypassWidgetState extends ConsumerState<NewTvBypassWidget> {
  InAppWebViewController? _controller;
  bool _isDisposed = false;

  bool _mountWebView = false;
  String _currentUrl = 'https://net11.cc/';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        ref.read(newTvBypassProvider).registerWebViewController(
          controllerGetter: () => _controller,
        );
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _mountWebView = true);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bypassState = ref.watch(newTvBypassProvider);

    return Stack(
      children: [
        if (_mountWebView)
          SizedBox(
            width: 1,
            height: 1,
            child: IgnorePointer(
              ignoring: true,
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri('https://net11.cc/')),
                initialSettings: InAppWebViewSettings(
                  userAgent: bypassState.userAgent,
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  thirdPartyCookiesEnabled: true,
                  transparentBackground: true,
                  useWideViewPort: true,
                  loadWithOverviewMode: true,
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;
                  bypassState.registerWebViewController(controllerGetter: () => _controller);
                  appDebugLog('🛡️ NewTV InAppWebView created');
                },
                onLoadStart: (controller, url) {
                  appDebugLog('🛡️ NewTV Loading $url');
                  if (url != null && mounted) {
                    setState(() {
                      _currentUrl = url.toString();
                    });
                  }
                },
                onLoadStop: (controller, url) async {
                  appDebugLog('🛡️ NewTV Load stopped for $url');
                  if (url != null && mounted) {
                    setState(() {
                      _currentUrl = url.toString();
                    });
                    
                    // The page finished loading, Cloudflare might have passed!
                    // Check if we are on the main page, or just blindly attempt success.
                    if (bypassState.isBypassing) {
                      bypassState.onBypassSuccess(_currentUrl);
                    }
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}

