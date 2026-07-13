import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/index.dart';

class ScheduleCalendar extends StatelessWidget {
  const ScheduleCalendar({
    super.key,
    required this.focusedDate,
    required this.selectedDate,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onPickMonth,
    required this.onDateSelected,
  });

  final DateTime focusedDate;
  final DateTime selectedDate;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onPickMonth;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final weekStart = focusedDate.subtract(
      Duration(days: focusedDate.weekday - 1),
    );
    final dates = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

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
                IconButton(
                  tooltip: 'Previous week',
                  onPressed: onPreviousWeek,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: onPickMonth,
                    child: Text(
                      DateFormat.yMMMM().format(focusedDate),
                      style: AppTypography.title,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next week',
                  onPressed: onNextWeek,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _WeekdayHeader(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (final date in dates)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: _CalendarDay(
                        date: date,
                        isToday: _isSameDay(date, DateTime.now()),
                        isSelected: _isSameDay(date, selectedDate),
                        onTap: () => onDateSelected(date),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
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
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.sidebarSelected
                : AppColors.surfaceVariant,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isToday
                  ? AppColors.borderSubtle.withValues(alpha: 0.75)
                  : AppColors.borderSubtle,
            ),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${date.day}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (isToday && !isSelected)
                Positioned(
                  bottom: AppSpacing.xs,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: 4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
