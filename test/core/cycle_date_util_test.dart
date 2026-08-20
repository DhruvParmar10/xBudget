import 'package:flutter_test/flutter_test.dart';
import 'package:xbudget/core/utils/cycle_date_util.dart';

void main() {
  group('CycleDateUtil Tests', () {
    test('Calendar mode produces 1st to last day of current month', () {
      final augDate = DateTime(2026, 8, 15);
      final range = CycleDateUtil.getCycleRange(now: augDate, mode: CycleMode.calendar);

      expect(range.start, equals(DateTime(2026, 8, 1, 0, 0, 0)));
      expect(range.end, equals(DateTime(2026, 8, 31, 23, 59, 59, 999)));

      final febDate = DateTime(2025, 2, 10);
      final febRange = CycleDateUtil.getCycleRange(now: febDate, mode: CycleMode.calendar);
      expect(febRange.start, equals(DateTime(2025, 2, 1, 0, 0, 0)));
      expect(febRange.end, equals(DateTime(2025, 2, 28, 23, 59, 59, 999)));
    });

    test('1-Day Offset mode (31st to 30th) produces correct range', () {
      // Middle of August (Aug 20)
      final midAug = DateTime(2026, 8, 20);
      final range1 = CycleDateUtil.getCycleRange(now: midAug, mode: CycleMode.offset31To30);
      // Starts on last day of July (Jul 31), ends on day before last day of August (Aug 30)
      expect(range1.start, equals(DateTime(2026, 7, 31, 0, 0, 0)));
      expect(range1.end, equals(DateTime(2026, 8, 30, 23, 59, 59, 999)));

      // On the last day of August (Aug 31), it starts the September cycle (Aug 31 to Sep 29)
      final endAug = DateTime(2026, 8, 31);
      final range2 = CycleDateUtil.getCycleRange(now: endAug, mode: CycleMode.offset31To30);
      expect(range2.start, equals(DateTime(2026, 8, 31, 0, 0, 0)));
      expect(range2.end, equals(DateTime(2026, 9, 29, 23, 59, 59, 999)));
    });

    test('Same Day Span mode (1st to 1st) produces correct range', () {
      final augDate = DateTime(2026, 8, 15);
      final range = CycleDateUtil.getCycleRange(
        now: augDate,
        mode: CycleMode.sameDaySpan,
        startDay: 1,
        endDay: 1,
      );

      expect(range.start, equals(DateTime(2026, 8, 1, 0, 0, 0)));
      expect(range.end, equals(DateTime(2026, 9, 1, 23, 59, 59, 999)));
    });

    test('Custom mode with cross-month span (e.g. 25th to 24th)', () {
      // Date before 25th (Aug 10) -> cycle is July 25 to Aug 24
      final aug10 = DateTime(2026, 8, 10);
      final range1 = CycleDateUtil.getCycleRange(
        now: aug10,
        mode: CycleMode.custom,
        startDay: 25,
        endDay: 24,
      );
      expect(range1.start, equals(DateTime(2026, 7, 25, 0, 0, 0)));
      expect(range1.end, equals(DateTime(2026, 8, 24, 23, 59, 59, 999)));

      // Date after 25th (Aug 26) -> cycle is Aug 25 to Sep 24
      final aug26 = DateTime(2026, 8, 26);
      final range2 = CycleDateUtil.getCycleRange(
        now: aug26,
        mode: CycleMode.custom,
        startDay: 25,
        endDay: 24,
      );
      expect(range2.start, equals(DateTime(2026, 8, 25, 0, 0, 0)));
      expect(range2.end, equals(DateTime(2026, 9, 24, 23, 59, 59, 999)));
    });

    test('Cycle description formatting', () {
      expect(
        CycleDateUtil.getCycleDescription(mode: CycleMode.calendar),
        equals('1st to End of Month (Calendar)'),
      );
      expect(
        CycleDateUtil.getCycleDescription(mode: CycleMode.offset31To30),
        equals('31st to 30th (1-day offset)'),
      );
      expect(
        CycleDateUtil.getCycleDescription(
          mode: CycleMode.custom,
          startDay: 5,
          endDay: 4,
        ),
        equals('Custom (5th to 4th)'),
      );
    });
  });
}
