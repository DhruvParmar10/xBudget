import 'package:drift/drift.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';

/// Type converter to safely store and read [BudgetCategory] enum as Text in SQLite.
class BudgetCategoryConverter extends TypeConverter<BudgetCategory, String> {
  const BudgetCategoryConverter();

  @override
  BudgetCategory fromSql(String fromDb) => BudgetCategory.fromString(fromDb);

  @override
  String toSql(BudgetCategory value) => value.name;
}

/// SQLite table for storing transactions with indexes on date, type, and category.
@TableIndex(name: 'transactions_date_idx', columns: {#date})
@TableIndex(name: 'transactions_date_type_idx', columns: {#date, #transactionType})
@TableIndex(name: 'transactions_category_idx', columns: {#category})
class Transactions extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get merchant => text()();
  TextColumn get transactionType =>
      text().withDefault(const Constant('expense'))();
  TextColumn get category => text().map(const BudgetCategoryConverter())();
  BoolColumn get isP2P => boolean().withDefault(const Constant(false))();
  DateTimeColumn get date => dateTime()();
  TextColumn get rawMessage => text().withDefault(const Constant(''))();
  BoolColumn get isUserCategorized =>
      boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for storing balance logs with index on timestamp.
@TableIndex(name: 'balance_logs_timestamp_idx', columns: {#timestamp})
class BalanceLogs extends Table {
  TextColumn get id => text()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get previousBalance => real()();
  RealColumn get adjustmentAmount => real()();
  RealColumn get resultingBalance => real()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
