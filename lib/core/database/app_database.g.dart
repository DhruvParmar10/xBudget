// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expense'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<BudgetCategory, String> category =
      GeneratedColumn<String>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BudgetCategory>($TransactionsTable.$convertercategory);
  static const VerificationMeta _isP2PMeta = const VerificationMeta('isP2P');
  @override
  late final GeneratedColumn<bool> isP2P = GeneratedColumn<bool>(
    'is_p2_p',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_p2_p" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawMessageMeta = const VerificationMeta(
    'rawMessage',
  );
  @override
  late final GeneratedColumn<String> rawMessage = GeneratedColumn<String>(
    'raw_message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isUserCategorizedMeta = const VerificationMeta(
    'isUserCategorized',
  );
  @override
  late final GeneratedColumn<bool> isUserCategorized = GeneratedColumn<bool>(
    'is_user_categorized',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_user_categorized" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amount,
    merchant,
    transactionType,
    category,
    isP2P,
    date,
    rawMessage,
    isUserCategorized,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    } else if (isInserting) {
      context.missing(_merchantMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    }
    if (data.containsKey('is_p2_p')) {
      context.handle(
        _isP2PMeta,
        isP2P.isAcceptableOrUnknown(data['is_p2_p']!, _isP2PMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('raw_message')) {
      context.handle(
        _rawMessageMeta,
        rawMessage.isAcceptableOrUnknown(data['raw_message']!, _rawMessageMeta),
      );
    }
    if (data.containsKey('is_user_categorized')) {
      context.handle(
        _isUserCategorizedMeta,
        isUserCategorized.isAcceptableOrUnknown(
          data['is_user_categorized']!,
          _isUserCategorizedMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      category: $TransactionsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      isP2P: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_p2_p'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      rawMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_message'],
      )!,
      isUserCategorized: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_user_categorized'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static TypeConverter<BudgetCategory, String> $convertercategory =
      const BudgetCategoryConverter();
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final double amount;
  final String merchant;
  final String transactionType;
  final BudgetCategory category;
  final bool isP2P;
  final DateTime date;
  final String rawMessage;
  final bool isUserCategorized;
  final String? note;
  final DateTime createdAt;
  const Transaction({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.transactionType,
    required this.category,
    required this.isP2P,
    required this.date,
    required this.rawMessage,
    required this.isUserCategorized,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['amount'] = Variable<double>(amount);
    map['merchant'] = Variable<String>(merchant);
    map['transaction_type'] = Variable<String>(transactionType);
    {
      map['category'] = Variable<String>(
        $TransactionsTable.$convertercategory.toSql(category),
      );
    }
    map['is_p2_p'] = Variable<bool>(isP2P);
    map['date'] = Variable<DateTime>(date);
    map['raw_message'] = Variable<String>(rawMessage);
    map['is_user_categorized'] = Variable<bool>(isUserCategorized);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      merchant: Value(merchant),
      transactionType: Value(transactionType),
      category: Value(category),
      isP2P: Value(isP2P),
      date: Value(date),
      rawMessage: Value(rawMessage),
      isUserCategorized: Value(isUserCategorized),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      merchant: serializer.fromJson<String>(json['merchant']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      category: serializer.fromJson<BudgetCategory>(json['category']),
      isP2P: serializer.fromJson<bool>(json['isP2P']),
      date: serializer.fromJson<DateTime>(json['date']),
      rawMessage: serializer.fromJson<String>(json['rawMessage']),
      isUserCategorized: serializer.fromJson<bool>(json['isUserCategorized']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amount': serializer.toJson<double>(amount),
      'merchant': serializer.toJson<String>(merchant),
      'transactionType': serializer.toJson<String>(transactionType),
      'category': serializer.toJson<BudgetCategory>(category),
      'isP2P': serializer.toJson<bool>(isP2P),
      'date': serializer.toJson<DateTime>(date),
      'rawMessage': serializer.toJson<String>(rawMessage),
      'isUserCategorized': serializer.toJson<bool>(isUserCategorized),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Transaction copyWith({
    String? id,
    double? amount,
    String? merchant,
    String? transactionType,
    BudgetCategory? category,
    bool? isP2P,
    DateTime? date,
    String? rawMessage,
    bool? isUserCategorized,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => Transaction(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    merchant: merchant ?? this.merchant,
    transactionType: transactionType ?? this.transactionType,
    category: category ?? this.category,
    isP2P: isP2P ?? this.isP2P,
    date: date ?? this.date,
    rawMessage: rawMessage ?? this.rawMessage,
    isUserCategorized: isUserCategorized ?? this.isUserCategorized,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      category: data.category.present ? data.category.value : this.category,
      isP2P: data.isP2P.present ? data.isP2P.value : this.isP2P,
      date: data.date.present ? data.date.value : this.date,
      rawMessage: data.rawMessage.present
          ? data.rawMessage.value
          : this.rawMessage,
      isUserCategorized: data.isUserCategorized.present
          ? data.isUserCategorized.value
          : this.isUserCategorized,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('merchant: $merchant, ')
          ..write('transactionType: $transactionType, ')
          ..write('category: $category, ')
          ..write('isP2P: $isP2P, ')
          ..write('date: $date, ')
          ..write('rawMessage: $rawMessage, ')
          ..write('isUserCategorized: $isUserCategorized, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amount,
    merchant,
    transactionType,
    category,
    isP2P,
    date,
    rawMessage,
    isUserCategorized,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.merchant == this.merchant &&
          other.transactionType == this.transactionType &&
          other.category == this.category &&
          other.isP2P == this.isP2P &&
          other.date == this.date &&
          other.rawMessage == this.rawMessage &&
          other.isUserCategorized == this.isUserCategorized &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<double> amount;
  final Value<String> merchant;
  final Value<String> transactionType;
  final Value<BudgetCategory> category;
  final Value<bool> isP2P;
  final Value<DateTime> date;
  final Value<String> rawMessage;
  final Value<bool> isUserCategorized;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.merchant = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.category = const Value.absent(),
    this.isP2P = const Value.absent(),
    this.date = const Value.absent(),
    this.rawMessage = const Value.absent(),
    this.isUserCategorized = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required double amount,
    required String merchant,
    this.transactionType = const Value.absent(),
    required BudgetCategory category,
    this.isP2P = const Value.absent(),
    required DateTime date,
    this.rawMessage = const Value.absent(),
    this.isUserCategorized = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amount = Value(amount),
       merchant = Value(merchant),
       category = Value(category),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<double>? amount,
    Expression<String>? merchant,
    Expression<String>? transactionType,
    Expression<String>? category,
    Expression<bool>? isP2P,
    Expression<DateTime>? date,
    Expression<String>? rawMessage,
    Expression<bool>? isUserCategorized,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (merchant != null) 'merchant': merchant,
      if (transactionType != null) 'transaction_type': transactionType,
      if (category != null) 'category': category,
      if (isP2P != null) 'is_p2_p': isP2P,
      if (date != null) 'date': date,
      if (rawMessage != null) 'raw_message': rawMessage,
      if (isUserCategorized != null) 'is_user_categorized': isUserCategorized,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<double>? amount,
    Value<String>? merchant,
    Value<String>? transactionType,
    Value<BudgetCategory>? category,
    Value<bool>? isP2P,
    Value<DateTime>? date,
    Value<String>? rawMessage,
    Value<bool>? isUserCategorized,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      isP2P: isP2P ?? this.isP2P,
      date: date ?? this.date,
      rawMessage: rawMessage ?? this.rawMessage,
      isUserCategorized: isUserCategorized ?? this.isUserCategorized,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $TransactionsTable.$convertercategory.toSql(category.value),
      );
    }
    if (isP2P.present) {
      map['is_p2_p'] = Variable<bool>(isP2P.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (rawMessage.present) {
      map['raw_message'] = Variable<String>(rawMessage.value);
    }
    if (isUserCategorized.present) {
      map['is_user_categorized'] = Variable<bool>(isUserCategorized.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('merchant: $merchant, ')
          ..write('transactionType: $transactionType, ')
          ..write('category: $category, ')
          ..write('isP2P: $isP2P, ')
          ..write('date: $date, ')
          ..write('rawMessage: $rawMessage, ')
          ..write('isUserCategorized: $isUserCategorized, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BalanceLogsTable extends BalanceLogs
    with TableInfo<$BalanceLogsTable, BalanceLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BalanceLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousBalanceMeta = const VerificationMeta(
    'previousBalance',
  );
  @override
  late final GeneratedColumn<double> previousBalance = GeneratedColumn<double>(
    'previous_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adjustmentAmountMeta = const VerificationMeta(
    'adjustmentAmount',
  );
  @override
  late final GeneratedColumn<double> adjustmentAmount = GeneratedColumn<double>(
    'adjustment_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultingBalanceMeta = const VerificationMeta(
    'resultingBalance',
  );
  @override
  late final GeneratedColumn<double> resultingBalance = GeneratedColumn<double>(
    'resulting_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    previousBalance,
    adjustmentAmount,
    resultingBalance,
    source,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'balance_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<BalanceLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('previous_balance')) {
      context.handle(
        _previousBalanceMeta,
        previousBalance.isAcceptableOrUnknown(
          data['previous_balance']!,
          _previousBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_previousBalanceMeta);
    }
    if (data.containsKey('adjustment_amount')) {
      context.handle(
        _adjustmentAmountMeta,
        adjustmentAmount.isAcceptableOrUnknown(
          data['adjustment_amount']!,
          _adjustmentAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_adjustmentAmountMeta);
    }
    if (data.containsKey('resulting_balance')) {
      context.handle(
        _resultingBalanceMeta,
        resultingBalance.isAcceptableOrUnknown(
          data['resulting_balance']!,
          _resultingBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resultingBalanceMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BalanceLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BalanceLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      previousBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}previous_balance'],
      )!,
      adjustmentAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}adjustment_amount'],
      )!,
      resultingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}resulting_balance'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BalanceLogsTable createAlias(String alias) {
    return $BalanceLogsTable(attachedDatabase, alias);
  }
}

class BalanceLog extends DataClass implements Insertable<BalanceLog> {
  final String id;
  final DateTime timestamp;
  final double previousBalance;
  final double adjustmentAmount;
  final double resultingBalance;
  final String source;
  final String? note;
  final DateTime createdAt;
  const BalanceLog({
    required this.id,
    required this.timestamp,
    required this.previousBalance,
    required this.adjustmentAmount,
    required this.resultingBalance,
    required this.source,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['previous_balance'] = Variable<double>(previousBalance);
    map['adjustment_amount'] = Variable<double>(adjustmentAmount);
    map['resulting_balance'] = Variable<double>(resultingBalance);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BalanceLogsCompanion toCompanion(bool nullToAbsent) {
    return BalanceLogsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      previousBalance: Value(previousBalance),
      adjustmentAmount: Value(adjustmentAmount),
      resultingBalance: Value(resultingBalance),
      source: Value(source),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory BalanceLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BalanceLog(
      id: serializer.fromJson<String>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      previousBalance: serializer.fromJson<double>(json['previousBalance']),
      adjustmentAmount: serializer.fromJson<double>(json['adjustmentAmount']),
      resultingBalance: serializer.fromJson<double>(json['resultingBalance']),
      source: serializer.fromJson<String>(json['source']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'previousBalance': serializer.toJson<double>(previousBalance),
      'adjustmentAmount': serializer.toJson<double>(adjustmentAmount),
      'resultingBalance': serializer.toJson<double>(resultingBalance),
      'source': serializer.toJson<String>(source),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BalanceLog copyWith({
    String? id,
    DateTime? timestamp,
    double? previousBalance,
    double? adjustmentAmount,
    double? resultingBalance,
    String? source,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => BalanceLog(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    previousBalance: previousBalance ?? this.previousBalance,
    adjustmentAmount: adjustmentAmount ?? this.adjustmentAmount,
    resultingBalance: resultingBalance ?? this.resultingBalance,
    source: source ?? this.source,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  BalanceLog copyWithCompanion(BalanceLogsCompanion data) {
    return BalanceLog(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      previousBalance: data.previousBalance.present
          ? data.previousBalance.value
          : this.previousBalance,
      adjustmentAmount: data.adjustmentAmount.present
          ? data.adjustmentAmount.value
          : this.adjustmentAmount,
      resultingBalance: data.resultingBalance.present
          ? data.resultingBalance.value
          : this.resultingBalance,
      source: data.source.present ? data.source.value : this.source,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BalanceLog(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('previousBalance: $previousBalance, ')
          ..write('adjustmentAmount: $adjustmentAmount, ')
          ..write('resultingBalance: $resultingBalance, ')
          ..write('source: $source, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    previousBalance,
    adjustmentAmount,
    resultingBalance,
    source,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BalanceLog &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.previousBalance == this.previousBalance &&
          other.adjustmentAmount == this.adjustmentAmount &&
          other.resultingBalance == this.resultingBalance &&
          other.source == this.source &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class BalanceLogsCompanion extends UpdateCompanion<BalanceLog> {
  final Value<String> id;
  final Value<DateTime> timestamp;
  final Value<double> previousBalance;
  final Value<double> adjustmentAmount;
  final Value<double> resultingBalance;
  final Value<String> source;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BalanceLogsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.previousBalance = const Value.absent(),
    this.adjustmentAmount = const Value.absent(),
    this.resultingBalance = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BalanceLogsCompanion.insert({
    required String id,
    required DateTime timestamp,
    required double previousBalance,
    required double adjustmentAmount,
    required double resultingBalance,
    this.source = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       timestamp = Value(timestamp),
       previousBalance = Value(previousBalance),
       adjustmentAmount = Value(adjustmentAmount),
       resultingBalance = Value(resultingBalance),
       createdAt = Value(createdAt);
  static Insertable<BalanceLog> custom({
    Expression<String>? id,
    Expression<DateTime>? timestamp,
    Expression<double>? previousBalance,
    Expression<double>? adjustmentAmount,
    Expression<double>? resultingBalance,
    Expression<String>? source,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (previousBalance != null) 'previous_balance': previousBalance,
      if (adjustmentAmount != null) 'adjustment_amount': adjustmentAmount,
      if (resultingBalance != null) 'resulting_balance': resultingBalance,
      if (source != null) 'source': source,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BalanceLogsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? timestamp,
    Value<double>? previousBalance,
    Value<double>? adjustmentAmount,
    Value<double>? resultingBalance,
    Value<String>? source,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BalanceLogsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      previousBalance: previousBalance ?? this.previousBalance,
      adjustmentAmount: adjustmentAmount ?? this.adjustmentAmount,
      resultingBalance: resultingBalance ?? this.resultingBalance,
      source: source ?? this.source,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (previousBalance.present) {
      map['previous_balance'] = Variable<double>(previousBalance.value);
    }
    if (adjustmentAmount.present) {
      map['adjustment_amount'] = Variable<double>(adjustmentAmount.value);
    }
    if (resultingBalance.present) {
      map['resulting_balance'] = Variable<double>(resultingBalance.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BalanceLogsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('previousBalance: $previousBalance, ')
          ..write('adjustmentAmount: $adjustmentAmount, ')
          ..write('resultingBalance: $resultingBalance, ')
          ..write('source: $source, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $BalanceLogsTable balanceLogs = $BalanceLogsTable(this);
  late final Index transactionsDateIdx = Index(
    'transactions_date_idx',
    'CREATE INDEX transactions_date_idx ON transactions (date)',
  );
  late final Index transactionsDateTypeIdx = Index(
    'transactions_date_type_idx',
    'CREATE INDEX transactions_date_type_idx ON transactions (date, transaction_type)',
  );
  late final Index transactionsCategoryIdx = Index(
    'transactions_category_idx',
    'CREATE INDEX transactions_category_idx ON transactions (category)',
  );
  late final Index balanceLogsTimestampIdx = Index(
    'balance_logs_timestamp_idx',
    'CREATE INDEX balance_logs_timestamp_idx ON balance_logs (timestamp)',
  );
  late final TransactionDao transactionDao = TransactionDao(
    this as AppDatabase,
  );
  late final BalanceLogDao balanceLogDao = BalanceLogDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    balanceLogs,
    transactionsDateIdx,
    transactionsDateTypeIdx,
    transactionsCategoryIdx,
    balanceLogsTimestampIdx,
  ];
}

typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required double amount,
      required String merchant,
      Value<String> transactionType,
      required BudgetCategory category,
      Value<bool> isP2P,
      required DateTime date,
      Value<String> rawMessage,
      Value<bool> isUserCategorized,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<double> amount,
      Value<String> merchant,
      Value<String> transactionType,
      Value<BudgetCategory> category,
      Value<bool> isP2P,
      Value<DateTime> date,
      Value<String> rawMessage,
      Value<bool> isUserCategorized,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BudgetCategory, BudgetCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isP2P => $composableBuilder(
    column: $table.isP2P,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawMessage => $composableBuilder(
    column: $table.rawMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUserCategorized => $composableBuilder(
    column: $table.isUserCategorized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isP2P => $composableBuilder(
    column: $table.isP2P,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawMessage => $composableBuilder(
    column: $table.rawMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUserCategorized => $composableBuilder(
    column: $table.isUserCategorized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BudgetCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isP2P =>
      $composableBuilder(column: $table.isP2P, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get rawMessage => $composableBuilder(
    column: $table.rawMessage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUserCategorized => $composableBuilder(
    column: $table.isUserCategorized,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> merchant = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<BudgetCategory> category = const Value.absent(),
                Value<bool> isP2P = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> rawMessage = const Value.absent(),
                Value<bool> isUserCategorized = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                amount: amount,
                merchant: merchant,
                transactionType: transactionType,
                category: category,
                isP2P: isP2P,
                date: date,
                rawMessage: rawMessage,
                isUserCategorized: isUserCategorized,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required double amount,
                required String merchant,
                Value<String> transactionType = const Value.absent(),
                required BudgetCategory category,
                Value<bool> isP2P = const Value.absent(),
                required DateTime date,
                Value<String> rawMessage = const Value.absent(),
                Value<bool> isUserCategorized = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                amount: amount,
                merchant: merchant,
                transactionType: transactionType,
                category: category,
                isP2P: isP2P,
                date: date,
                rawMessage: rawMessage,
                isUserCategorized: isUserCategorized,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$BalanceLogsTableCreateCompanionBuilder =
    BalanceLogsCompanion Function({
      required String id,
      required DateTime timestamp,
      required double previousBalance,
      required double adjustmentAmount,
      required double resultingBalance,
      Value<String> source,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$BalanceLogsTableUpdateCompanionBuilder =
    BalanceLogsCompanion Function({
      Value<String> id,
      Value<DateTime> timestamp,
      Value<double> previousBalance,
      Value<double> adjustmentAmount,
      Value<double> resultingBalance,
      Value<String> source,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$BalanceLogsTableFilterComposer
    extends Composer<_$AppDatabase, $BalanceLogsTable> {
  $$BalanceLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get previousBalance => $composableBuilder(
    column: $table.previousBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get adjustmentAmount => $composableBuilder(
    column: $table.adjustmentAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get resultingBalance => $composableBuilder(
    column: $table.resultingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BalanceLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $BalanceLogsTable> {
  $$BalanceLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get previousBalance => $composableBuilder(
    column: $table.previousBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get adjustmentAmount => $composableBuilder(
    column: $table.adjustmentAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get resultingBalance => $composableBuilder(
    column: $table.resultingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BalanceLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BalanceLogsTable> {
  $$BalanceLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get previousBalance => $composableBuilder(
    column: $table.previousBalance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get adjustmentAmount => $composableBuilder(
    column: $table.adjustmentAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get resultingBalance => $composableBuilder(
    column: $table.resultingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BalanceLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BalanceLogsTable,
          BalanceLog,
          $$BalanceLogsTableFilterComposer,
          $$BalanceLogsTableOrderingComposer,
          $$BalanceLogsTableAnnotationComposer,
          $$BalanceLogsTableCreateCompanionBuilder,
          $$BalanceLogsTableUpdateCompanionBuilder,
          (
            BalanceLog,
            BaseReferences<_$AppDatabase, $BalanceLogsTable, BalanceLog>,
          ),
          BalanceLog,
          PrefetchHooks Function()
        > {
  $$BalanceLogsTableTableManager(_$AppDatabase db, $BalanceLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BalanceLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BalanceLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BalanceLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> previousBalance = const Value.absent(),
                Value<double> adjustmentAmount = const Value.absent(),
                Value<double> resultingBalance = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceLogsCompanion(
                id: id,
                timestamp: timestamp,
                previousBalance: previousBalance,
                adjustmentAmount: adjustmentAmount,
                resultingBalance: resultingBalance,
                source: source,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime timestamp,
                required double previousBalance,
                required double adjustmentAmount,
                required double resultingBalance,
                Value<String> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BalanceLogsCompanion.insert(
                id: id,
                timestamp: timestamp,
                previousBalance: previousBalance,
                adjustmentAmount: adjustmentAmount,
                resultingBalance: resultingBalance,
                source: source,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BalanceLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BalanceLogsTable,
      BalanceLog,
      $$BalanceLogsTableFilterComposer,
      $$BalanceLogsTableOrderingComposer,
      $$BalanceLogsTableAnnotationComposer,
      $$BalanceLogsTableCreateCompanionBuilder,
      $$BalanceLogsTableUpdateCompanionBuilder,
      (
        BalanceLog,
        BaseReferences<_$AppDatabase, $BalanceLogsTable, BalanceLog>,
      ),
      BalanceLog,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$BalanceLogsTableTableManager get balanceLogs =>
      $$BalanceLogsTableTableManager(_db, _db.balanceLogs);
}
