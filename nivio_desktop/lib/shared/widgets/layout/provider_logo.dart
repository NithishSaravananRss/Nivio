import 'package:flutter/material.dart';
import '../../../core/network/image/tmdb_image_builder.dart';
import '../../theme/index.dart';

class ProviderLogoResolver {
  static const Map<String, String> _logoPathMap = {
    'prime video': '/dQgJ477t946T6tWTe4ZlhCqHn7q.jpg',
    'amazon prime video': '/dQgJ477t946T6tWTe4ZlhCqHn7q.jpg',
    'disney+': '/7rwE026ge98cBtPR5oR701m4crE.jpg',
    'disney plus': '/7rwE026ge98cBtPR5oR701m4crE.jpg',
    'apple tv': '/2e08ja8BhSS6ebw2w7MAJBs5gTu.jpg',
    'apple tv+': '/2e08ja8BhSS6ebw2w7MAJBs5gTu.jpg',
    'apple tv plus': '/2e08ja8BhSS6ebw2w7MAJBs5gTu.jpg',
    'hulu': '/bxBlR3krwGQ1AYjA7crEiR5wA3L.jpg',
    'max': '/peURwq6mGkH85cr1ZQLKp6g3275.jpg',
    'hbo max': '/peURwq6mGkH85cr1ZQLKp6g3275.jpg',
    'peacock': '/8vc434qp5Uk5845Xm7H86J1jO1B.jpg',
    'peacock premium': '/8vc434qp5Uk5845Xm7H86J1jO1B.jpg',
    'paramount+': '/keym7h62Nu6yr451IP0jK11A6a6.jpg',
    'paramount plus': '/keym7h62Nu6yr451IP0jK11A6a6.jpg',
    'crunchyroll': '/or65cr31bM2P4m25kQ11c1YjC4E.jpg',
    'hotstar': '/bc4b1848c26211.png',
    'jiohotstar': '/bc4b1848c26211.png',
  };

  static String? getLogoUrl(String providerName) {
    final key = providerName.toLowerCase().trim();
    for (final entry in _logoPathMap.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return TmdbImageBuilder.logo(entry.value);
      }
    }
    return null;
  }
}

class ProviderLogo extends StatelessWidget {
  const ProviderLogo({super.key, required this.name, this.size = 36.0});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logoUrl = ProviderLogoResolver.getLogoUrl(name);

    if (logoUrl != null) {
      return Tooltip(
        message: name,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.small),
            boxShadow: AppShadows.hover,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            logoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _ProviderTextBadge(name: name, size: size),
          ),
        ),
      );
    }

    // Fallback if logo is not found: styled premium text badge
    return _ProviderTextBadge(name: name, size: size);
  }
}

class _ProviderTextBadge extends StatelessWidget {
  const _ProviderTextBadge({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      child: Container(
        height: size,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Center(
          child: Text(
            name,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class ProviderRow extends StatelessWidget {
  const ProviderRow({super.key, required this.providers, this.size = 40.0});

  final List<String> providers;
  final double size;

  @override
  Widget build(BuildContext context) {
    // If no providers exist, or it contains 'Not Available', hide completely
    final activeProviders = providers
        .where((p) => p.isNotEmpty && p.toLowerCase() != 'not available')
        .toList();

    if (activeProviders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AVAILABLE ON',
          style: AppTypography.metadata.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: activeProviders
              .map((p) => ProviderLogo(name: p, size: size))
              .toList(),
        ),
      ],
    );
  }
}
