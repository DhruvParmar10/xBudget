import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_state.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_bloc.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_state.dart';
import 'note_balance_bottom_sheet.dart';

class BalanceHeroCard extends StatelessWidget {
  const BalanceHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, balanceState) {
        final currentBalance = balanceState is BalanceLoaded ? balanceState.currentBalance : null;
        final balanceSource = balanceState is BalanceLoaded ? balanceState.balanceSource : 'manual';

        return BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, txnState) {
            final totalExpense = txnState is TransactionLoaded ? txnState.totalExpense : 0.0;
            final totalIncome = txnState is TransactionLoaded ? txnState.totalIncome : 0.0;
            final netFlow = totalIncome - totalExpense;

            return BlocBuilder<SyncBloc, SyncState>(
              builder: (context, syncState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ~ CURRENT BALANCE Header & Source/Edit Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '~ ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cream,
                              ),
                            ),
                            const Text(
                              'CURRENT BALANCE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: AppColors.cream,
                              ),
                            ),
                            if (currentBalance != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.caramelOrange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.caramelOrange.withValues(alpha: 0.6),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  balanceSource == 'sms' ? 'SMS' : 'Manual',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cream,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        InkWell(
                          onTap: () => NoteBalanceBottomSheet.show(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.caramelOrange,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  currentBalance != null ? Icons.edit_outlined : Icons.add,
                                  size: 13,
                                  color: AppColors.cream,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentBalance != null ? 'Update' : 'Note Balance',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.cream,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Big Current Balance Amount Display
                    GestureDetector(
                      onTap: () => NoteBalanceBottomSheet.show(context),
                      child: Text(
                        currentBalance != null
                            ? '₹${currentBalance.toStringAsFixed(2)}'
                            : '₹ --.--',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cream,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: AppColors.divider, height: 1),
                    ),

                    // Monthly Expense & Monthly Income Side-by-Side Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Monthly Expense Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Monthly Expense',
                                style: TextStyle(
                                  color: AppColors.cream,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '₹${totalExpense.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.cream,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Monthly Income Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Monthly Income',
                                style: TextStyle(
                                  color: AppColors.cream,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '₹${totalIncome.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.cream,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Net Flow summary
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Net Flow',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              netFlow >= 0
                                  ? '+₹${netFlow.toStringAsFixed(0)}'
                                  : '-₹${netFlow.abs().toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: netFlow >= 0
                                    ? AppColors.netFlowPositive
                                    : AppColors.netFlowNegative,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

