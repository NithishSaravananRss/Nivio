import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;
import 'package:material_color_utilities/material_color_utilities.dart';

import 'app_colors.dart';

class DynamicArtworkColors {
  const DynamicArtworkColors({
    required this.dominant,
    required this.darkMuted,
    required this.darkVibrant,
    required this.lightVibrant,
    required this.lightMuted,
    required this.onSurface,
  });

  final Color dominant;
  final Color darkMuted;
  final Color darkVibrant;
  final Color lightVibrant;
  final Color lightMuted;
  final Color onSurface;

  static const fallback = DynamicArtworkColors(
    dominant: AppColors.primary,
    darkMuted: AppColors.background,
    darkVibrant: Color(0xFF8B0000),
    lightVibrant: AppColors.secondary,
    lightMuted: AppColors.surfaceVariant,
    onSurface: Colors.white,
  );
}

final Map<String, Future<DynamicArtworkColors>> _dynamicColorCache = {};

Future<DynamicArtworkColors> dynamicArtworkColorsForUrl(String? imageUrl) {
  final url = imageUrl?.trim();
  if (url == null || url.isEmpty) {
    return Future.value(DynamicArtworkColors.fallback);
  }
  return _dynamicColorCache.putIfAbsent(url, () => _extractArtworkColors(url));
}

Future<DynamicArtworkColors> _extractArtworkColors(String imageUrl) async {
  try {
    final cacheManager = DefaultCacheManager();
    final fileInfo = await cacheManager.getFileFromCache(imageUrl);
    final file = fileInfo?.file ?? await cacheManager.getSingleFile(imageUrl);
    final seedColorValue = await compute(
      _extractSeedColor,
      await file.readAsBytes(),
    );
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Color(seedColorValue),
      brightness: Brightness.dark,
    );
    final darkMuted = colorScheme.surface;
    return DynamicArtworkColors(
      dominant: colorScheme.primary,
      darkMuted: darkMuted,
      darkVibrant: colorScheme.secondary,
      lightVibrant: colorScheme.tertiary,
      lightMuted: colorScheme.surfaceContainerHighest,
      onSurface:
          ThemeData.estimateBrightnessForColor(darkMuted) == Brightness.dark
          ? Colors.white
          : Colors.black,
    );
  } catch (_) {
    return DynamicArtworkColors.fallback;
  }
}

Future<int> _extractSeedColor(Uint8List bytes) async {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return AppColors.primary.toARGB32();
  final resized = img.copyResize(decoded, width: 50, height: 50);
  final pixels = <int>[];
  for (final pixel in resized) {
    final a = pixel.a.toInt();
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    pixels.add((a << 24) | (r << 16) | (g << 8) | b);
  }
  final quantizerResult = await QuantizerCelebi().quantize(pixels, 128);
  final colorToCount = quantizerResult.colorToCount;
  if (colorToCount.isEmpty) return AppColors.primary.toARGB32();
  return colorToCount.keys.reduce(
    (a, b) => colorToCount[a]! > colorToCount[b]! ? a : b,
  );
}
