import 'package:flutter/material.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';

class CategoryUiHelper {
  static IconData getIcon(BudgetCategory cat) {
    switch (cat) {
      case BudgetCategory.food:
        return Icons.restaurant;
      case BudgetCategory.groceries:
        return Icons.shopping_basket;
      case BudgetCategory.transport:
        return Icons.directions_car;
      case BudgetCategory.shopping:
        return Icons.shopping_bag;
      case BudgetCategory.bills:
        return Icons.receipt_long;
      case BudgetCategory.entertainment:
        return Icons.movie;
      case BudgetCategory.health:
        return Icons.medical_services;
      case BudgetCategory.rent:
        return Icons.home;
      case BudgetCategory.investment:
        return Icons.trending_up;
      case BudgetCategory.salary:
        return Icons.account_balance_wallet;
      case BudgetCategory.p2pTransfer:
        return Icons.swap_horiz;
      case BudgetCategory.uncategorized:
        return Icons.category;
    }
  }

  static Color getColor(BudgetCategory cat) {
    return AppColors.getCategoryColor(cat);
  }
}

