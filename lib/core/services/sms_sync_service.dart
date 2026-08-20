import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xbudget/features/transactions/data/models/transaction_model.dart';
import 'package:xbudget/features/transactions/domain/entities/transaction_entity.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';
import '../constants/app_preferences.dart';
import '../utils/parsed_transaction.dart';
import '../utils/sms_parser.dart';
import '../utils/transaction_categorizer.dart';

/// Summary returned after an SMS synchronization run.
class SyncResult {
  final int totalSmsFound;
  final int eligibleCount;
  final int newTransactionsAdded;
  final DateTime syncTimestamp;
  final String? errorMessage;

  const SyncResult({
    required this.totalSmsFound,
    required this.eligibleCount,
    required this.newTransactionsAdded,
    required this.syncTimestamp,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

/// Service to handle SMS ingestion, permission checks, incremental sync,
/// and parsing pipeline execution.
class SmsSyncService {
  final TransactionRepository _repository;
  final AppPreferences _preferences;
  final SmsQuery _smsQuery;

  SmsSyncService({
    required TransactionRepository repository,
    required AppPreferences preferences,
    SmsQuery? smsQuery,
  })  : _repository = repository,
        _preferences = preferences,
        _smsQuery = smsQuery ?? SmsQuery();

  /// Performs SMS sync:
  /// - If first time: looks back past 60 days (2 months).
  /// - If subsequent time: only queries messages newer than [lastSyncTimestamp].
  Future<SyncResult> syncSms({bool forceInitialLookback = false}) async {
    try {
      final lastSync = forceInitialLookback ? null : _preferences.lastSyncTimestamp;
      final now = DateTime.now();

      // Look back 60 days if no previous sync exists
      final lookbackDate = lastSync ?? now.subtract(const Duration(days: 60));

      List<_RawSmsMessage> rawMessages = [];

      if (!kIsWeb && Platform.isAndroid) {
        // Check and request SMS permissions on Android
        final status = await Permission.sms.request();
        if (!status.isGranted) {
          return SyncResult(
            totalSmsFound: 0,
            eligibleCount: 0,
            newTransactionsAdded: 0,
            syncTimestamp: now,
            errorMessage: 'SMS permission denied. Please enable SMS access.',
          );
        }

        // Query device SMS inbox
        final smsList = await _smsQuery.querySms(
          kinds: [SmsQueryKind.inbox],
          sort: true,
        );

        rawMessages = smsList
            .where((sms) {
              final date = sms.date;
              return date != null && date.isAfter(lookbackDate);
            })
            .map((sms) => _RawSmsMessage(
                  sender: sms.address ?? '',
                  body: sms.body ?? '',
                  date: sms.date ?? DateTime.now(),
                ))
            .toList();
      } else {
        // Running on iOS, desktop, simulator or test environment:
        // Use realistic sample dataset if no device SMS query is available
        rawMessages = _getSampleSmsMessages(lookbackDate);
      }

      int eligibleCount = 0;
      final List<TransactionEntity> toSave = [];
      final userRules = await _repository.getUserCategoryRules();
      ParsedTransaction? latestParsedWithBalance;

      for (final msg in rawMessages) {
        if (SmsParser.instance.isEligibleTransactionSms(msg.sender, msg.body)) {
          eligibleCount++;
          final parsed = SmsParser.instance.parse(
            sender: msg.sender,
            body: msg.body,
            timestamp: msg.date,
          );

          if (parsed != null) {
            if (parsed.balance != null) {
              if (latestParsedWithBalance == null ||
                  parsed.date.isAfter(latestParsedWithBalance.date)) {
                latestParsedWithBalance = parsed;
              }
            }
            final category = TransactionCategorizer.categorize(
              parsed,
              userRules: userRules,
            );
            final model = TransactionModel.fromParsedTransaction(
              parsed,
              category,
            );
            toSave.add(model);
          }
        }
      }

      // Bulk ingest with deduplication
      final newAdded = await _repository.saveTransactions(toSave);

      // Auto-update current balance from latest SMS if applicable
      if (latestParsedWithBalance != null && latestParsedWithBalance.balance != null) {
        final manualUpdate = _preferences.balanceUpdatedAt;
        final isManual = _preferences.balanceSource == 'manual';
        if (manualUpdate == null || !isManual || latestParsedWithBalance.date.isAfter(manualUpdate)) {
          await _preferences.setCurrentBalance(
            latestParsedWithBalance.balance!,
            source: 'sms',
            updatedAt: latestParsedWithBalance.date,
          );
        }
      }

      // Update sync timestamp
      await _preferences.setLastSyncTimestamp(now);

      return SyncResult(
        totalSmsFound: rawMessages.length,
        eligibleCount: eligibleCount,
        newTransactionsAdded: newAdded,
        syncTimestamp: now,
      );
    } catch (e) {
      return SyncResult(
        totalSmsFound: 0,
        eligibleCount: 0,
        newTransactionsAdded: 0,
        syncTimestamp: DateTime.now(),
        errorMessage: 'Sync failed: $e',
      );
    }
  }

  /// Injects sample real-world ICICI SMS messages for testing on any device/emulator.
  Future<SyncResult> injectSampleMessages() async {
    final now = DateTime.now();
    final sampleMessages = _getSampleSmsMessages(
      now.subtract(const Duration(days: 60)),
    );

    int eligibleCount = 0;
    final List<TransactionEntity> toSave = [];
    final userRules = await _repository.getUserCategoryRules();
    ParsedTransaction? latestParsedWithBalance;

    for (final msg in sampleMessages) {
      if (SmsParser.instance.isEligibleTransactionSms(msg.sender, msg.body)) {
        eligibleCount++;
        final parsed = SmsParser.instance.parse(
          sender: msg.sender,
          body: msg.body,
          timestamp: msg.date,
        );

        if (parsed != null) {
          if (parsed.balance != null) {
            if (latestParsedWithBalance == null ||
                parsed.date.isAfter(latestParsedWithBalance.date)) {
              latestParsedWithBalance = parsed;
            }
          }
          final category = TransactionCategorizer.categorize(
            parsed,
            userRules: userRules,
          );
          final model = TransactionModel.fromParsedTransaction(
            parsed,
            category,
          );
          toSave.add(model);
        }
      }
    }

    final newAdded = await _repository.saveTransactions(toSave);

    if (latestParsedWithBalance != null && latestParsedWithBalance.balance != null) {
      final manualUpdate = _preferences.balanceUpdatedAt;
      final isManual = _preferences.balanceSource == 'manual';
      if (manualUpdate == null || !isManual || latestParsedWithBalance.date.isAfter(manualUpdate)) {
        await _preferences.setCurrentBalance(
          latestParsedWithBalance.balance!,
          source: 'sms',
          updatedAt: latestParsedWithBalance.date,
        );
      }
    }

    await _preferences.setLastSyncTimestamp(now);

    return SyncResult(
      totalSmsFound: sampleMessages.length,
      eligibleCount: eligibleCount,
      newTransactionsAdded: newAdded,
      syncTimestamp: now,
    );
  }

  /// Realistic sample ICICI SMS messages spanning the past 60 days
  List<_RawSmsMessage> _getSampleSmsMessages(DateTime lookbackDate) {
    final now = DateTime.now();

    final samples = [
      _RawSmsMessage(
        sender: 'VM-ICICIB',
        body:
            'Dear Customer, Rs 189.00 debited from A/c XX892 on ${now.subtract(const Duration(days: 1)).day}-Aug-26; SWIGGY credited. Avl Bal Rs 24,500.00.',
        date: now.subtract(const Duration(days: 1)),
      ),
      _RawSmsMessage(
        sender: 'VM-ICICIB',
        body:
            'Dear Customer, Rs 450.00 debited from A/c XX892 on ${now.subtract(const Duration(days: 2)).day}-Aug-26; Blinkit credited. Avl Bal Rs 24,050.00.',
        date: now.subtract(const Duration(days: 2)),
      ),
      _RawSmsMessage(
        sender: 'VM-ICICIB',
        body:
            'Avl Bal: INR 23,800.00. Rs 250.00 spent on ICICI Card XX1002 at Starbucks Cafe.',
        date: now.subtract(const Duration(days: 4)),
      ),
      _RawSmsMessage(
        sender: 'VM-ICICIB',
        body:
            'Dear Customer, Rs 320.00 debited from A/c XX892; Uber debited. Avl Bal Rs 23,480.00',
        date: now.subtract(const Duration(days: 6)),
      ),
      _RawSmsMessage(
        sender: 'VM-ICICIB',
        body:
            'Dear Customer, Rs 1,499.00 debited from A/c XX892; Amazon Pay credited. Avl Bal Rs 21,981.00',
        date: now.subtract(const Duration(days: 10)),
      ),
      _RawSmsMessage(
        sender: 'VM-ICICIB',
        body:
            'Dear Customer, Rs 2,500.00 debited from A/c XX892; trf to Rahul Sharma via UPI. Avl Bal Rs 19,481.00',
        date: now.subtract(const Duration(days: 14)),
      ),
      _RawSmsMessage(
        sender: 'VM-ICICIB',
        body:
            'Total Bal: Rs.94,481.00. Your A/c XX892 is credited with Rs 75,000.00 on ${now.subtract(const Duration(days: 20)).day}-Aug-26 by salary transfer.',
        date: now.subtract(const Duration(days: 20)),
      ),
      _RawSmsMessage(
        sender: 'VM-ICICIB',
        body:
            'Dear Customer, Rs 899.00 debited from A/c XX892; Airtel Prepaid credited. Avl Bal Rs 18,582.00',
        date: now.subtract(const Duration(days: 25)),
      ),
      _RawSmsMessage(
        sender: 'VM-ICICIB',
        body:
            'Your One Time Password (OTP) for ICICI Bank NetBanking login is 839201. Do not share it.',
        date: now.subtract(const Duration(days: 2)),
      ),
    ];

    return samples.where((s) => s.date.isAfter(lookbackDate)).toList();
  }
}

class _RawSmsMessage {
  final String sender;
  final String body;
  final DateTime date;

  _RawSmsMessage({
    required this.sender,
    required this.body,
    required this.date,
  });
}
