import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:xbudget/features/transactions/presentation/widgets/category_ui_helper.dart';

class CategoryBreakdownList extends StatelessWidget {
  const CategoryBreakdownList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        Map<BudgetCategory, double> categorySpend = {};

        if (state is TransactionLoaded) {
          categorySpend = state.categorySpend;
        }

        // Get categories with spend > 0, sorted descending by amount
        final entries = categorySpend.entries
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // If no expenses yet, show a few key categories with 0.00
        final displayEntries = entries.isNotEmpty
            ? entries
            : [
                const MapEntry(BudgetCategory.food, 0.0),
                const MapEntry(BudgetCategory.bills, 0.0),
                const MapEntry(BudgetCategory.shopping, 0.0),
                const MapEntry(BudgetCategory.transport, 0.0),
                const MapEntry(BudgetCategory.entertainment, 0.0),
              ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: displayEntries.map((entry) {
              final catColor = CategoryUiHelper.getColor(entry.key);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          entry.key.displayName,
                          style: const TextStyle(
                            color: AppColors.cream,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.cream,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
