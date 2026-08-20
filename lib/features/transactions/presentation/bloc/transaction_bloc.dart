import 'package:flutter_bloc/flutter_bloc.dart';
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

  TransactionBloc({
    required this.getTransactionsUseCase,
    required this.getSpendBreakdownUseCase,
    required this.getTotalSpendUseCase,
    required this.getTotalIncomeUseCase,
    required this.updateTransactionCategoryUseCase,
    required this.deleteTransactionUseCase,
  }) : super(const TransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<FilterCategoryEvent>(_onFilterCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
  }

  DateTime _getStartOfMonth([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime _getEndOfMonth([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
  }

  Future<void> _onLoadTransactions(
    LoadTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      emit(const TransactionLoading());

      final currentSelectedCategory = event.category;

      final transactions = await getTransactionsUseCase(
        GetTransactionsParams(
          startDate: event.startDate,
          endDate: event.endDate,
          category: currentSelectedCategory,
          query: event.query,
          transactionType: event.transactionType,
        ),
      );

      final monthStartDate = event.startDate ?? _getStartOfMonth();
      final monthEndDate = event.endDate ?? _getEndOfMonth();

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
          selectedCategory: currentSelectedCategory,
        ),
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
      final selectedCategory = event.category;

      final transactions = await getTransactionsUseCase(
        GetTransactionsParams(category: selectedCategory),
      );

      final monthStartDate = _getStartOfMonth();
      final monthEndDate = _getEndOfMonth();

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
          selectedCategory: selectedCategory,
        ),
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

      add(FilterCategoryEvent(currentCategory));
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

      add(FilterCategoryEvent(currentCategory));
    } catch (e) {
      emit(TransactionError('Failed to delete transaction: $e'));
    }
  }
}
