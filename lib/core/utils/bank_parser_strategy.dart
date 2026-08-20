import 'parsed_transaction.dart';

/// Strategy interface for bank-specific SMS parsers.
///
/// Each bank has unique SMS templates, sender IDs, and formatting nuances.
/// Implementing this interface allows adding new banks cleanly without
/// modifying existing parser logic.
abstract class BankParserStrategy {
  /// Name or identifier for the bank (e.g., 'ICICI', 'HDFC', 'SBI').
  String get bankName;

  /// Fast-pass guard check to determine if the SMS belongs to this bank
  /// and contains an eligible transaction pattern.
  bool isEligible(String sender, String body);

  /// Detailed extraction of transaction parameters from the SMS body.
  /// Returns [ParsedTransaction] or `null` if parsing fails.
  ParsedTransaction? parse(String body, DateTime timestamp);
}
