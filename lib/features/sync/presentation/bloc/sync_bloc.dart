import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/sync/domain/usecases/clear_all_data_usecase.dart';
import 'package:xbudget/features/sync/domain/usecases/inject_sample_sms_usecase.dart';
import 'package:xbudget/features/sync/domain/usecases/sync_sms_usecase.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncSmsUseCase syncSmsUseCase;
  final InjectSampleSmsUseCase injectSampleSmsUseCase;
  final ClearAllDataUseCase clearAllDataUseCase;
  final AppPreferences preferences;

  SyncBloc({
    required this.syncSmsUseCase,
    required this.injectSampleSmsUseCase,
    required this.clearAllDataUseCase,
    required this.preferences,
  }) : super(SyncInitial(lastSyncTimestamp: preferences.lastSyncTimestamp)) {
    on<LoadSyncInfoEvent>(_onLoadSyncInfo);
    on<TriggerSmsSyncEvent>(_onTriggerSmsSync);
    on<InjectSampleSmsEvent>(_onInjectSampleSms);
    on<ResetAllDataEvent>(_onResetAllData);
  }

  void _onLoadSyncInfo(
    LoadSyncInfoEvent event,
    Emitter<SyncState> emit,
  ) {
    emit(SyncInitial(lastSyncTimestamp: preferences.lastSyncTimestamp));
  }

  Future<void> _onTriggerSmsSync(
    TriggerSmsSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    emit(
      SyncInProgress(
        message: event.isAutoSync ? 'Auto-syncing SMS...' : 'Syncing SMS...',
        isAutoSync: event.isAutoSync,
        lastSyncTimestamp: preferences.lastSyncTimestamp,
      ),
    );

    final result = await syncSmsUseCase(
      SyncSmsParams(forceInitialLookback: event.forceInitial),
    );

    if (result.isSuccess) {
      emit(
        SyncSuccess(
          message:
              'Synced ${result.totalSmsFound} SMS (${result.newTransactionsAdded} new)',
          syncResult: result,
          lastSyncTimestamp: preferences.lastSyncTimestamp,
        ),
      );
    } else {
      emit(
        SyncFailure(
          errorMessage: result.errorMessage ?? 'Sync failed',
          lastSyncTimestamp: preferences.lastSyncTimestamp,
        ),
      );
    }
  }

  Future<void> _onInjectSampleSms(
    InjectSampleSmsEvent event,
    Emitter<SyncState> emit,
  ) async {
    emit(
      SyncInProgress(
        message: 'Loading past 2 months sample ICICI SMS...',
        lastSyncTimestamp: preferences.lastSyncTimestamp,
      ),
    );

    final result = await injectSampleSmsUseCase(const NoParams());

    if (result.isSuccess) {
      emit(
        SyncSuccess(
          message:
              'Loaded ${result.totalSmsFound} SMS (${result.newTransactionsAdded} added)',
          syncResult: result,
          lastSyncTimestamp: preferences.lastSyncTimestamp,
        ),
      );
    } else {
      emit(
        SyncFailure(
          errorMessage: result.errorMessage ?? 'Failed to load sample SMS',
          lastSyncTimestamp: preferences.lastSyncTimestamp,
        ),
      );
    }
  }

  Future<void> _onResetAllData(
    ResetAllDataEvent event,
    Emitter<SyncState> emit,
  ) async {
    emit(
      SyncInProgress(
        message: 'Resetting storage...',
        lastSyncTimestamp: preferences.lastSyncTimestamp,
      ),
    );

    await clearAllDataUseCase(const NoParams());

    emit(
      SyncSuccess(
        message: 'Storage reset successfully',
        lastSyncTimestamp: preferences.lastSyncTimestamp,
      ),
    );
  }
}
