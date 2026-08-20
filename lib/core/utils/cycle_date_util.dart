enum CycleMode {
  calendar,
  offset31To30,
  sameDaySpan, // e.g. 1st to 1st, 31st to 31st
  custom,
}

class CycleDateUtil {
  /// Returns the clamped day for a specific year and month (handles leap years & 28/30/31 days).
  static int clampDay(int year, int month, int targetDay) {
    // DateTime(year, month + 1, 0) gives the last day of 'month'
    final lastDay = DateTime(year, month + 1, 0).day;
    return targetDay.clamp(1, lastDay);
  }

  /// Calculates the start and end DateTime for the cycle containing [now].
  static ({DateTime start, DateTime end}) getCycleRange({
    DateTime? now,
    required CycleMode mode,
    int startDay = 1,
    int endDay = 31,
  }) {
    final ref = now ?? DateTime.now();

    switch (mode) {
      case CycleMode.calendar:
        final start = DateTime(ref.year, ref.month, 1, 0, 0, 0);
        final end = DateTime(ref.year, ref.month + 1, 0, 23, 59, 59, 999);
        return (start: start, end: end);

      case CycleMode.offset31To30:
        final lastDayOfThisMonth = DateTime(ref.year, ref.month + 1, 0).day;
        if (ref.day == lastDayOfThisMonth) {
          // If today is the last day of this month (e.g. Aug 31), next cycle has started
          final start = DateTime(ref.year, ref.month, ref.day, 0, 0, 0);
          final end = DateTime(ref.year, ref.month + 2, -1, 23, 59, 59, 999);
          return (start: start, end: end);
        } else {
          // Standard offset cycle (e.g. Jul 31 to Aug 30)
          final start = DateTime(ref.year, ref.month, 0, 0, 0, 0);
          final end = DateTime(ref.year, ref.month + 1, -1, 23, 59, 59, 999);
          return (start: start, end: end);
        }

      case CycleMode.sameDaySpan:
        // e.g. 1st to 1st or 31st to 31st
        final effectiveStartDay = startDay;
        final effectiveEndDay = endDay;
        if (ref.day >= effectiveStartDay) {
          final sDay = clampDay(ref.year, ref.month, effectiveStartDay);
          final eDay = clampDay(ref.year, ref.month + 1, effectiveEndDay);
          final start = DateTime(ref.year, ref.month, sDay, 0, 0, 0);
          final end = DateTime(ref.year, ref.month + 1, eDay, 23, 59, 59, 999);
          return (start: start, end: end);
        } else {
          final sDay = clampDay(ref.year, ref.month - 1, effectiveStartDay);
          final eDay = clampDay(ref.year, ref.month, effectiveEndDay);
          final start = DateTime(ref.year, ref.month - 1, sDay, 0, 0, 0);
          final end = DateTime(ref.year, ref.month, eDay, 23, 59, 59, 999);
          return (start: start, end: end);
        }

      case CycleMode.custom:
        if (startDay == 1 && endDay >= 31) {
          // Calendar month equivalence
          final start = DateTime(ref.year, ref.month, 1, 0, 0, 0);
          final end = DateTime(ref.year, ref.month + 1, 0, 23, 59, 59, 999);
          return (start: start, end: end);
        }

        if (startDay < endDay) {
          // Same calendar month cycle (e.g. 1st to 15th, or 5th to 20th)
          final sDay = clampDay(ref.year, ref.month, startDay);
          final eDay = clampDay(ref.year, ref.month, endDay);
          final start = DateTime(ref.year, ref.month, sDay, 0, 0, 0);
          final end = DateTime(ref.year, ref.month, eDay, 23, 59, 59, 999);
          return (start: start, end: end);
        } else {
          // Cross-month cycle (e.g. 25th to 24th, 31st to 30th, 1st to 1st)
          if (ref.day >= startDay) {
            final sDay = clampDay(ref.year, ref.month, startDay);
            final eDay = clampDay(ref.year, ref.month + 1, endDay);
            final start = DateTime(ref.year, ref.month, sDay, 0, 0, 0);
            final end = DateTime(ref.year, ref.month + 1, eDay, 23, 59, 59, 999);
            return (start: start, end: end);
          } else {
            final sDay = clampDay(ref.year, ref.month - 1, startDay);
            final eDay = clampDay(ref.year, ref.month, endDay);
            final start = DateTime(ref.year, ref.month - 1, sDay, 0, 0, 0);
            final end = DateTime(ref.year, ref.month, eDay, 23, 59, 59, 999);
            return (start: start, end: end);
          }
        }
    }
  }

  static DateTime getCycleStartDate({
    DateTime? now,
    required CycleMode mode,
    int startDay = 1,
    int endDay = 31,
  }) {
    return getCycleRange(
      now: now,
      mode: mode,
      startDay: startDay,
      endDay: endDay,
    ).start;
  }

  static DateTime getCycleEndDate({
    DateTime? now,
    required CycleMode mode,
    int startDay = 1,
    int endDay = 31,
  }) {
    return getCycleRange(
      now: now,
      mode: mode,
      startDay: startDay,
      endDay: endDay,
    ).end;
  }

  static String getOrdinal(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  static String formatShortDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String getCycleDescription({
    required CycleMode mode,
    int startDay = 1,
    int endDay = 31,
  }) {
    switch (mode) {
      case CycleMode.calendar:
        return '1st to End of Month (Calendar)';
      case CycleMode.offset31To30:
        return '31st to 30th (1-day offset)';
      case CycleMode.sameDaySpan:
        return '${getOrdinal(startDay)} to ${getOrdinal(endDay)} (Span)';
      case CycleMode.custom:
        return 'Custom (${getOrdinal(startDay)} to ${getOrdinal(endDay)})';
    }
  }
}
