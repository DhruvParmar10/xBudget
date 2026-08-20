import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_state.dart';
import 'category_ui_helper.dart';

class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final totalTxns = state is TransactionLoaded ? state.transactions.length : 0;
        final selectedCat = state is TransactionLoaded ? state.selectedCategory : null;
        final categorySpend = state is TransactionLoaded ? state.categorySpend : <BudgetCategory, double>{};

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.4),
                selectedColor: AppColors.primary,
                side: BorderSide(
                  color: selectedCat == null ? AppColors.primary : AppColors.border,
                ),
                labelStyle: TextStyle(
                  color: selectedCat == null ? AppColors.cream : AppColors.onSurfaceVariant,
                  fontWeight: selectedCat == null ? FontWeight.bold : FontWeight.normal,
                ),
                label: Text(
                  selectedCat == null
                      ? 'All ($totalTxns)'
                      : 'All',
                ),
                selected: selectedCat == null,
                onSelected: (_) {
                  context.read<TransactionBloc>().add(const FilterCategoryEvent(null));
                },
              ),
              const SizedBox(width: 8),
              ...BudgetCategory.values.map((cat) {
                final spend = categorySpend[cat] ?? 0.0;
                final isSelected = selectedCat == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.4),
                    selectedColor: AppColors.primary,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.cream : AppColors.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    avatar: Icon(
                      CategoryUiHelper.getIcon(cat),
                      size: 16,
                      color: isSelected ? AppColors.cream : CategoryUiHelper.getColor(cat),
                    ),
                    label: Text(
                      spend > 0
                          ? '${cat.displayName} (₹${spend.toStringAsFixed(0)})'
                          : cat.displayName,
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      context.read<TransactionBloc>().add(
                            FilterCategoryEvent(selected ? cat : null),
                          );
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

