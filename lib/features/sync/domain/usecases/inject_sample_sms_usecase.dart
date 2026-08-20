import 'package:xbudget/core/services/sms_sync_service.dart';
import 'package:xbudget/core/usecases/usecase.dart';

class InjectSampleSmsUseCase implements UseCase<SyncResult, NoParams> {
  final SmsSyncService syncService;

  InjectSampleSmsUseCase(this.syncService);

  @override
  Future<SyncResult> call(NoParams params) async {
    return await syncService.injectSampleMessages();
  }
}
