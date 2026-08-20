import 'package:equatable/equatable.dart';
import 'package:xbudget/core/services/sms_sync_service.dart';

abstract class SyncState extends Equatable {
  final DateTime? lastSyncTimestamp;

  const SyncState({this.lastSyncTimestamp});

  @override
  List<Object?> get props => [lastSyncTimestamp];
}

class SyncInitial extends SyncState {
  const SyncInitial({super.lastSyncTimestamp});
}

class SyncInProgress extends SyncState {
  final String message;
  final bool isAutoSync;

  const SyncInProgress({
    required this.message,
    this.isAutoSync = false,
    super.lastSyncTimestamp,
  });

  @override
  List<Object?> get props => [message, isAutoSync, lastSyncTimestamp];
}

class SyncSuccess extends SyncState {
  final String message;
  final SyncResult? syncResult;

  const SyncSuccess({
    required this.message,
    this.syncResult,
    super.lastSyncTimestamp,
  });

  @override
  List<Object?> get props => [message, syncResult, lastSyncTimestamp];
}

class SyncFailure extends SyncState {
  final String errorMessage;

  const SyncFailure({
    required this.errorMessage,
    super.lastSyncTimestamp,
  });

  @override
  List<Object?> get props => [errorMessage, lastSyncTimestamp];
}
