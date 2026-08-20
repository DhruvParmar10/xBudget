import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  // ---------------------------------------------------------------------------
  // PREFERENCE KEYS
  // ---------------------------------------------------------------------------
  static const String _keyLastSyncTimestamp = 'last_sync_timestamp';
  static const String _keyMonthlyBudget = 'monthly_budget';
  static const String _keyIsOnboardingCompleted = 'is_onboarding_completed';

  // ---------------------------------------------------------------------------
  // LAZY SYNC TIMESTAMP (Milliseconds since epoch)
  // ---------------------------------------------------------------------------

  /// Gets the last date/time the app synced SMS messages.
  /// Returns null if no sync has ever occurred.
  DateTime? get lastSyncTimestamp {
    final epoch = _prefs.getInt(_keyLastSyncTimestamp);
    if (epoch == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(epoch);
  }

  /// Updates the last sync timestamp to the provided [dateTime] or defaults to [DateTime.now()].
  Future<bool> setLastSyncTimestamp([DateTime? dateTime]) async {
    final timestamp = (dateTime ?? DateTime.now()).millisecondsSinceEpoch;
    return await _prefs.setInt(_keyLastSyncTimestamp, timestamp);
  }

  // ---------------------------------------------------------------------------
  // MONTHLY BUDGET BASELINE
  // ---------------------------------------------------------------------------

  /// Gets the user's monthly budget limit.
  /// Defaults to 0.0 if not set during onboarding.
  double get monthlyBudget {
    return _prefs.getDouble(_keyMonthlyBudget) ?? 0.0;
  }

  /// Sets or updates the user's monthly budget.
  Future<bool> setMonthlyBudget(double budget) async {
    return await _prefs.setDouble(_keyMonthlyBudget, budget);
  }

  // ---------------------------------------------------------------------------
  // ONBOARDING STATUS
  // ---------------------------------------------------------------------------

  /// Checks whether the user has completed initial onboarding.
  bool get isOnboardingCompleted {
    return _prefs.getBool(_keyIsOnboardingCompleted) ?? false;
  }

  /// Flags onboarding as completed.
  Future<bool> setOnboardingCompleted(bool completed) async {
    return await _prefs.setBool(_keyIsOnboardingCompleted, completed);
  }

  // ---------------------------------------------------------------------------
  // CURRENT BALANCE TRACKING
  // ---------------------------------------------------------------------------
  static const String _keyCurrentBalance = 'current_balance';
  static const String _keyBalanceUpdatedAt = 'balance_updated_at';
  static const String _keyBalanceSource = 'balance_source';

  /// Gets the user's recorded current balance, or null if not yet set.
  double? get currentBalance {
    return _prefs.getDouble(_keyCurrentBalance);
  }

  /// Gets the timestamp when the current balance was last updated.
  DateTime? get balanceUpdatedAt {
    final epoch = _prefs.getInt(_keyBalanceUpdatedAt);
    if (epoch == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(epoch);
  }

  /// Gets the source of the current balance ('manual' or 'sms').
  String get balanceSource {
    return _prefs.getString(_keyBalanceSource) ?? 'manual';
  }

  /// Sets or updates the current balance with an optional [source] and [updatedAt].
  Future<bool> setCurrentBalance(
    double balance, {
    String source = 'manual',
    DateTime? updatedAt,
  }) async {
    final ts = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch;
    final r1 = await _prefs.setDouble(_keyCurrentBalance, balance);
    final r2 = await _prefs.setInt(_keyBalanceUpdatedAt, ts);
    final r3 = await _prefs.setString(_keyBalanceSource, source);
    return r1 && r2 && r3;
  }

  /// Clears the recorded current balance.
  Future<bool> clearCurrentBalance() async {
    final r1 = await _prefs.remove(_keyCurrentBalance);
    final r2 = await _prefs.remove(_keyBalanceUpdatedAt);
    final r3 = await _prefs.remove(_keyBalanceSource);
    return r1 && r2 && r3;
  }

  // ---------------------------------------------------------------------------
  // RESET / CLEAR PREFERENCES
  // ---------------------------------------------------------------------------

  /// Resets all stored user preferences (useful for testing or app resets).
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
