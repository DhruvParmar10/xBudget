import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/balance/domain/usecases/clear_balance_usecase.dart';
import 'package:xbudget/features/balance/domain/usecases/get_balance_usecase.dart';
import 'package:xbudget/features/balance/domain/usecases/set_balance_usecase.dart';
import 'balance_event.dart';
import 'balance_state.dart';

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  final GetBalanceUseCase getBalanceUseCase;
  final SetBalanceUseCase setBalanceUseCase;
  final ClearBalanceUseCase clearBalanceUseCase;

  BalanceBloc({
    required this.getBalanceUseCase,
    required this.setBalanceUseCase,
    required this.clearBalanceUseCase,
  }) : super(const BalanceInitial()) {
    on<LoadBalanceEvent>(_onLoadBalance);
    on<UpdateBalanceEvent>(_onUpdateBalance);
    on<ClearBalanceEvent>(_onClearBalance);
  }

  Future<void> _onLoadBalance(
    LoadBalanceEvent event,
    Emitter<BalanceState> emit,
  ) async {
    try {
      final data = await getBalanceUseCase(const NoParams());
      emit(
        BalanceLoaded(
          currentBalance: data.currentBalance,
          balanceUpdatedAt: data.balanceUpdatedAt,
          balanceSource: data.balanceSource,
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
        ),
      );
      final data = await getBalanceUseCase(const NoParams());
      emit(
        BalanceLoaded(
          currentBalance: data.currentBalance,
          balanceUpdatedAt: data.balanceUpdatedAt,
          balanceSource: data.balanceSource,
        ),
      );
    } catch (e) {
      emit(BalanceError('Failed to update balance: $e'));
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
        ),
      );
    } catch (e) {
      emit(BalanceError('Failed to clear balance: $e'));
    }
  }
}
