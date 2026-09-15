import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import '../../domain/usecases/add_balance_log_usecase.dart';
import '../../domain/usecases/clear_balance_usecase.dart';
import '../../domain/usecases/delete_balance_log_usecase.dart';
import '../../domain/usecases/get_balance_usecase.dart';
import '../../domain/usecases/set_balance_usecase.dart';
import '../../domain/usecases/update_balance_log_usecase.dart';
import 'balance_event.dart';
import 'balance_state.dart';

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  final GetBalanceUseCase getBalanceUseCase;
  final SetBalanceUseCase setBalanceUseCase;
  final ClearBalanceUseCase clearBalanceUseCase;
  final AddBalanceLogUseCase addBalanceLogUseCase;
  final UpdateBalanceLogUseCase updateBalanceLogUseCase;
  final DeleteBalanceLogUseCase deleteBalanceLogUseCase;

  BalanceBloc({
    required this.getBalanceUseCase,
    required this.setBalanceUseCase,
    required this.clearBalanceUseCase,
    required this.addBalanceLogUseCase,
    required this.updateBalanceLogUseCase,
    required this.deleteBalanceLogUseCase,
  }) : super(const BalanceInitial()) {
    on<LoadBalanceEvent>(_onLoadBalance);
    on<UpdateBalanceEvent>(_onUpdateBalance);
    on<AddBalanceLogEvent>(_onAddBalanceLog);
    on<UpdateBalanceLogEvent>(_onUpdateBalanceLog);
    on<DeleteBalanceLogEvent>(_onDeleteBalanceLog);
    on<ClearBalanceEvent>(_onClearBalance);
  }

  Future<void> _onLoadBalance(
    LoadBalanceEvent event,
    Emitter<BalanceState> emit,
  ) async {
    try {
      emit(const BalanceLoading());
      final data = await getBalanceUseCase(const NoParams());
      emit(
        BalanceLoaded(
          currentBalance: data.currentBalance,
          balanceUpdatedAt: data.balanceUpdatedAt,
          balanceSource: data.balanceSource,
          balanceLogs: data.balanceLogs,
        ),
      );
    } catch (e) {
      emit(BalanceError('Failed to load balance: $e'));
    }
  }

  Future<void> _onUpdateBalance(
    UpdateBalanceEvent event,
    Emitter<BalanceState> emit,
  ) async {
    try {
      await setBalanceUseCase(
        SetBalanceParams(
          balance: event.balance,
          source: event.source,
          updatedAt: event.updatedAt,
          note: event.note,
        ),
      );
      final data = await getBalanceUseCase(const NoParams());
      emit(
        BalanceLoaded(
          currentBalance: data.currentBalance,
          balanceUpdatedAt: data.balanceUpdatedAt,
          balanceSource: data.balanceSource,
          balanceLogs: data.balanceLogs,
        ),
      );
    } catch (e) {
      emit(BalanceError('Failed to update balance: $e'));
    }
  }

  Future<void> _onAddBalanceLog(
    AddBalanceLogEvent event,
    Emitter<BalanceState> emit,
  ) async {
    try {
      await addBalanceLogUseCase(event.log);
      final data = await getBalanceUseCase(const NoParams());
      emit(
        BalanceLoaded(
          currentBalance: data.currentBalance,
          balanceUpdatedAt: data.balanceUpdatedAt,
          balanceSource: data.balanceSource,
          balanceLogs: data.balanceLogs,
        ),
      );
    } catch (e) {
      emit(BalanceError('Failed to add balance log: $e'));
    }
  }

  Future<void> _onUpdateBalanceLog(
    UpdateBalanceLogEvent event,
    Emitter<BalanceState> emit,
  ) async {
    try {
      await updateBalanceLogUseCase(event.log);
      final data = await getBalanceUseCase(const NoParams());
      emit(
        BalanceLoaded(
          currentBalance: data.currentBalance,
          balanceUpdatedAt: data.balanceUpdatedAt,
          balanceSource: data.balanceSource,
          balanceLogs: data.balanceLogs,
        ),
      );
    } catch (e) {
      emit(BalanceError('Failed to update balance log: $e'));
    }
  }

  Future<void> _onDeleteBalanceLog(
    DeleteBalanceLogEvent event,
    Emitter<BalanceState> emit,
  ) async {
    try {
      await deleteBalanceLogUseCase(event.id);
      final data = await getBalanceUseCase(const NoParams());
      emit(
        BalanceLoaded(
          currentBalance: data.currentBalance,
          balanceUpdatedAt: data.balanceUpdatedAt,
          balanceSource: data.balanceSource,
          balanceLogs: data.balanceLogs,
        ),
      );
    } catch (e) {
      emit(BalanceError('Failed to delete balance log: $e'));
    }
  }

  Future<void> _onClearBalance(
    ClearBalanceEvent event,
    Emitter<BalanceState> emit,
  ) async {
    try {
      await clearBalanceUseCase(const NoParams());
      final data = await getBalanceUseCase(const NoParams());
      emit(
        BalanceLoaded(
          currentBalance: data.currentBalance,
          balanceUpdatedAt: data.balanceUpdatedAt,
          balanceSource: data.balanceSource,
          balanceLogs: data.balanceLogs,
        ),
      );
    } catch (e) {
      emit(BalanceError('Failed to clear balance: $e'));
    }
  }
}
