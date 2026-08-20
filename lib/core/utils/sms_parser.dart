import 'bank_parser_strategy.dart';
import 'parsed_transaction.dart';
import 'strategies/icici_parser_strategy.dart';

/// Composite SMS parser that coordinates bank-specific parsing strategies.
///
/// Iterates through registered [BankParserStrategy] implementations to find
/// an eligible parser for incoming SMS messages.
class SmsParser {
  final List<BankParserStrategy> _strategies;

  /// Creates an [SmsParser] with the given list of [strategies].
  /// Defaults to `[IciciParserStrategy()]`.
  SmsParser({List<BankParserStrategy>? strategies})
      : _strategies = strategies ?? [IciciParserStrategy()];

  /// Default singleton instance for quick access across the app.
  static final SmsParser instance = SmsParser();

  /// List of active bank strategies registered in this parser.
  List<BankParserStrategy> get strategies => List.unmodifiable(_strategies);

  /// Stage 1: Fast Pass Guard Clause
  /// Returns `true` if any registered bank strategy considers the SMS eligible.
  bool isEligibleTransactionSms(String sender, String body) {
    return _strategies.any((strategy) => strategy.isEligible(sender, body));
  }

  /// Stage 2: Detailed Extraction
  /// Iterates through eligible strategies in order and attempts to parse the SMS.
  /// Returns [ParsedTransaction] on success, or `null` if no strategy could parse it.
  ParsedTransaction? parse({
    required String sender,
    required String body,
    required DateTime timestamp,
  }) {
    for (final strategy in _strategies) {
      if (strategy.isEligible(sender, body)) {
        final result = strategy.parse(body, timestamp);
        if (result != null) return result;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // STATIC CONVENIENCE METHODS
  // ---------------------------------------------------------------------------

  /// Static helper for fast-pass guard check using default strategies.
  static bool isEligible(String sender, String body) =>
      instance.isEligibleTransactionSms(sender, body);

  /// Static helper for detailed parsing using default strategies.
  static ParsedTransaction? parseMessage({
    required String sender,
    required String body,
    required DateTime timestamp,
  }) =>
      instance.parse(sender: sender, body: body, timestamp: timestamp);
}
