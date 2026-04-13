// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSnapshotsTable extends AppSnapshots
    with TableInfo<$AppSnapshotsTable, AppSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateJsonMeta = const VerificationMeta(
    'stateJson',
  );
  @override
  late final GeneratedColumn<String> stateJson = GeneratedColumn<String>(
    'state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, stateJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('state_json')) {
      context.handle(
        _stateJsonMeta,
        stateJson.isAcceptableOrUnknown(data['state_json']!, _stateJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_stateJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state_json'],
      )!,
    );
  }

  @override
  $AppSnapshotsTable createAlias(String alias) {
    return $AppSnapshotsTable(attachedDatabase, alias);
  }
}

class AppSnapshot extends DataClass implements Insertable<AppSnapshot> {
  final int id;
  final String stateJson;
  const AppSnapshot({required this.id, required this.stateJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['state_json'] = Variable<String>(stateJson);
    return map;
  }

  AppSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return AppSnapshotsCompanion(id: Value(id), stateJson: Value(stateJson));
  }

  factory AppSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSnapshot(
      id: serializer.fromJson<int>(json['id']),
      stateJson: serializer.fromJson<String>(json['stateJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stateJson': serializer.toJson<String>(stateJson),
    };
  }

  AppSnapshot copyWith({int? id, String? stateJson}) =>
      AppSnapshot(id: id ?? this.id, stateJson: stateJson ?? this.stateJson);
  AppSnapshot copyWithCompanion(AppSnapshotsCompanion data) {
    return AppSnapshot(
      id: data.id.present ? data.id.value : this.id,
      stateJson: data.stateJson.present ? data.stateJson.value : this.stateJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSnapshot(')
          ..write('id: $id, ')
          ..write('stateJson: $stateJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, stateJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSnapshot &&
          other.id == this.id &&
          other.stateJson == this.stateJson);
}

class AppSnapshotsCompanion extends UpdateCompanion<AppSnapshot> {
  final Value<int> id;
  final Value<String> stateJson;
  const AppSnapshotsCompanion({
    this.id = const Value.absent(),
    this.stateJson = const Value.absent(),
  });
  AppSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required String stateJson,
  }) : stateJson = Value(stateJson);
  static Insertable<AppSnapshot> custom({
    Expression<int>? id,
    Expression<String>? stateJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stateJson != null) 'state_json': stateJson,
    });
  }

  AppSnapshotsCompanion copyWith({Value<int>? id, Value<String>? stateJson}) {
    return AppSnapshotsCompanion(
      id: id ?? this.id,
      stateJson: stateJson ?? this.stateJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stateJson.present) {
      map['state_json'] = Variable<String>(stateJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('stateJson: $stateJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSnapshotsTable appSnapshots = $AppSnapshotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [appSnapshots];
}

typedef $$AppSnapshotsTableCreateCompanionBuilder =
    AppSnapshotsCompanion Function({Value<int> id, required String stateJson});
typedef $$AppSnapshotsTableUpdateCompanionBuilder =
    AppSnapshotsCompanion Function({Value<int> id, Value<String> stateJson});

class $$AppSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSnapshotsTable> {
  $$AppSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSnapshotsTable> {
  $$AppSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSnapshotsTable> {
  $$AppSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stateJson =>
      $composableBuilder(column: $table.stateJson, builder: (column) => column);
}

class $$AppSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSnapshotsTable,
          AppSnapshot,
          $$AppSnapshotsTableFilterComposer,
          $$AppSnapshotsTableOrderingComposer,
          $$AppSnapshotsTableAnnotationComposer,
          $$AppSnapshotsTableCreateCompanionBuilder,
          $$AppSnapshotsTableUpdateCompanionBuilder,
          (
            AppSnapshot,
            BaseReferences<_$AppDatabase, $AppSnapshotsTable, AppSnapshot>,
          ),
          AppSnapshot,
          PrefetchHooks Function()
        > {
  $$AppSnapshotsTableTableManager(_$AppDatabase db, $AppSnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> stateJson = const Value.absent(),
              }) => AppSnapshotsCompanion(id: id, stateJson: stateJson),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String stateJson,
              }) => AppSnapshotsCompanion.insert(id: id, stateJson: stateJson),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSnapshotsTable,
      AppSnapshot,
      $$AppSnapshotsTableFilterComposer,
      $$AppSnapshotsTableOrderingComposer,
      $$AppSnapshotsTableAnnotationComposer,
      $$AppSnapshotsTableCreateCompanionBuilder,
      $$AppSnapshotsTableUpdateCompanionBuilder,
      (
        AppSnapshot,
        BaseReferences<_$AppDatabase, $AppSnapshotsTable, AppSnapshot>,
      ),
      AppSnapshot,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSnapshotsTableTableManager get appSnapshots =>
      $$AppSnapshotsTableTableManager(_db, _db.appSnapshots);
}
