import 'package:flutter/material.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';

/// Centralized Color Palette for xBudget
/// All colors in the app are derived from these base constants.
/// Modifying these 4 primary palette constants will update the entire app theme.
class AppColors {
  // ---------------------------------------------------------------------------
  // CHOCOLATE TRUFFLE PALETTE CONSTANTS
  // ---------------------------------------------------------------------------
  static const Color milkChocolate = Color(0xFF713600); // #713600
  static const Color caramelOrange = Color(0xFFC05800); // #C05800
  static const Color cream = Color(0xFFFDFBD4);         // #FDFBD4
  static const Color darkChocolate = Color(0xFF38240D); // #38240D

  // ---------------------------------------------------------------------------
  // SEMANTIC APP THEME TOKENS
  // ---------------------------------------------------------------------------
  /// Primary brand accent
  static const Color primary = caramelOrange;
  static const Color onPrimary = cream;

  /// Secondary accent / container color
  static const Color secondary = milkChocolate;
  static const Color onSecondary = cream;

  /// Main background
  static const Color background = darkChocolate;
  static const Color onBackground = cream;

  /// Surfaces (AppBars, Dialogs, Bottom Sheets)
  static const Color surface = Color(0xFF2E1C0A);
  static const Color surfaceLight = Color(0xFF4A3216);
  static const Color onSurface = cream;
  static const Color onSurfaceVariant = Color(0xFFD4C8A8);

  /// Transaction / Card colors (wireframe cream cards)
  static const Color cardBackground = cream;
  static const Color cardTextPrimary = Color(0xFF2B1810);
  static const Color cardTextSecondary = Color(0xFF7A6A5A);
  static const Color cardDivider = Color(0xFFE5DEB8);

  /// Dividers & Borders
  static const Color divider = Color(0xFF5A3B18);
  static const Color border = Color(0xFF5A3B18);

  /// Financial metrics
  static const Color expense = Color(0xFFE64A19);
  static const Color income = Color(0xFF4CAF50);
  static const Color netFlowPositive = Color(0xFF66BB6A);
  static const Color netFlowNegative = Color(0xFFFF7043);

  /// Bottom Navigation Bar
  static const Color navBarBackground = Color(0xFF281809);
  static const Color navBarSelected = caramelOrange;
  static const Color navBarUnselected = Color(0xFFA8947E);

  // ---------------------------------------------------------------------------
  // HARMONIOUS CATEGORY PALETTE (Used in Pie Chart & Badges)
  // ---------------------------------------------------------------------------
  static const List<Color> pieChartPalette = [
    caramelOrange,
    milkChocolate,
    Color(0xFFE07A28),
    Color(0xFF8D4913),
    Color(0xFFA0522D),
    Color(0xFFB8621B),
    Color(0xFFD4A373),
    Color(0xFF6B4226),
    Color(0xFF99582A),
    Color(0xFFBC6C25),
  ];

  static Color getCategoryColor(BudgetCategory category) {
    switch (category) {
      case BudgetCategory.food:
        return caramelOrange;
      case BudgetCategory.groceries:
        return const Color(0xFFE07A28);
      case BudgetCategory.bills:
        return milkChocolate;
      case BudgetCategory.transport:
        return const Color(0xFF8D4913);
      case BudgetCategory.shopping:
        return const Color(0xFFB8621B);
      case BudgetCategory.entertainment:
        return const Color(0xFFA0522D);
      case BudgetCategory.health:
        return const Color(0xFF99582A);
      case BudgetCategory.rent:
        return const Color(0xFF6B4226);
      case BudgetCategory.investment:
        return const Color(0xFFD4A373);
      case BudgetCategory.salary:
        return const Color(0xFF4CAF50);
      case BudgetCategory.p2pTransfer:
        return const Color(0xFFBC6C25);
      case BudgetCategory.uncategorized:
        return const Color(0xFF8A735D);
    }
  }
}
