import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(title: title, message: message);
  }
}
