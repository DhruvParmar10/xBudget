class ParsedTransaction {
  final double amount;
  final String merchant;
  final String transactionType; // 'expense' or 'income'
  final bool isP2P;
  final DateTime date;
  final String rawMessage;
  final double? balance;

  const ParsedTransaction({
    required this.amount,
    required this.merchant,
    required this.transactionType,
    required this.isP2P,
    required this.date,
    required this.rawMessage,
    this.balance,
  });

  @override
  String toString() {
    return 'ParsedTransaction(amount: $amount, merchant: "$merchant", type: $transactionType, isP2P: $isP2P, date: $date, balance: $balance)';
  }
}
