import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class DesktopPipService {
  DesktopPipService._();

  static final DesktopPipService instance = DesktopPipService._();

  Size? _previousSize;
  Offset? _previousPosition;
  bool _active = false;

  bool get isActive => _active;
  bool get isSupported =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  Future<void> toggle() async {
    if (_active) {
      await exit();
    } else {
      await enter();
    }
  }

  Future<void> enter() async {
    if (_active || !isSupported) return;
    try {
      await windowManager.ensureInitialized();
      _previousSize = await windowManager.getSize();
      _previousPosition = await windowManager.getPosition();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setMinimumSize(const Size(360, 220));
      await windowManager.setSize(const Size(460, 280));
      await windowManager.center();
      _active = true;
    } catch (_) {
      _active = false;
    }
  }

  Future<void> exit() async {
    if (!_active) return;
    try {
      await windowManager.ensureInitialized();
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setMinimumSize(const Size(900, 560));
      final size = _previousSize;
      final position = _previousPosition;
      if (size != null) await windowManager.setSize(size);
      if (position != null) await windowManager.setPosition(position);
    } finally {
      _active = false;
      _previousSize = null;
      _previousPosition = null;
    }
  }
}
