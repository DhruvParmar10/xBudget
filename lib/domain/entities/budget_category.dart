/// Predefined budget and spending categories for transactions.
enum BudgetCategory {
  food('Food & Dining'),
  groceries('Groceries'),
  transport('Transport & Fuel'),
  shopping('Shopping'),
  bills('Bills & Utilities'),
  entertainment('Entertainment'),
  health('Health & Medical'),
  rent('Rent & Housing'),
  investment('Investments & Savings'),
  salary('Salary & Income'),
  p2pTransfer('P2P Transfer'),
  uncategorized('Uncategorized');

  final String displayName;

  const BudgetCategory(this.displayName);

  /// Converts a string name to a [BudgetCategory], defaulting to [uncategorized].
  static BudgetCategory fromString(String? name) {
    if (name == null) return BudgetCategory.uncategorized;
    for (final category in BudgetCategory.values) {
      if (category.name.toLowerCase() == name.toLowerCase() ||
          category.displayName.toLowerCase() == name.toLowerCase()) {
        return category;
      }
    }
    return BudgetCategory.uncategorized;
  }
}
