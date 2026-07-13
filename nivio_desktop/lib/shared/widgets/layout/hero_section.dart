import 'package:flutter/material.dart';
import '../../../core/network/image/tmdb_image_builder.dart';
import '../../theme/index.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({
    super.key,
    required this.title,
    required this.poster,
    required this.content,
    this.backdropPath,
    this.logoPath,
  });

  final String title;
  final String? backdropPath;
  final String? logoPath;
  final Widget poster;
  final Widget content;

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppAnimation.emphasized,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final heroMinHeight = (viewportHeight * 0.82)
        .clamp(660.0, 840.0)
        .toDouble();

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Animated Backdrop Artwork
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: AnimatedScale(
                scale: _fadeController.isAnimating ? 1.025 : 1.0,
                duration: const Duration(milliseconds: 900),
                curve: AppAnimation.emphasized,
                child: _BackdropImage(
                  title: widget.title,
                  backdropPath: widget.backdropPath,
                ),
              ),
            ),
          ),

          // 2. Gradients overlay (Strong left-to-right fade & bottom fade to background)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.background.withValues(alpha: 1),
                    AppColors.background.withValues(alpha: 0.82),
                    AppColors.background.withValues(alpha: 0.26),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                  stops: const [0, 0.32, 0.68, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.74),
                    AppColors.background,
                  ],
                  stops: const [0, 0.26, 0.74, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.15,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.42),
                  ],
                  stops: const [0, 0.68, 1],
                ),
              ),
            ),
          ),

          // 3. Main Content Row / Column Layout (Responsive)
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 104, 56, 72),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppBreakpoints.contentMaxWidth,
                  minHeight: heroMinHeight,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide =
                        constraints.maxWidth >= AppBreakpoints.standard;
                    final posterWidth = isWide ? 246.0 : 198.0;

                    if (!isWide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SizedBox(
                              width: posterWidth,
                              child: widget.poster,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          widget.content,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: posterWidth,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.05),
                                end: Offset.zero,
                              ).animate(_fadeAnimation),
                              child: widget.poster,
                            ),
                          ),
                        ),
                        const SizedBox(width: 56),
                        Expanded(child: widget.content),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropImage extends StatelessWidget {
  const _BackdropImage({required this.title, this.backdropPath});

  final String title;
  final String? backdropPath;

  @override
  Widget build(BuildContext context) {
    if (backdropPath != null && backdropPath!.isNotEmpty) {
      return Image(
        image: NetworkImage(
          TmdbImageBuilder.backdrop(backdropPath, size: 'w1280'),
        ),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }

    // Fallback: Radial Ambient Gradient
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.4,
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Center(
        child: Text(
          title,
          style: AppTypography.display.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.02),
            fontSize: 100,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
