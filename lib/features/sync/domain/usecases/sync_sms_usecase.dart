import 'package:equatable/equatable.dart';
import 'package:xbudget/core/services/sms_sync_service.dart';
import 'package:xbudget/core/usecases/usecase.dart';

class SyncSmsParams extends Equatable {
  final bool forceInitialLookback;

  const SyncSmsParams({this.forceInitialLookback = false});

  @override
  List<Object?> get props => [forceInitialLookback];
}

class SyncSmsUseCase implements UseCase<SyncResult, SyncSmsParams> {
  final SmsSyncService syncService;

  SyncSmsUseCase(this.syncService);

  @override
  Future<SyncResult> call(SyncSmsParams params) async {
    return await syncService.syncSms(
      forceInitialLookback: params.forceInitialLookback,
    );
  }
}
