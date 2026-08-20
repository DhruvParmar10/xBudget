import 'package:flutter/material.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import 'package:xbudget/features/transactions/domain/entities/transaction_entity.dart';
import 'category_ui_helper.dart';
import 'transaction_details_bottom_sheet.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntity txn;

  const TransactionTile({
    super.key,
    required this.txn,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryUiHelper.getColor(txn.category);
    final catIcon = CategoryUiHelper.getIcon(txn.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => TransactionDetailsBottomSheet.show(context, txn),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Category Icon in subtle circular badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    catIcon,
                    color: catColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Merchant & Category Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              txn.merchant,
                              style: const TextStyle(
                                color: AppColors.cardTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (txn.isP2P)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.milkChocolate.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'P2P',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.milkChocolate,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${txn.category.displayName} • ${txn.date.day}/${txn.date.month}/${txn.date.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.cardTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Amount
                Text(
                  '${txn.isExpense ? '-' : '+'}₹${txn.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: txn.isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

