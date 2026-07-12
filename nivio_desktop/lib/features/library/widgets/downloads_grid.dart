import 'package:flutter/material.dart';

import '../../../shared/theme/index.dart';

class DownloadsGrid extends StatelessWidget {
  const DownloadsGrid({super.key});

  static const _downloads = [
    _DownloadItem('Blackout City', 'Downloading · 1.2 GB of 2.8 GB', 0.42),
    _DownloadItem('Sky Forge', 'Downloading · Episode 8', 0.68),
    _DownloadItem('Moon Harbor', 'Completed · Season 1 Episode 9', 1),
    _DownloadItem('Archive West', 'Completed · Season 2 Episode 1', 1),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.standard;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 2 : 1,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisExtent: 112,
          ),
          itemCount: _downloads.length,
          itemBuilder: (context, index) =>
              _DownloadTile(download: _downloads[index]),
        );
      },
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({required this.download});

  final _DownloadItem download;

  @override
  Widget build(BuildContext context) {
    final isComplete = download.progress >= 1;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isComplete
                      ? Icons.check_circle_outline
                      : Icons.downloading_outlined,
                  color: isComplete ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(download.title, style: AppTypography.title),
                      const SizedBox(height: AppSpacing.xs),
                      Text(download.subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            LinearProgressIndicator(value: download.progress),
          ],
        ),
      ),
    );
  }
}

class _DownloadItem {
  const _DownloadItem(this.title, this.subtitle, this.progress);

  final String title;
  final String subtitle;
  final double progress;
}
