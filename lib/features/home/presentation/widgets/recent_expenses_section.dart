import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:xbudget/features/transactions/presentation/widgets/empty_transactions_view.dart';
import 'package:xbudget/features/transactions/presentation/widgets/transaction_tile.dart';

class RecentExpensesSection extends StatelessWidget {
  final VoidCallback? onSeeMore;

  const RecentExpensesSection({
    super.key,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is TransactionError) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.expense),
              ),
            ),
          );
        }

        final allTransactions = state is TransactionLoaded ? state.transactions : [];
        final expenseTransactions = allTransactions.where((txn) => txn.isExpense).toList();
        final last10Expenses = expenseTransactions.take(10).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Last 10 Expenses',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (expenseTransactions.length > 10)
                    GestureDetector(
                      onTap: onSeeMore,
                      child: Text(
                        '${expenseTransactions.length} total',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (last10Expenses.isEmpty)
              const EmptyTransactionsView()
            else
              Column(
                children: [
                  ...last10Expenses.map((txn) => TransactionTile(txn: txn)),
                  if (expenseTransactions.length > 10)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextButton.icon(
                          onPressed: onSeeMore,
                          icon: const Icon(Icons.more_horiz, color: AppColors.cream),
                          label: const Text(
                            'View All Expenses',
                            style: TextStyle(
                              color: AppColors.cream,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
