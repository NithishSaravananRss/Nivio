import 'package:flutter/material.dart';
import '../../theme/index.dart';
import '../cards/section_header.dart';

class PersonCarousel extends StatefulWidget {
  const PersonCarousel({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 250.0,
    this.itemWidth = 170.0,
  });

  final String title;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double height;
  final double itemWidth;

  @override
  State<PersonCarousel> createState() => _PersonCarouselState();
}

class _PersonCarouselState extends State<PersonCarousel> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftButton = false;
  bool _showRightButton = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;
    setState(() {
      _showLeftButton = _scrollController.offset > 10;
      _showRightButton = _scrollController.offset <
          _scrollController.position.maxScrollExtent - 10;
    });
  }

  void _scroll(double offset) {
    _scrollController.animateTo(
      (_scrollController.offset + offset).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: AppAnimation.slow,
      curve: AppAnimation.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: widget.title),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Horizontal list
              Positioned.fill(
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.itemCount,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.lg),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: widget.itemWidth,
                      child: widget.itemBuilder(context, index),
                    );
                  },
                ),
              ),

              // Left scroll button
              if (_showLeftButton)
                Positioned(
                  left: -18,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CarouselArrowButton(
                      icon: Icons.chevron_left,
                      onTap: () => _scroll(-500),
                    ),
                  ),
                ),

              // Right scroll button
              if (_showRightButton && widget.itemCount > 4)
                Positioned(
                  right: -18,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CarouselArrowButton(
                      icon: Icons.chevron_right,
                      onTap: () => _scroll(500),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CarouselArrowButton extends StatefulWidget {
  const _CarouselArrowButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_CarouselArrowButton> createState() => _CarouselArrowButtonState();
}

class _CarouselArrowButtonState extends State<_CarouselArrowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimation.hover,
          curve: AppAnimation.standard,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered
                ? AppColors.primary
                : Colors.black.withValues(alpha: 0.62),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.borderSubtle,
            ),
            boxShadow: AppShadows.hover,
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 24,
              color: _isHovered ? AppColors.background : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
