import 'package:flutter/material.dart';
import 'package:xbudget/domain/entities/budget_category.dart';

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
    switch (cat) {
      case BudgetCategory.food:
        return Colors.orange;
      case BudgetCategory.groceries:
        return Colors.green;
      case BudgetCategory.transport:
        return Colors.blue;
      case BudgetCategory.shopping:
        return Colors.purple;
      case BudgetCategory.bills:
        return Colors.amber.shade700;
      case BudgetCategory.entertainment:
        return Colors.pink;
      case BudgetCategory.health:
        return Colors.teal;
      case BudgetCategory.rent:
        return Colors.indigo;
      case BudgetCategory.investment:
        return Colors.cyan;
      case BudgetCategory.salary:
        return Colors.green.shade700;
      case BudgetCategory.p2pTransfer:
        return Colors.deepPurple;
      case BudgetCategory.uncategorized:
        return Colors.grey;
    }
  }
}
