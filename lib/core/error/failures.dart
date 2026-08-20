import 'package:equatable/equatable.dart';

/// Base Failure class for Clean Architecture.
abstract class Failure extends Equatable {
  final String message;
  const Failure([this.message = '']);

  @override
  List<Object?> get props => [message];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to access local cache']);
}

class SmsFailure extends Failure {
  const SmsFailure([super.message = 'Failed to read SMS']);
}

class SyncFailure extends Failure {
  const SyncFailure([super.message = 'SMS synchronization failed']);
}

class GoogleAuthFailure extends Failure {
  const GoogleAuthFailure([super.message = 'Google authentication failed']);
}

class GoogleSheetsFailure extends Failure {
  const GoogleSheetsFailure([super.message = 'Google Sheets operation failed']);
}
