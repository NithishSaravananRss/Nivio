import 'package:flutter/material.dart';

import '../../../shared/theme/index.dart';

class ScheduleCalendar extends StatelessWidget {
  const ScheduleCalendar({
    super.key,
    required this.selectedMonth,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  final String selectedMonth;
  final DateTime selectedDate;
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  static const _months = ['January 2026', 'February 2026', 'March 2026'];
  static const _releaseDays = {3, 7, 11, 15, 18, 22, 27};

  @override
  Widget build(BuildContext context) {
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
                Expanded(child: Text('Schedule', style: AppTypography.title)),
                DropdownButton<String>(
                  value: selectedMonth,
                  items: _months
                      .map(
                        (month) =>
                            DropdownMenuItem(value: month, child: Text(month)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onMonthChanged(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _WeekdayHeader(),
            const SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
              ),
              itemCount: 35,
              itemBuilder: (context, index) {
                final day = index - 2;
                if (day <= 0 || day > 31) {
                  return const SizedBox.shrink();
                }
                final hasRelease = _releaseDays.contains(day);
                final isToday = day == 15;
                final isSelected = selectedDate.day == day;
                return _CalendarDay(
                  day: day,
                  hasRelease: hasRelease,
                  isToday: isToday,
                  isSelected: isSelected,
                  onTap: () => onDateSelected(
                    DateTime(selectedDate.year, selectedDate.month, day),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
          .map(
            (day) => Expanded(
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: AppTypography.metadata,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.hasRelease,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final bool hasRelease;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isToday || isSelected
              ? AppColors.sidebarSelected
              : AppColors.surfaceVariant,
          border: Border.all(
            color: isToday || isSelected
                ? AppColors.primary
                : AppColors.borderSubtle,
          ),
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$day',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (hasRelease)
              const Positioned(
                right: AppSpacing.xs,
                bottom: AppSpacing.xs,
                child: _ReleaseDot(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseDot extends StatelessWidget {
  const _ReleaseDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: const SizedBox.square(dimension: AppSpacing.xs),
    );
  }
}
