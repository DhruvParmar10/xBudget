import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class LoadSyncInfoEvent extends SyncEvent {
  const LoadSyncInfoEvent();
}

class TriggerSmsSyncEvent extends SyncEvent {
  final bool isAutoSync;
  final bool forceInitial;

  const TriggerSmsSyncEvent({
    this.isAutoSync = false,
    this.forceInitial = false,
  });

  @override
  List<Object?> get props => [isAutoSync, forceInitial];
}

class InjectSampleSmsEvent extends SyncEvent {
  const InjectSampleSmsEvent();
}

class ResetAllDataEvent extends SyncEvent {
  const ResetAllDataEvent();
}
