import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/services/google_sheets_service.dart';
import 'package:xbudget/features/sync/domain/usecases/google_auth_usecases.dart';
import 'package:xbudget/features/sync/domain/usecases/sync_to_google_sheets_usecase.dart';
import 'package:xbudget/features/sync/presentation/bloc/google_sheets_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/google_sheets_event.dart';
import 'package:xbudget/features/sync/presentation/bloc/google_sheets_state.dart';
import 'package:xbudget/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:xbudget/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:xbudget/features/transactions/domain/entities/transaction_entity.dart';

class MockGoogleSheetsService extends GoogleSheetsService {
  bool signedIn = false;
  bool signInReturns = true;
  String? mockEmail;
  String? mockSheetId = 'sheet-abc';
  GoogleSheetsSyncSummary? mockSyncSummary;

  @override
  bool get isSignedIn => signedIn;

  @override
  String? get currentEmail => mockEmail;

  @override
  String? get spreadsheetId => mockSheetId;

  @override
  Future<bool> signIn() async {
    if (signInReturns) {
      signedIn = true;
      mockEmail = 'user@example.com';
      return true;
    }
    return false;
  }

  @override
  Future<bool> signInSilently() async {
    if (mockEmail != null) {
      signedIn = true;
      return true;
    }
    return false;
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
    mockEmail = null;
    mockSheetId = null;
  }

  @override
  Future<String?> initSheet({
    String sheetTitle = GoogleSheetsService.defaultSpreadsheetTitle,
    double? currentBalance,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
  }) async {
    return mockSheetId ?? 'sheet-abc';
  }

  @override
  Future<GoogleSheetsSyncSummary> syncTransactions(
    List<TransactionEntity> transactions, {
    double? currentBalance,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
  }) async {
    return mockSyncSummary ??
        GoogleSheetsSyncSummary(
          totalLocalTransactions: transactions.length,
          newRowsAppended: 2,
          spreadsheetId: mockSheetId ?? 'sheet-abc',
          syncTimestamp: DateTime(2026, 8, 21),
        );
  }
}

void main() {
  group('GoogleSheetsBloc Tests', () {
    late AppPreferences preferences;
    late MockGoogleSheetsService mockService;
    late SignInGoogleUseCase signInUseCase;
    late SignOutGoogleUseCase signOutUseCase;
    late GetGoogleAuthStatusUseCase getAuthStatusUseCase;
    late SyncToGoogleSheetsUseCase syncUseCase;
    late TransactionRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      preferences = AppPreferences(prefs);
      final dataSource = TransactionLocalDataSourceImpl(prefs);
      repository = TransactionRepositoryImpl(dataSource);
      mockService = MockGoogleSheetsService();

      signInUseCase = SignInGoogleUseCase(
        googleSheetsService: mockService,
        preferences: preferences,
      );
      signOutUseCase = SignOutGoogleUseCase(
        googleSheetsService: mockService,
        preferences: preferences,
      );
      getAuthStatusUseCase = GetGoogleAuthStatusUseCase(
        googleSheetsService: mockService,
        preferences: preferences,
      );
      syncUseCase = SyncToGoogleSheetsUseCase(
        googleSheetsService: mockService,
        repository: repository,
        preferences: preferences,
      );
    });

    GoogleSheetsBloc buildBloc() {
      return GoogleSheetsBloc(
        signInGoogleUseCase: signInUseCase,
        signOutGoogleUseCase: signOutUseCase,
        getGoogleAuthStatusUseCase: getAuthStatusUseCase,
        syncToGoogleSheetsUseCase: syncUseCase,
        preferences: preferences,
      );
    }

    test('initial state is GoogleSheetsInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, isA<GoogleSheetsInitial>());
    });

    blocTest<GoogleSheetsBloc, GoogleSheetsState>(
      'emits [GoogleSheetsUnauthenticated] on CheckGoogleSheetsAuthEvent when not signed in',
      build: buildBloc,
      act: (bloc) => bloc.add(const CheckGoogleSheetsAuthEvent()),
      expect: () => [
        isA<GoogleSheetsUnauthenticated>(),
      ],
    );

    blocTest<GoogleSheetsBloc, GoogleSheetsState>(
      'emits [GoogleSheetsLoading, GoogleSheetsAuthenticated] on successful SignInGoogleSheetsEvent',
      build: buildBloc,
      act: (bloc) => bloc.add(const SignInGoogleSheetsEvent()),
      expect: () => [
        isA<GoogleSheetsLoading>(),
        isA<GoogleSheetsAuthenticated>().having(
          (s) => s.email,
          'email',
          'user@example.com',
        ),
      ],
      verify: (_) {
        expect(preferences.googleAccountEmail, equals('user@example.com'));
      },
    );

    blocTest<GoogleSheetsBloc, GoogleSheetsState>(
      'emits [GoogleSheetsLoading, GoogleSheetsError] on failed SignInGoogleSheetsEvent',
      build: () {
        mockService.signInReturns = false;
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SignInGoogleSheetsEvent()),
      expect: () => [
        isA<GoogleSheetsLoading>(),
        isA<GoogleSheetsError>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'Google Sign-In was cancelled or failed.',
        ),
      ],
    );

    blocTest<GoogleSheetsBloc, GoogleSheetsState>(
      'emits [GoogleSheetsLoading, GoogleSheetsUnauthenticated] on SignOutGoogleSheetsEvent',
      build: () {
        mockService.signedIn = true;
        mockService.mockEmail = 'user@example.com';
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SignOutGoogleSheetsEvent()),
      expect: () => [
        isA<GoogleSheetsLoading>(),
        isA<GoogleSheetsUnauthenticated>(),
      ],
    );

    blocTest<GoogleSheetsBloc, GoogleSheetsState>(
      'emits [GoogleSheetsLoading, GoogleSheetsSyncSuccess] on successful SyncToGoogleSheetsEvent',
      build: buildBloc,
      act: (bloc) => bloc.add(const SyncToGoogleSheetsEvent()),
      expect: () => [
        isA<GoogleSheetsLoading>(),
        isA<GoogleSheetsSyncSuccess>().having(
          (s) => s.spreadsheetId,
          'spreadsheetId',
          'sheet-abc',
        ),
      ],
    );
  });
}
