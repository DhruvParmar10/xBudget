import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/di/injection_container.dart';
import 'package:xbudget/core/utils/cycle_date_util.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/get_spend_breakdown_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/get_total_income_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/get_total_spend_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/update_transaction_category_usecase.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactionsUseCase getTransactionsUseCase;
  final GetSpendBreakdownUseCase getSpendBreakdownUseCase;
  final GetTotalSpendUseCase getTotalSpendUseCase;
  final GetTotalIncomeUseCase getTotalIncomeUseCase;
  final UpdateTransactionCategoryUseCase updateTransactionCategoryUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final AddTransactionUseCase? addTransactionUseCase;
  final AppPreferences? preferences;

  TransactionBloc({
    required this.getTransactionsUseCase,
    required this.getSpendBreakdownUseCase,
    required this.getTotalSpendUseCase,
    required this.getTotalIncomeUseCase,
    required this.updateTransactionCategoryUseCase,
    required this.deleteTransactionUseCase,
    this.addTransactionUseCase,
    this.preferences,
  }) : super(const TransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<FilterCategoryEvent>(_onFilterCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<AddTransactionEvent>(_onAddTransaction);
  }

  AppPreferences? _resolvePreferences() {
    if (preferences != null) return preferences;
    try {
      if (sl.isRegistered<AppPreferences>()) {
        return sl<AppPreferences>();
      }
    } catch (_) {}
    return null;
  }

  DateTime _getStartOfMonth([DateTime? dt]) {
    final prefs = _resolvePreferences();
    final mode = prefs?.cycleMode ?? CycleMode.offset31To30;
    final startDay = prefs?.cycleStartDay ?? 31;
    final endDay = prefs?.cycleEndDay ?? 30;

    return CycleDateUtil.getCycleStartDate(
      now: dt,
      mode: mode,
      startDay: startDay,
      endDay: endDay,
    );
  }

  DateTime _getEndOfMonth([DateTime? dt]) {
    final prefs = _resolvePreferences();
    final mode = prefs?.cycleMode ?? CycleMode.offset31To30;
    final startDay = prefs?.cycleStartDay ?? 31;
    final endDay = prefs?.cycleEndDay ?? 30;

    return CycleDateUtil.getCycleEndDate(
      now: dt,
      mode: mode,
      startDay: startDay,
      endDay: endDay,
    );
  }

  Future<void> _loadAndEmitTransactions(
    Emitter<TransactionState> emit, {
    BudgetCategory? category,
    DateTime? startDate,
    DateTime? endDate,
    String? query,
    String? transactionType,
  }) async {
    final transactions = await getTransactionsUseCase(
      GetTransactionsParams(
        startDate: startDate,
        endDate: endDate,
        category: category,
        query: query,
        transactionType: transactionType,
      ),
    );

    final monthStartDate = startDate ?? _getStartOfMonth();
    final monthEndDate = endDate ?? _getEndOfMonth();

    final categorySpend = await getSpendBreakdownUseCase(
      GetSpendBreakdownParams(
        startDate: monthStartDate,
        endDate: monthEndDate,
      ),
    );

    final totalExpense = await getTotalSpendUseCase(
      GetTotalSpendParams(
        startDate: monthStartDate,
        endDate: monthEndDate,
      ),
    );

    final totalIncome = await getTotalIncomeUseCase(
      GetTotalIncomeParams(
        startDate: monthStartDate,
        endDate: monthEndDate,
      ),
    );

    emit(
      TransactionLoaded(
        transactions: transactions,
        categorySpend: categorySpend,
        totalExpense: totalExpense,
        totalIncome: totalIncome,
        selectedCategory: category,
      ),
    );
  }

  Future<void> _onLoadTransactions(
    LoadTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      emit(const TransactionLoading());

      await _loadAndEmitTransactions(
        emit,
        category: event.category,
        startDate: event.startDate,
        endDate: event.endDate,
        query: event.query,
        transactionType: event.transactionType,
      );
    } catch (e) {
      emit(TransactionError('Failed to load transactions: $e'));
    }
  }

  Future<void> _onFilterCategory(
    FilterCategoryEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _loadAndEmitTransactions(
        emit,
        category: event.category,
      );
    } catch (e) {
      emit(TransactionError('Failed to filter transactions: $e'));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await updateTransactionCategoryUseCase(
        UpdateTransactionCategoryParams(
          id: event.transactionId,
          category: event.category,
        ),
      );

      final currentCategory = state is TransactionLoaded
          ? (state as TransactionLoaded).selectedCategory
          : null;

      await _loadAndEmitTransactions(
        emit,
        category: currentCategory,
      );
    } catch (e) {
      emit(TransactionError('Failed to update category: $e'));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await deleteTransactionUseCase(DeleteTransactionParams(event.transactionId));

      final currentCategory = state is TransactionLoaded
          ? (state as TransactionLoaded).selectedCategory
          : null;

      await _loadAndEmitTransactions(
        emit,
        category: currentCategory,
      );
    } catch (e) {
      emit(TransactionError('Failed to delete transaction: $e'));
    }
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final useCase = addTransactionUseCase ?? (sl.isRegistered<AddTransactionUseCase>() ? sl<AddTransactionUseCase>() : null);
      if (useCase != null) {
        await useCase(
          AddTransactionParams(
            amount: event.amount,
            merchant: event.merchant,
            transactionType: event.transactionType,
            category: event.category,
            isP2P: event.isP2P,
            date: event.date,
            note: event.note,
          ),
        );
      }

      final currentCategory = state is TransactionLoaded
          ? (state as TransactionLoaded).selectedCategory
          : null;

      await _loadAndEmitTransactions(
        emit,
        category: currentCategory,
      );
    } catch (e) {
      emit(TransactionError('Failed to add transaction: $e'));
    }
  }
}
