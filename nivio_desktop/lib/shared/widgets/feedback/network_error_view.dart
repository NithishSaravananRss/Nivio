import 'package:flutter/material.dart';

import 'error_view.dart';

class NetworkErrorView extends StatelessWidget {
  const NetworkErrorView({
    super.key,
    this.title = 'Connection problem',
    this.message = 'Check your network connection and try again.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorView(title: title, message: message, onRetry: onRetry);
  }
}
