import 'package:flutter/material.dart';
import '../../../core/network/image/tmdb_image_builder.dart';
import '../../theme/index.dart';
import '../common/hover_card.dart';

class PersonCard extends StatefulWidget {
  const PersonCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.profilePath,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? profilePath;
  final VoidCallback? onTap;

  @override
  State<PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<PersonCard> {
  static final Set<String> _failedProfileUrls = <String>{};

  String? get _profileUrl {
    final path = widget.profilePath?.trim();
    if (path == null || path.isEmpty) return null;

    final url = TmdbImageBuilder.profile(path, size: 'w185');
    if (url.isEmpty || _failedProfileUrls.contains(url)) return null;

    return url;
  }

  void _markFailed(String url) {
    _failedProfileUrls.add(url);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileUrl = _profileUrl;

    return HoverCard(
      semanticLabel: widget.title,
      onTap: widget.onTap,
      padding: EdgeInsets.zero,
      child: const SizedBox.shrink(),
      builder: (context, isHovered, isFocused) {
        final active = isHovered || isFocused;

        return AnimatedScale(
          scale: active ? 1.035 : 1.0,
          duration: AppAnimation.hover,
          curve: AppAnimation.standard,
          child: SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 210,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: active ? 0.45 : 0.28,
                          ),
                          blurRadius: active ? 26 : 14,
                          spreadRadius: active ? -2 : -6,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: profileUrl == null
                          ? const _PersonPlaceholder()
                          : Image.network(
                              profileUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                _markFailed(profileUrl);
                                return const _PersonPlaceholder();
                              },
                              frameBuilder:
                                  (
                                    context,
                                    child,
                                    frame,
                                    wasSynchronouslyLoaded,
                                  ) {
                                    if (wasSynchronouslyLoaded ||
                                        frame != null) {
                                      return child;
                                    }
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        const _PersonPlaceholder(),
                                        AnimatedOpacity(
                                          opacity: frame == null ? 0 : 1,
                                          duration: AppAnimation.hover,
                                          child: child,
                                        ),
                                      ],
                                    );
                                  },
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PersonPlaceholder extends StatelessWidget {
  const _PersonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [
            AppColors.textSecondary.withValues(alpha: 0.14),
            AppColors.surfaceVariant,
            AppColors.background.withValues(alpha: 0.94),
          ],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 22,
            child: Icon(
              Icons.person,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              size: 86,
            ),
          ),
          Positioned(
            top: 44,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface.withValues(alpha: 0.72),
              ),
              child: Icon(
                Icons.person_outline,
                color: AppColors.textSecondary.withValues(alpha: 0.64),
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
