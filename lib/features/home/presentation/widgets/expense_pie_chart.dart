import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_state.dart';

class ExpensePieChart extends StatelessWidget {
  const ExpensePieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        Map<BudgetCategory, double> categorySpend = {};
        double totalExpense = 0.0;

        if (state is TransactionLoaded) {
          categorySpend = state.categorySpend;
          totalExpense = state.totalExpense;
        }

        // Filter out zero / negative amounts
        final nonZeroCategories = categorySpend.entries
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    categorySpend: nonZeroCategories,
                    totalExpense: totalExpense,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Monthly Expense',
              style: TextStyle(
                color: AppColors.cream,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<MapEntry<BudgetCategory, double>> categorySpend;
  final double totalExpense;

  _PieChartPainter({
    required this.categorySpend,
    required this.totalExpense,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    final borderPaint = Paint()
      ..color = AppColors.cream.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (totalExpense <= 0 || categorySpend.isEmpty) {
      // Empty state circular placeholder
      final emptyFillPaint = Paint()
        ..color = AppColors.surfaceLight.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, emptyFillPaint);
      canvas.drawCircle(center, radius, borderPaint);

      // Draw cross dividing lines to match wireframe sketch placeholder
      canvas.drawLine(
        Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius),
        borderPaint,
      );
      canvas.drawLine(
        Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy),
        borderPaint,
      );

      // Text in center
      const textSpan = TextSpan(
        text: 'No Expenses\nThis Month',
        style: TextStyle(
          color: AppColors.cream,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * 1.5);

      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );
      return;
    }

    double startAngle = -math.pi / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw slices
    for (int i = 0; i < categorySpend.length; i++) {
      final entry = categorySpend[i];
      final sweepAngle = (entry.value / totalExpense) * 2 * math.pi;

      final sliceColor = AppColors.pieChartPalette[i % AppColors.pieChartPalette.length];
      final slicePaint = Paint()
        ..color = sliceColor
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, slicePaint);

      // Draw slice border line
      final linePaint = Paint()
        ..color = AppColors.cream.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final endPoint = Offset(
        center.dx + radius * math.cos(startAngle),
        center.dy + radius * math.sin(startAngle),
      );
      canvas.drawLine(center, endPoint, linePaint);

      // Draw percentage text on slice if slice is big enough
      final percentage = (entry.value / totalExpense) * 100;
      if (percentage >= 5) {
        final labelAngle = startAngle + sweepAngle / 2;
        final labelRadius = radius * 0.65;
        final labelPos = Offset(
          center.dx + labelRadius * math.cos(labelAngle),
          center.dy + labelRadius * math.sin(labelAngle),
        );

        final labelText = '${entry.key.displayName}\n${percentage.toStringAsFixed(0)}%';
        final labelSpan = TextSpan(
          text: labelText,
          style: const TextStyle(
            color: AppColors.cream,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 3,
                color: Colors.black87,
                offset: Offset(1, 1),
              ),
            ],
          ),
        );

        final labelPainter = TextPainter(
          text: labelSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: radius * 0.8);

        labelPainter.paint(
          canvas,
          Offset(labelPos.dx - labelPainter.width / 2, labelPos.dy - labelPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }

    // Outer circle border
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.totalExpense != totalExpense ||
        oldDelegate.categorySpend != categorySpend;
  }
}
