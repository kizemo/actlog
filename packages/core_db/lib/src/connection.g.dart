// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    key,
    value,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  /// 实体 ID。
  final String id;

  /// 配置键。
  final String key;

  /// 配置值（JSON 文本；bool 存 0/1）。
  final String value;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const Setting({
    required this.id,
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<String>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  Setting copyWith({
    String? id,
    String? key,
    String? value,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => Setting(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value ?? this.value,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    key,
    value,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> id;
  final Value<String> key;
  final Value<String> value;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String id,
    required String key,
    this.value = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       key = Value(key),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<Setting> custom({
    Expression<String>? id,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? id,
    Value<String>? key,
    Value<String>? value,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayLogTable extends DayLog with TableInfo<$DayLogTable, DayLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('full'),
  );
  static const VerificationMeta _learningMeta = const VerificationMeta(
    'learning',
  );
  @override
  late final GeneratedColumn<String> learning = GeneratedColumn<String>(
    'learning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _goodMeta = const VerificationMeta('good');
  @override
  late final GeneratedColumn<String> good = GeneratedColumn<String>(
    'good',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _improveMeta = const VerificationMeta(
    'improve',
  );
  @override
  late final GeneratedColumn<String> improve = GeneratedColumn<String>(
    'improve',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _controllableMeta = const VerificationMeta(
    'controllable',
  );
  @override
  late final GeneratedColumn<String> controllable = GeneratedColumn<String>(
    'controllable',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _uncontrollableMeta = const VerificationMeta(
    'uncontrollable',
  );
  @override
  late final GeneratedColumn<String> uncontrollable = GeneratedColumn<String>(
    'uncontrollable',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nextActionMeta = const VerificationMeta(
    'nextAction',
  );
  @override
  late final GeneratedColumn<String> nextAction = GeneratedColumn<String>(
    'next_action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _moodNoteMeta = const VerificationMeta(
    'moodNote',
  );
  @override
  late final GeneratedColumn<String> moodNote = GeneratedColumn<String>(
    'mood_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _mood1Meta = const VerificationMeta('mood1');
  @override
  late final GeneratedColumn<int> mood1 = GeneratedColumn<int>(
    'mood_1',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mood2Meta = const VerificationMeta('mood2');
  @override
  late final GeneratedColumn<int> mood2 = GeneratedColumn<int>(
    'mood_2',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mood3Meta = const VerificationMeta('mood3');
  @override
  late final GeneratedColumn<int> mood3 = GeneratedColumn<int>(
    'mood_3',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mood4Meta = const VerificationMeta('mood4');
  @override
  late final GeneratedColumn<int> mood4 = GeneratedColumn<int>(
    'mood_4',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mood5Meta = const VerificationMeta('mood5');
  @override
  late final GeneratedColumn<int> mood5 = GeneratedColumn<int>(
    'mood_5',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mood6Meta = const VerificationMeta('mood6');
  @override
  late final GeneratedColumn<int> mood6 = GeneratedColumn<int>(
    'mood_6',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mood7Meta = const VerificationMeta('mood7');
  @override
  late final GeneratedColumn<int> mood7 = GeneratedColumn<int>(
    'mood_7',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mood8Meta = const VerificationMeta('mood8');
  @override
  late final GeneratedColumn<int> mood8 = GeneratedColumn<int>(
    'mood_8',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moodFailedMeta = const VerificationMeta(
    'moodFailed',
  );
  @override
  late final GeneratedColumn<int> moodFailed = GeneratedColumn<int>(
    'mood_failed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    mode,
    learning,
    good,
    improve,
    controllable,
    uncontrollable,
    nextAction,
    moodNote,
    mood1,
    mood2,
    mood3,
    mood4,
    mood5,
    mood6,
    mood7,
    mood8,
    moodFailed,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('learning')) {
      context.handle(
        _learningMeta,
        learning.isAcceptableOrUnknown(data['learning']!, _learningMeta),
      );
    }
    if (data.containsKey('good')) {
      context.handle(
        _goodMeta,
        good.isAcceptableOrUnknown(data['good']!, _goodMeta),
      );
    }
    if (data.containsKey('improve')) {
      context.handle(
        _improveMeta,
        improve.isAcceptableOrUnknown(data['improve']!, _improveMeta),
      );
    }
    if (data.containsKey('controllable')) {
      context.handle(
        _controllableMeta,
        controllable.isAcceptableOrUnknown(
          data['controllable']!,
          _controllableMeta,
        ),
      );
    }
    if (data.containsKey('uncontrollable')) {
      context.handle(
        _uncontrollableMeta,
        uncontrollable.isAcceptableOrUnknown(
          data['uncontrollable']!,
          _uncontrollableMeta,
        ),
      );
    }
    if (data.containsKey('next_action')) {
      context.handle(
        _nextActionMeta,
        nextAction.isAcceptableOrUnknown(data['next_action']!, _nextActionMeta),
      );
    }
    if (data.containsKey('mood_note')) {
      context.handle(
        _moodNoteMeta,
        moodNote.isAcceptableOrUnknown(data['mood_note']!, _moodNoteMeta),
      );
    }
    if (data.containsKey('mood_1')) {
      context.handle(
        _mood1Meta,
        mood1.isAcceptableOrUnknown(data['mood_1']!, _mood1Meta),
      );
    }
    if (data.containsKey('mood_2')) {
      context.handle(
        _mood2Meta,
        mood2.isAcceptableOrUnknown(data['mood_2']!, _mood2Meta),
      );
    }
    if (data.containsKey('mood_3')) {
      context.handle(
        _mood3Meta,
        mood3.isAcceptableOrUnknown(data['mood_3']!, _mood3Meta),
      );
    }
    if (data.containsKey('mood_4')) {
      context.handle(
        _mood4Meta,
        mood4.isAcceptableOrUnknown(data['mood_4']!, _mood4Meta),
      );
    }
    if (data.containsKey('mood_5')) {
      context.handle(
        _mood5Meta,
        mood5.isAcceptableOrUnknown(data['mood_5']!, _mood5Meta),
      );
    }
    if (data.containsKey('mood_6')) {
      context.handle(
        _mood6Meta,
        mood6.isAcceptableOrUnknown(data['mood_6']!, _mood6Meta),
      );
    }
    if (data.containsKey('mood_7')) {
      context.handle(
        _mood7Meta,
        mood7.isAcceptableOrUnknown(data['mood_7']!, _mood7Meta),
      );
    }
    if (data.containsKey('mood_8')) {
      context.handle(
        _mood8Meta,
        mood8.isAcceptableOrUnknown(data['mood_8']!, _mood8Meta),
      );
    }
    if (data.containsKey('mood_failed')) {
      context.handle(
        _moodFailedMeta,
        moodFailed.isAcceptableOrUnknown(data['mood_failed']!, _moodFailedMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      learning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learning'],
      )!,
      good: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}good'],
      )!,
      improve: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}improve'],
      )!,
      controllable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}controllable'],
      )!,
      uncontrollable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uncontrollable'],
      )!,
      nextAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_action'],
      )!,
      moodNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood_note'],
      )!,
      mood1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood_1'],
      ),
      mood2: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood_2'],
      ),
      mood3: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood_3'],
      ),
      mood4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood_4'],
      ),
      mood5: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood_5'],
      ),
      mood6: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood_6'],
      ),
      mood7: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood_7'],
      ),
      mood8: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood_8'],
      ),
      moodFailed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood_failed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $DayLogTable createAlias(String alias) {
    return $DayLogTable(attachedDatabase, alias);
  }
}

class DayLogData extends DataClass implements Insertable<DayLogData> {
  /// 实体 ID。
  final String id;

  /// 日历日 'YYYY-MM-DD'。
  final String date;

  /// 完整版 / 极简版。
  final String mode;

  /// 复盘三段 · 学到了什么。
  final String learning;

  /// 复盘三段 · 做得好的。
  final String good;

  /// 复盘三段 · 待改进的。
  final String improve;

  /// 可控的事。
  final String controllable;

  /// 不可控的事。
  final String uncontrollable;

  /// 下一步可控动作。
  final String nextAction;

  /// 情绪备注。
  final String moodNote;

  /// 心态 1 认真。
  final int? mood1;

  /// 心态 2 快。
  final int? mood2;

  /// 心态 3 坚守承诺。
  final int? mood3;

  /// 心态 4 保证完成任务。
  final int? mood4;

  /// 心态 5 乐观。
  final int? mood5;

  /// 心态 6 自信。
  final int? mood6;

  /// 心态 7 爱与奉献。
  final int? mood7;

  /// 心态 8 决不找借口。
  final int? mood8;

  /// 今日失守（0/1）。
  final int moodFailed;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const DayLogData({
    required this.id,
    required this.date,
    required this.mode,
    required this.learning,
    required this.good,
    required this.improve,
    required this.controllable,
    required this.uncontrollable,
    required this.nextAction,
    required this.moodNote,
    this.mood1,
    this.mood2,
    this.mood3,
    this.mood4,
    this.mood5,
    this.mood6,
    this.mood7,
    this.mood8,
    required this.moodFailed,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['mode'] = Variable<String>(mode);
    map['learning'] = Variable<String>(learning);
    map['good'] = Variable<String>(good);
    map['improve'] = Variable<String>(improve);
    map['controllable'] = Variable<String>(controllable);
    map['uncontrollable'] = Variable<String>(uncontrollable);
    map['next_action'] = Variable<String>(nextAction);
    map['mood_note'] = Variable<String>(moodNote);
    if (!nullToAbsent || mood1 != null) {
      map['mood_1'] = Variable<int>(mood1);
    }
    if (!nullToAbsent || mood2 != null) {
      map['mood_2'] = Variable<int>(mood2);
    }
    if (!nullToAbsent || mood3 != null) {
      map['mood_3'] = Variable<int>(mood3);
    }
    if (!nullToAbsent || mood4 != null) {
      map['mood_4'] = Variable<int>(mood4);
    }
    if (!nullToAbsent || mood5 != null) {
      map['mood_5'] = Variable<int>(mood5);
    }
    if (!nullToAbsent || mood6 != null) {
      map['mood_6'] = Variable<int>(mood6);
    }
    if (!nullToAbsent || mood7 != null) {
      map['mood_7'] = Variable<int>(mood7);
    }
    if (!nullToAbsent || mood8 != null) {
      map['mood_8'] = Variable<int>(mood8);
    }
    map['mood_failed'] = Variable<int>(moodFailed);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  DayLogCompanion toCompanion(bool nullToAbsent) {
    return DayLogCompanion(
      id: Value(id),
      date: Value(date),
      mode: Value(mode),
      learning: Value(learning),
      good: Value(good),
      improve: Value(improve),
      controllable: Value(controllable),
      uncontrollable: Value(uncontrollable),
      nextAction: Value(nextAction),
      moodNote: Value(moodNote),
      mood1: mood1 == null && nullToAbsent
          ? const Value.absent()
          : Value(mood1),
      mood2: mood2 == null && nullToAbsent
          ? const Value.absent()
          : Value(mood2),
      mood3: mood3 == null && nullToAbsent
          ? const Value.absent()
          : Value(mood3),
      mood4: mood4 == null && nullToAbsent
          ? const Value.absent()
          : Value(mood4),
      mood5: mood5 == null && nullToAbsent
          ? const Value.absent()
          : Value(mood5),
      mood6: mood6 == null && nullToAbsent
          ? const Value.absent()
          : Value(mood6),
      mood7: mood7 == null && nullToAbsent
          ? const Value.absent()
          : Value(mood7),
      mood8: mood8 == null && nullToAbsent
          ? const Value.absent()
          : Value(mood8),
      moodFailed: Value(moodFailed),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory DayLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayLogData(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      mode: serializer.fromJson<String>(json['mode']),
      learning: serializer.fromJson<String>(json['learning']),
      good: serializer.fromJson<String>(json['good']),
      improve: serializer.fromJson<String>(json['improve']),
      controllable: serializer.fromJson<String>(json['controllable']),
      uncontrollable: serializer.fromJson<String>(json['uncontrollable']),
      nextAction: serializer.fromJson<String>(json['nextAction']),
      moodNote: serializer.fromJson<String>(json['moodNote']),
      mood1: serializer.fromJson<int?>(json['mood1']),
      mood2: serializer.fromJson<int?>(json['mood2']),
      mood3: serializer.fromJson<int?>(json['mood3']),
      mood4: serializer.fromJson<int?>(json['mood4']),
      mood5: serializer.fromJson<int?>(json['mood5']),
      mood6: serializer.fromJson<int?>(json['mood6']),
      mood7: serializer.fromJson<int?>(json['mood7']),
      mood8: serializer.fromJson<int?>(json['mood8']),
      moodFailed: serializer.fromJson<int>(json['moodFailed']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'mode': serializer.toJson<String>(mode),
      'learning': serializer.toJson<String>(learning),
      'good': serializer.toJson<String>(good),
      'improve': serializer.toJson<String>(improve),
      'controllable': serializer.toJson<String>(controllable),
      'uncontrollable': serializer.toJson<String>(uncontrollable),
      'nextAction': serializer.toJson<String>(nextAction),
      'moodNote': serializer.toJson<String>(moodNote),
      'mood1': serializer.toJson<int?>(mood1),
      'mood2': serializer.toJson<int?>(mood2),
      'mood3': serializer.toJson<int?>(mood3),
      'mood4': serializer.toJson<int?>(mood4),
      'mood5': serializer.toJson<int?>(mood5),
      'mood6': serializer.toJson<int?>(mood6),
      'mood7': serializer.toJson<int?>(mood7),
      'mood8': serializer.toJson<int?>(mood8),
      'moodFailed': serializer.toJson<int>(moodFailed),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  DayLogData copyWith({
    String? id,
    String? date,
    String? mode,
    String? learning,
    String? good,
    String? improve,
    String? controllable,
    String? uncontrollable,
    String? nextAction,
    String? moodNote,
    Value<int?> mood1 = const Value.absent(),
    Value<int?> mood2 = const Value.absent(),
    Value<int?> mood3 = const Value.absent(),
    Value<int?> mood4 = const Value.absent(),
    Value<int?> mood5 = const Value.absent(),
    Value<int?> mood6 = const Value.absent(),
    Value<int?> mood7 = const Value.absent(),
    Value<int?> mood8 = const Value.absent(),
    int? moodFailed,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => DayLogData(
    id: id ?? this.id,
    date: date ?? this.date,
    mode: mode ?? this.mode,
    learning: learning ?? this.learning,
    good: good ?? this.good,
    improve: improve ?? this.improve,
    controllable: controllable ?? this.controllable,
    uncontrollable: uncontrollable ?? this.uncontrollable,
    nextAction: nextAction ?? this.nextAction,
    moodNote: moodNote ?? this.moodNote,
    mood1: mood1.present ? mood1.value : this.mood1,
    mood2: mood2.present ? mood2.value : this.mood2,
    mood3: mood3.present ? mood3.value : this.mood3,
    mood4: mood4.present ? mood4.value : this.mood4,
    mood5: mood5.present ? mood5.value : this.mood5,
    mood6: mood6.present ? mood6.value : this.mood6,
    mood7: mood7.present ? mood7.value : this.mood7,
    mood8: mood8.present ? mood8.value : this.mood8,
    moodFailed: moodFailed ?? this.moodFailed,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  DayLogData copyWithCompanion(DayLogCompanion data) {
    return DayLogData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      mode: data.mode.present ? data.mode.value : this.mode,
      learning: data.learning.present ? data.learning.value : this.learning,
      good: data.good.present ? data.good.value : this.good,
      improve: data.improve.present ? data.improve.value : this.improve,
      controllable: data.controllable.present
          ? data.controllable.value
          : this.controllable,
      uncontrollable: data.uncontrollable.present
          ? data.uncontrollable.value
          : this.uncontrollable,
      nextAction: data.nextAction.present
          ? data.nextAction.value
          : this.nextAction,
      moodNote: data.moodNote.present ? data.moodNote.value : this.moodNote,
      mood1: data.mood1.present ? data.mood1.value : this.mood1,
      mood2: data.mood2.present ? data.mood2.value : this.mood2,
      mood3: data.mood3.present ? data.mood3.value : this.mood3,
      mood4: data.mood4.present ? data.mood4.value : this.mood4,
      mood5: data.mood5.present ? data.mood5.value : this.mood5,
      mood6: data.mood6.present ? data.mood6.value : this.mood6,
      mood7: data.mood7.present ? data.mood7.value : this.mood7,
      mood8: data.mood8.present ? data.mood8.value : this.mood8,
      moodFailed: data.moodFailed.present
          ? data.moodFailed.value
          : this.moodFailed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayLogData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mode: $mode, ')
          ..write('learning: $learning, ')
          ..write('good: $good, ')
          ..write('improve: $improve, ')
          ..write('controllable: $controllable, ')
          ..write('uncontrollable: $uncontrollable, ')
          ..write('nextAction: $nextAction, ')
          ..write('moodNote: $moodNote, ')
          ..write('mood1: $mood1, ')
          ..write('mood2: $mood2, ')
          ..write('mood3: $mood3, ')
          ..write('mood4: $mood4, ')
          ..write('mood5: $mood5, ')
          ..write('mood6: $mood6, ')
          ..write('mood7: $mood7, ')
          ..write('mood8: $mood8, ')
          ..write('moodFailed: $moodFailed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    date,
    mode,
    learning,
    good,
    improve,
    controllable,
    uncontrollable,
    nextAction,
    moodNote,
    mood1,
    mood2,
    mood3,
    mood4,
    mood5,
    mood6,
    mood7,
    mood8,
    moodFailed,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayLogData &&
          other.id == this.id &&
          other.date == this.date &&
          other.mode == this.mode &&
          other.learning == this.learning &&
          other.good == this.good &&
          other.improve == this.improve &&
          other.controllable == this.controllable &&
          other.uncontrollable == this.uncontrollable &&
          other.nextAction == this.nextAction &&
          other.moodNote == this.moodNote &&
          other.mood1 == this.mood1 &&
          other.mood2 == this.mood2 &&
          other.mood3 == this.mood3 &&
          other.mood4 == this.mood4 &&
          other.mood5 == this.mood5 &&
          other.mood6 == this.mood6 &&
          other.mood7 == this.mood7 &&
          other.mood8 == this.mood8 &&
          other.moodFailed == this.moodFailed &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class DayLogCompanion extends UpdateCompanion<DayLogData> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> mode;
  final Value<String> learning;
  final Value<String> good;
  final Value<String> improve;
  final Value<String> controllable;
  final Value<String> uncontrollable;
  final Value<String> nextAction;
  final Value<String> moodNote;
  final Value<int?> mood1;
  final Value<int?> mood2;
  final Value<int?> mood3;
  final Value<int?> mood4;
  final Value<int?> mood5;
  final Value<int?> mood6;
  final Value<int?> mood7;
  final Value<int?> mood8;
  final Value<int> moodFailed;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const DayLogCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.mode = const Value.absent(),
    this.learning = const Value.absent(),
    this.good = const Value.absent(),
    this.improve = const Value.absent(),
    this.controllable = const Value.absent(),
    this.uncontrollable = const Value.absent(),
    this.nextAction = const Value.absent(),
    this.moodNote = const Value.absent(),
    this.mood1 = const Value.absent(),
    this.mood2 = const Value.absent(),
    this.mood3 = const Value.absent(),
    this.mood4 = const Value.absent(),
    this.mood5 = const Value.absent(),
    this.mood6 = const Value.absent(),
    this.mood7 = const Value.absent(),
    this.mood8 = const Value.absent(),
    this.moodFailed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayLogCompanion.insert({
    required String id,
    required String date,
    this.mode = const Value.absent(),
    this.learning = const Value.absent(),
    this.good = const Value.absent(),
    this.improve = const Value.absent(),
    this.controllable = const Value.absent(),
    this.uncontrollable = const Value.absent(),
    this.nextAction = const Value.absent(),
    this.moodNote = const Value.absent(),
    this.mood1 = const Value.absent(),
    this.mood2 = const Value.absent(),
    this.mood3 = const Value.absent(),
    this.mood4 = const Value.absent(),
    this.mood5 = const Value.absent(),
    this.mood6 = const Value.absent(),
    this.mood7 = const Value.absent(),
    this.mood8 = const Value.absent(),
    this.moodFailed = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<DayLogData> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? mode,
    Expression<String>? learning,
    Expression<String>? good,
    Expression<String>? improve,
    Expression<String>? controllable,
    Expression<String>? uncontrollable,
    Expression<String>? nextAction,
    Expression<String>? moodNote,
    Expression<int>? mood1,
    Expression<int>? mood2,
    Expression<int>? mood3,
    Expression<int>? mood4,
    Expression<int>? mood5,
    Expression<int>? mood6,
    Expression<int>? mood7,
    Expression<int>? mood8,
    Expression<int>? moodFailed,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (mode != null) 'mode': mode,
      if (learning != null) 'learning': learning,
      if (good != null) 'good': good,
      if (improve != null) 'improve': improve,
      if (controllable != null) 'controllable': controllable,
      if (uncontrollable != null) 'uncontrollable': uncontrollable,
      if (nextAction != null) 'next_action': nextAction,
      if (moodNote != null) 'mood_note': moodNote,
      if (mood1 != null) 'mood_1': mood1,
      if (mood2 != null) 'mood_2': mood2,
      if (mood3 != null) 'mood_3': mood3,
      if (mood4 != null) 'mood_4': mood4,
      if (mood5 != null) 'mood_5': mood5,
      if (mood6 != null) 'mood_6': mood6,
      if (mood7 != null) 'mood_7': mood7,
      if (mood8 != null) 'mood_8': mood8,
      if (moodFailed != null) 'mood_failed': moodFailed,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayLogCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String>? mode,
    Value<String>? learning,
    Value<String>? good,
    Value<String>? improve,
    Value<String>? controllable,
    Value<String>? uncontrollable,
    Value<String>? nextAction,
    Value<String>? moodNote,
    Value<int?>? mood1,
    Value<int?>? mood2,
    Value<int?>? mood3,
    Value<int?>? mood4,
    Value<int?>? mood5,
    Value<int?>? mood6,
    Value<int?>? mood7,
    Value<int?>? mood8,
    Value<int>? moodFailed,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return DayLogCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      mode: mode ?? this.mode,
      learning: learning ?? this.learning,
      good: good ?? this.good,
      improve: improve ?? this.improve,
      controllable: controllable ?? this.controllable,
      uncontrollable: uncontrollable ?? this.uncontrollable,
      nextAction: nextAction ?? this.nextAction,
      moodNote: moodNote ?? this.moodNote,
      mood1: mood1 ?? this.mood1,
      mood2: mood2 ?? this.mood2,
      mood3: mood3 ?? this.mood3,
      mood4: mood4 ?? this.mood4,
      mood5: mood5 ?? this.mood5,
      mood6: mood6 ?? this.mood6,
      mood7: mood7 ?? this.mood7,
      mood8: mood8 ?? this.mood8,
      moodFailed: moodFailed ?? this.moodFailed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (learning.present) {
      map['learning'] = Variable<String>(learning.value);
    }
    if (good.present) {
      map['good'] = Variable<String>(good.value);
    }
    if (improve.present) {
      map['improve'] = Variable<String>(improve.value);
    }
    if (controllable.present) {
      map['controllable'] = Variable<String>(controllable.value);
    }
    if (uncontrollable.present) {
      map['uncontrollable'] = Variable<String>(uncontrollable.value);
    }
    if (nextAction.present) {
      map['next_action'] = Variable<String>(nextAction.value);
    }
    if (moodNote.present) {
      map['mood_note'] = Variable<String>(moodNote.value);
    }
    if (mood1.present) {
      map['mood_1'] = Variable<int>(mood1.value);
    }
    if (mood2.present) {
      map['mood_2'] = Variable<int>(mood2.value);
    }
    if (mood3.present) {
      map['mood_3'] = Variable<int>(mood3.value);
    }
    if (mood4.present) {
      map['mood_4'] = Variable<int>(mood4.value);
    }
    if (mood5.present) {
      map['mood_5'] = Variable<int>(mood5.value);
    }
    if (mood6.present) {
      map['mood_6'] = Variable<int>(mood6.value);
    }
    if (mood7.present) {
      map['mood_7'] = Variable<int>(mood7.value);
    }
    if (mood8.present) {
      map['mood_8'] = Variable<int>(mood8.value);
    }
    if (moodFailed.present) {
      map['mood_failed'] = Variable<int>(moodFailed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayLogCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mode: $mode, ')
          ..write('learning: $learning, ')
          ..write('good: $good, ')
          ..write('improve: $improve, ')
          ..write('controllable: $controllable, ')
          ..write('uncontrollable: $uncontrollable, ')
          ..write('nextAction: $nextAction, ')
          ..write('moodNote: $moodNote, ')
          ..write('mood1: $mood1, ')
          ..write('mood2: $mood2, ')
          ..write('mood3: $mood3, ')
          ..write('mood4: $mood4, ')
          ..write('mood5: $mood5, ')
          ..write('mood6: $mood6, ')
          ..write('mood7: $mood7, ')
          ..write('mood8: $mood8, ')
          ..write('moodFailed: $moodFailed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectTable extends Project with TableInfo<$ProjectTable, ProjectData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalMeta = const VerificationMeta('goal');
  @override
  late final GeneratedColumn<String> goal = GeneratedColumn<String>(
    'goal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<int> archived = GeneratedColumn<int>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    goal,
    startDate,
    endDate,
    domain,
    status,
    archived,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('goal')) {
      context.handle(
        _goalMeta,
        goal.isAcceptableOrUnknown(data['goal']!, _goalMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      goal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $ProjectTable createAlias(String alias) {
    return $ProjectTable(attachedDatabase, alias);
  }
}

class ProjectData extends DataClass implements Insertable<ProjectData> {
  /// 实体 ID。
  final String id;

  /// 项目名称。
  final String name;

  /// 目标。
  final String goal;

  /// 开始日期。
  final String? startDate;

  /// 结束日期。
  final String? endDate;

  /// 领域标签。
  final String domain;

  /// 项目状态。
  final String status;

  /// 是否归档。
  final int archived;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const ProjectData({
    required this.id,
    required this.name,
    required this.goal,
    this.startDate,
    this.endDate,
    required this.domain,
    required this.status,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['goal'] = Variable<String>(goal);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    map['domain'] = Variable<String>(domain);
    map['status'] = Variable<String>(status);
    map['archived'] = Variable<int>(archived);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  ProjectCompanion toCompanion(bool nullToAbsent) {
    return ProjectCompanion(
      id: Value(id),
      name: Value(name),
      goal: Value(goal),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      domain: Value(domain),
      status: Value(status),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory ProjectData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      goal: serializer.fromJson<String>(json['goal']),
      startDate: serializer.fromJson<String?>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      domain: serializer.fromJson<String>(json['domain']),
      status: serializer.fromJson<String>(json['status']),
      archived: serializer.fromJson<int>(json['archived']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'goal': serializer.toJson<String>(goal),
      'startDate': serializer.toJson<String?>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'domain': serializer.toJson<String>(domain),
      'status': serializer.toJson<String>(status),
      'archived': serializer.toJson<int>(archived),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  ProjectData copyWith({
    String? id,
    String? name,
    String? goal,
    Value<String?> startDate = const Value.absent(),
    Value<String?> endDate = const Value.absent(),
    String? domain,
    String? status,
    int? archived,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => ProjectData(
    id: id ?? this.id,
    name: name ?? this.name,
    goal: goal ?? this.goal,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    domain: domain ?? this.domain,
    status: status ?? this.status,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  ProjectData copyWithCompanion(ProjectCompanion data) {
    return ProjectData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      goal: data.goal.present ? data.goal.value : this.goal,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      domain: data.domain.present ? data.domain.value : this.domain,
      status: data.status.present ? data.status.value : this.status,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('goal: $goal, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('domain: $domain, ')
          ..write('status: $status, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    goal,
    startDate,
    endDate,
    domain,
    status,
    archived,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectData &&
          other.id == this.id &&
          other.name == this.name &&
          other.goal == this.goal &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.domain == this.domain &&
          other.status == this.status &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class ProjectCompanion extends UpdateCompanion<ProjectData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> goal;
  final Value<String?> startDate;
  final Value<String?> endDate;
  final Value<String> domain;
  final Value<String> status;
  final Value<int> archived;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const ProjectCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.goal = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.domain = const Value.absent(),
    this.status = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectCompanion.insert({
    required String id,
    required String name,
    this.goal = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.domain = const Value.absent(),
    this.status = const Value.absent(),
    this.archived = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<ProjectData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? goal,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? domain,
    Expression<String>? status,
    Expression<int>? archived,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (goal != null) 'goal': goal,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (domain != null) 'domain': domain,
      if (status != null) 'status': status,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? goal,
    Value<String?>? startDate,
    Value<String?>? endDate,
    Value<String>? domain,
    Value<String>? status,
    Value<int>? archived,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return ProjectCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      domain: domain ?? this.domain,
      status: status ?? this.status,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(goal.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (archived.present) {
      map['archived'] = Variable<int>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('goal: $goal, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('domain: $domain, ')
          ..write('status: $status, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TodoTable extends Todo with TableInfo<$TodoTable, TodoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _estMinutesMeta = const VerificationMeta(
    'estMinutes',
  );
  @override
  late final GeneratedColumn<int> estMinutes = GeneratedColumn<int>(
    'est_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES project (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _quadrantMeta = const VerificationMeta(
    'quadrant',
  );
  @override
  late final GeneratedColumn<String> quadrant = GeneratedColumn<String>(
    'quadrant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityAbcMeta = const VerificationMeta(
    'priorityAbc',
  );
  @override
  late final GeneratedColumn<String> priorityAbc = GeneratedColumn<String>(
    'priority_abc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    detail,
    estMinutes,
    dueDate,
    projectId,
    quadrant,
    priorityAbc,
    status,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todo';
  @override
  VerificationContext validateIntegrity(
    Insertable<TodoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('est_minutes')) {
      context.handle(
        _estMinutesMeta,
        estMinutes.isAcceptableOrUnknown(data['est_minutes']!, _estMinutesMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('quadrant')) {
      context.handle(
        _quadrantMeta,
        quadrant.isAcceptableOrUnknown(data['quadrant']!, _quadrantMeta),
      );
    }
    if (data.containsKey('priority_abc')) {
      context.handle(
        _priorityAbcMeta,
        priorityAbc.isAcceptableOrUnknown(
          data['priority_abc']!,
          _priorityAbcMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      )!,
      estMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}est_minutes'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      quadrant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quadrant'],
      ),
      priorityAbc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority_abc'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $TodoTable createAlias(String alias) {
    return $TodoTable(attachedDatabase, alias);
  }
}

class TodoData extends DataClass implements Insertable<TodoData> {
  /// 实体 ID。
  final String id;

  /// 标题。
  final String title;

  /// 详情。
  final String detail;

  /// 预估分钟数。
  final int? estMinutes;

  /// 截止日历日。
  final String? dueDate;

  /// 所属项目。
  final String? projectId;

  /// 四象限。
  final String? quadrant;

  /// ABC 优先级。
  final String? priorityAbc;

  /// 状态。
  final String status;

  /// 完成时刻。
  final int? completedAt;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const TodoData({
    required this.id,
    required this.title,
    required this.detail,
    this.estMinutes,
    this.dueDate,
    this.projectId,
    this.quadrant,
    this.priorityAbc,
    required this.status,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['detail'] = Variable<String>(detail);
    if (!nullToAbsent || estMinutes != null) {
      map['est_minutes'] = Variable<int>(estMinutes);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || quadrant != null) {
      map['quadrant'] = Variable<String>(quadrant);
    }
    if (!nullToAbsent || priorityAbc != null) {
      map['priority_abc'] = Variable<String>(priorityAbc);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  TodoCompanion toCompanion(bool nullToAbsent) {
    return TodoCompanion(
      id: Value(id),
      title: Value(title),
      detail: Value(detail),
      estMinutes: estMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estMinutes),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      quadrant: quadrant == null && nullToAbsent
          ? const Value.absent()
          : Value(quadrant),
      priorityAbc: priorityAbc == null && nullToAbsent
          ? const Value.absent()
          : Value(priorityAbc),
      status: Value(status),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory TodoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      detail: serializer.fromJson<String>(json['detail']),
      estMinutes: serializer.fromJson<int?>(json['estMinutes']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      quadrant: serializer.fromJson<String?>(json['quadrant']),
      priorityAbc: serializer.fromJson<String?>(json['priorityAbc']),
      status: serializer.fromJson<String>(json['status']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'detail': serializer.toJson<String>(detail),
      'estMinutes': serializer.toJson<int?>(estMinutes),
      'dueDate': serializer.toJson<String?>(dueDate),
      'projectId': serializer.toJson<String?>(projectId),
      'quadrant': serializer.toJson<String?>(quadrant),
      'priorityAbc': serializer.toJson<String?>(priorityAbc),
      'status': serializer.toJson<String>(status),
      'completedAt': serializer.toJson<int?>(completedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  TodoData copyWith({
    String? id,
    String? title,
    String? detail,
    Value<int?> estMinutes = const Value.absent(),
    Value<String?> dueDate = const Value.absent(),
    Value<String?> projectId = const Value.absent(),
    Value<String?> quadrant = const Value.absent(),
    Value<String?> priorityAbc = const Value.absent(),
    String? status,
    Value<int?> completedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => TodoData(
    id: id ?? this.id,
    title: title ?? this.title,
    detail: detail ?? this.detail,
    estMinutes: estMinutes.present ? estMinutes.value : this.estMinutes,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    projectId: projectId.present ? projectId.value : this.projectId,
    quadrant: quadrant.present ? quadrant.value : this.quadrant,
    priorityAbc: priorityAbc.present ? priorityAbc.value : this.priorityAbc,
    status: status ?? this.status,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  TodoData copyWithCompanion(TodoCompanion data) {
    return TodoData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      detail: data.detail.present ? data.detail.value : this.detail,
      estMinutes: data.estMinutes.present
          ? data.estMinutes.value
          : this.estMinutes,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      quadrant: data.quadrant.present ? data.quadrant.value : this.quadrant,
      priorityAbc: data.priorityAbc.present
          ? data.priorityAbc.value
          : this.priorityAbc,
      status: data.status.present ? data.status.value : this.status,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('detail: $detail, ')
          ..write('estMinutes: $estMinutes, ')
          ..write('dueDate: $dueDate, ')
          ..write('projectId: $projectId, ')
          ..write('quadrant: $quadrant, ')
          ..write('priorityAbc: $priorityAbc, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    detail,
    estMinutes,
    dueDate,
    projectId,
    quadrant,
    priorityAbc,
    status,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoData &&
          other.id == this.id &&
          other.title == this.title &&
          other.detail == this.detail &&
          other.estMinutes == this.estMinutes &&
          other.dueDate == this.dueDate &&
          other.projectId == this.projectId &&
          other.quadrant == this.quadrant &&
          other.priorityAbc == this.priorityAbc &&
          other.status == this.status &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class TodoCompanion extends UpdateCompanion<TodoData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> detail;
  final Value<int?> estMinutes;
  final Value<String?> dueDate;
  final Value<String?> projectId;
  final Value<String?> quadrant;
  final Value<String?> priorityAbc;
  final Value<String> status;
  final Value<int?> completedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const TodoCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.detail = const Value.absent(),
    this.estMinutes = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.projectId = const Value.absent(),
    this.quadrant = const Value.absent(),
    this.priorityAbc = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodoCompanion.insert({
    required String id,
    required String title,
    this.detail = const Value.absent(),
    this.estMinutes = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.projectId = const Value.absent(),
    this.quadrant = const Value.absent(),
    this.priorityAbc = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<TodoData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? detail,
    Expression<int>? estMinutes,
    Expression<String>? dueDate,
    Expression<String>? projectId,
    Expression<String>? quadrant,
    Expression<String>? priorityAbc,
    Expression<String>? status,
    Expression<int>? completedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (detail != null) 'detail': detail,
      if (estMinutes != null) 'est_minutes': estMinutes,
      if (dueDate != null) 'due_date': dueDate,
      if (projectId != null) 'project_id': projectId,
      if (quadrant != null) 'quadrant': quadrant,
      if (priorityAbc != null) 'priority_abc': priorityAbc,
      if (status != null) 'status': status,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodoCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? detail,
    Value<int?>? estMinutes,
    Value<String?>? dueDate,
    Value<String?>? projectId,
    Value<String?>? quadrant,
    Value<String?>? priorityAbc,
    Value<String>? status,
    Value<int?>? completedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return TodoCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      estMinutes: estMinutes ?? this.estMinutes,
      dueDate: dueDate ?? this.dueDate,
      projectId: projectId ?? this.projectId,
      quadrant: quadrant ?? this.quadrant,
      priorityAbc: priorityAbc ?? this.priorityAbc,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (estMinutes.present) {
      map['est_minutes'] = Variable<int>(estMinutes.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (quadrant.present) {
      map['quadrant'] = Variable<String>(quadrant.value);
    }
    if (priorityAbc.present) {
      map['priority_abc'] = Variable<String>(priorityAbc.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('detail: $detail, ')
          ..write('estMinutes: $estMinutes, ')
          ..write('dueDate: $dueDate, ')
          ..write('projectId: $projectId, ')
          ..write('quadrant: $quadrant, ')
          ..write('priorityAbc: $priorityAbc, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanItemTable extends PlanItem
    with TableInfo<$PlanItemTable, PlanItemData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanItemTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTodoIdMeta = const VerificationMeta(
    'sourceTodoId',
  );
  @override
  late final GeneratedColumn<String> sourceTodoId = GeneratedColumn<String>(
    'source_todo_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES todo (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _quadrantMeta = const VerificationMeta(
    'quadrant',
  );
  @override
  late final GeneratedColumn<String> quadrant = GeneratedColumn<String>(
    'quadrant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityAbcMeta = const VerificationMeta(
    'priorityAbc',
  );
  @override
  late final GeneratedColumn<String> priorityAbc = GeneratedColumn<String>(
    'priority_abc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _estMinutesMeta = const VerificationMeta(
    'estMinutes',
  );
  @override
  late final GeneratedColumn<int> estMinutes = GeneratedColumn<int>(
    'est_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plannedStartMeta = const VerificationMeta(
    'plannedStart',
  );
  @override
  late final GeneratedColumn<int> plannedStart = GeneratedColumn<int>(
    'planned_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plannedEndMeta = const VerificationMeta(
    'plannedEnd',
  );
  @override
  late final GeneratedColumn<int> plannedEnd = GeneratedColumn<int>(
    'planned_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _doneAtMeta = const VerificationMeta('doneAt');
  @override
  late final GeneratedColumn<int> doneAt = GeneratedColumn<int>(
    'done_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultNoteMeta = const VerificationMeta(
    'resultNote',
  );
  @override
  late final GeneratedColumn<String> resultNote = GeneratedColumn<String>(
    'result_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isHabitRefMeta = const VerificationMeta(
    'isHabitRef',
  );
  @override
  late final GeneratedColumn<int> isHabitRef = GeneratedColumn<int>(
    'is_habit_ref',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    title,
    detail,
    sourceType,
    sourceId,
    sourceTodoId,
    quadrant,
    priorityAbc,
    domain,
    estMinutes,
    plannedStart,
    plannedEnd,
    status,
    doneAt,
    resultNote,
    isHabitRef,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_item';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanItemData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('source_todo_id')) {
      context.handle(
        _sourceTodoIdMeta,
        sourceTodoId.isAcceptableOrUnknown(
          data['source_todo_id']!,
          _sourceTodoIdMeta,
        ),
      );
    }
    if (data.containsKey('quadrant')) {
      context.handle(
        _quadrantMeta,
        quadrant.isAcceptableOrUnknown(data['quadrant']!, _quadrantMeta),
      );
    }
    if (data.containsKey('priority_abc')) {
      context.handle(
        _priorityAbcMeta,
        priorityAbc.isAcceptableOrUnknown(
          data['priority_abc']!,
          _priorityAbcMeta,
        ),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    }
    if (data.containsKey('est_minutes')) {
      context.handle(
        _estMinutesMeta,
        estMinutes.isAcceptableOrUnknown(data['est_minutes']!, _estMinutesMeta),
      );
    }
    if (data.containsKey('planned_start')) {
      context.handle(
        _plannedStartMeta,
        plannedStart.isAcceptableOrUnknown(
          data['planned_start']!,
          _plannedStartMeta,
        ),
      );
    }
    if (data.containsKey('planned_end')) {
      context.handle(
        _plannedEndMeta,
        plannedEnd.isAcceptableOrUnknown(data['planned_end']!, _plannedEndMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('done_at')) {
      context.handle(
        _doneAtMeta,
        doneAt.isAcceptableOrUnknown(data['done_at']!, _doneAtMeta),
      );
    }
    if (data.containsKey('result_note')) {
      context.handle(
        _resultNoteMeta,
        resultNote.isAcceptableOrUnknown(data['result_note']!, _resultNoteMeta),
      );
    }
    if (data.containsKey('is_habit_ref')) {
      context.handle(
        _isHabitRefMeta,
        isHabitRef.isAcceptableOrUnknown(
          data['is_habit_ref']!,
          _isHabitRefMeta,
        ),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanItemData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanItemData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      sourceTodoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_todo_id'],
      ),
      quadrant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quadrant'],
      ),
      priorityAbc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority_abc'],
      ),
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      estMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}est_minutes'],
      ),
      plannedStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_start'],
      ),
      plannedEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_end'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      doneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}done_at'],
      ),
      resultNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_note'],
      )!,
      isHabitRef: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_habit_ref'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $PlanItemTable createAlias(String alias) {
    return $PlanItemTable(attachedDatabase, alias);
  }
}

class PlanItemData extends DataClass implements Insertable<PlanItemData> {
  /// 实体 ID。
  final String id;

  /// 所属日历日 'YYYY-MM-DD'。
  final String date;

  /// 标题（来源为待办时存的是当时的标题快照）。
  final String title;

  /// 详情。
  final String detail;

  /// 来源类型。
  final String sourceType;

  /// 多态来源指针。
  final String? sourceId;

  /// 显式指向 todo.id。
  final String? sourceTodoId;

  /// 四象限。
  final String? quadrant;

  /// ABC 优先级。
  final String? priorityAbc;

  /// 领域标签。
  final String domain;

  /// 预估分钟数。
  final int? estMinutes;

  /// 计划开始时刻。
  final int? plannedStart;

  /// 计划结束时刻。
  final int? plannedEnd;

  /// 状态。
  final String status;

  /// 完成时刻。
  final int? doneAt;

  /// 成果 / 进展备注。
  final String resultNote;

  /// 是否由习惯打卡回填生成。
  final int isHabitRef;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const PlanItemData({
    required this.id,
    required this.date,
    required this.title,
    required this.detail,
    required this.sourceType,
    this.sourceId,
    this.sourceTodoId,
    this.quadrant,
    this.priorityAbc,
    required this.domain,
    this.estMinutes,
    this.plannedStart,
    this.plannedEnd,
    required this.status,
    this.doneAt,
    required this.resultNote,
    required this.isHabitRef,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['title'] = Variable<String>(title);
    map['detail'] = Variable<String>(detail);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || sourceTodoId != null) {
      map['source_todo_id'] = Variable<String>(sourceTodoId);
    }
    if (!nullToAbsent || quadrant != null) {
      map['quadrant'] = Variable<String>(quadrant);
    }
    if (!nullToAbsent || priorityAbc != null) {
      map['priority_abc'] = Variable<String>(priorityAbc);
    }
    map['domain'] = Variable<String>(domain);
    if (!nullToAbsent || estMinutes != null) {
      map['est_minutes'] = Variable<int>(estMinutes);
    }
    if (!nullToAbsent || plannedStart != null) {
      map['planned_start'] = Variable<int>(plannedStart);
    }
    if (!nullToAbsent || plannedEnd != null) {
      map['planned_end'] = Variable<int>(plannedEnd);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<int>(doneAt);
    }
    map['result_note'] = Variable<String>(resultNote);
    map['is_habit_ref'] = Variable<int>(isHabitRef);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  PlanItemCompanion toCompanion(bool nullToAbsent) {
    return PlanItemCompanion(
      id: Value(id),
      date: Value(date),
      title: Value(title),
      detail: Value(detail),
      sourceType: Value(sourceType),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      sourceTodoId: sourceTodoId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceTodoId),
      quadrant: quadrant == null && nullToAbsent
          ? const Value.absent()
          : Value(quadrant),
      priorityAbc: priorityAbc == null && nullToAbsent
          ? const Value.absent()
          : Value(priorityAbc),
      domain: Value(domain),
      estMinutes: estMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estMinutes),
      plannedStart: plannedStart == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedStart),
      plannedEnd: plannedEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedEnd),
      status: Value(status),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
      resultNote: Value(resultNote),
      isHabitRef: Value(isHabitRef),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory PlanItemData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanItemData(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      title: serializer.fromJson<String>(json['title']),
      detail: serializer.fromJson<String>(json['detail']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      sourceTodoId: serializer.fromJson<String?>(json['sourceTodoId']),
      quadrant: serializer.fromJson<String?>(json['quadrant']),
      priorityAbc: serializer.fromJson<String?>(json['priorityAbc']),
      domain: serializer.fromJson<String>(json['domain']),
      estMinutes: serializer.fromJson<int?>(json['estMinutes']),
      plannedStart: serializer.fromJson<int?>(json['plannedStart']),
      plannedEnd: serializer.fromJson<int?>(json['plannedEnd']),
      status: serializer.fromJson<String>(json['status']),
      doneAt: serializer.fromJson<int?>(json['doneAt']),
      resultNote: serializer.fromJson<String>(json['resultNote']),
      isHabitRef: serializer.fromJson<int>(json['isHabitRef']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'title': serializer.toJson<String>(title),
      'detail': serializer.toJson<String>(detail),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceId': serializer.toJson<String?>(sourceId),
      'sourceTodoId': serializer.toJson<String?>(sourceTodoId),
      'quadrant': serializer.toJson<String?>(quadrant),
      'priorityAbc': serializer.toJson<String?>(priorityAbc),
      'domain': serializer.toJson<String>(domain),
      'estMinutes': serializer.toJson<int?>(estMinutes),
      'plannedStart': serializer.toJson<int?>(plannedStart),
      'plannedEnd': serializer.toJson<int?>(plannedEnd),
      'status': serializer.toJson<String>(status),
      'doneAt': serializer.toJson<int?>(doneAt),
      'resultNote': serializer.toJson<String>(resultNote),
      'isHabitRef': serializer.toJson<int>(isHabitRef),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  PlanItemData copyWith({
    String? id,
    String? date,
    String? title,
    String? detail,
    String? sourceType,
    Value<String?> sourceId = const Value.absent(),
    Value<String?> sourceTodoId = const Value.absent(),
    Value<String?> quadrant = const Value.absent(),
    Value<String?> priorityAbc = const Value.absent(),
    String? domain,
    Value<int?> estMinutes = const Value.absent(),
    Value<int?> plannedStart = const Value.absent(),
    Value<int?> plannedEnd = const Value.absent(),
    String? status,
    Value<int?> doneAt = const Value.absent(),
    String? resultNote,
    int? isHabitRef,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => PlanItemData(
    id: id ?? this.id,
    date: date ?? this.date,
    title: title ?? this.title,
    detail: detail ?? this.detail,
    sourceType: sourceType ?? this.sourceType,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    sourceTodoId: sourceTodoId.present ? sourceTodoId.value : this.sourceTodoId,
    quadrant: quadrant.present ? quadrant.value : this.quadrant,
    priorityAbc: priorityAbc.present ? priorityAbc.value : this.priorityAbc,
    domain: domain ?? this.domain,
    estMinutes: estMinutes.present ? estMinutes.value : this.estMinutes,
    plannedStart: plannedStart.present ? plannedStart.value : this.plannedStart,
    plannedEnd: plannedEnd.present ? plannedEnd.value : this.plannedEnd,
    status: status ?? this.status,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
    resultNote: resultNote ?? this.resultNote,
    isHabitRef: isHabitRef ?? this.isHabitRef,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  PlanItemData copyWithCompanion(PlanItemCompanion data) {
    return PlanItemData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      title: data.title.present ? data.title.value : this.title,
      detail: data.detail.present ? data.detail.value : this.detail,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sourceTodoId: data.sourceTodoId.present
          ? data.sourceTodoId.value
          : this.sourceTodoId,
      quadrant: data.quadrant.present ? data.quadrant.value : this.quadrant,
      priorityAbc: data.priorityAbc.present
          ? data.priorityAbc.value
          : this.priorityAbc,
      domain: data.domain.present ? data.domain.value : this.domain,
      estMinutes: data.estMinutes.present
          ? data.estMinutes.value
          : this.estMinutes,
      plannedStart: data.plannedStart.present
          ? data.plannedStart.value
          : this.plannedStart,
      plannedEnd: data.plannedEnd.present
          ? data.plannedEnd.value
          : this.plannedEnd,
      status: data.status.present ? data.status.value : this.status,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
      resultNote: data.resultNote.present
          ? data.resultNote.value
          : this.resultNote,
      isHabitRef: data.isHabitRef.present
          ? data.isHabitRef.value
          : this.isHabitRef,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanItemData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('title: $title, ')
          ..write('detail: $detail, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceTodoId: $sourceTodoId, ')
          ..write('quadrant: $quadrant, ')
          ..write('priorityAbc: $priorityAbc, ')
          ..write('domain: $domain, ')
          ..write('estMinutes: $estMinutes, ')
          ..write('plannedStart: $plannedStart, ')
          ..write('plannedEnd: $plannedEnd, ')
          ..write('status: $status, ')
          ..write('doneAt: $doneAt, ')
          ..write('resultNote: $resultNote, ')
          ..write('isHabitRef: $isHabitRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    date,
    title,
    detail,
    sourceType,
    sourceId,
    sourceTodoId,
    quadrant,
    priorityAbc,
    domain,
    estMinutes,
    plannedStart,
    plannedEnd,
    status,
    doneAt,
    resultNote,
    isHabitRef,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanItemData &&
          other.id == this.id &&
          other.date == this.date &&
          other.title == this.title &&
          other.detail == this.detail &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.sourceTodoId == this.sourceTodoId &&
          other.quadrant == this.quadrant &&
          other.priorityAbc == this.priorityAbc &&
          other.domain == this.domain &&
          other.estMinutes == this.estMinutes &&
          other.plannedStart == this.plannedStart &&
          other.plannedEnd == this.plannedEnd &&
          other.status == this.status &&
          other.doneAt == this.doneAt &&
          other.resultNote == this.resultNote &&
          other.isHabitRef == this.isHabitRef &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class PlanItemCompanion extends UpdateCompanion<PlanItemData> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> title;
  final Value<String> detail;
  final Value<String> sourceType;
  final Value<String?> sourceId;
  final Value<String?> sourceTodoId;
  final Value<String?> quadrant;
  final Value<String?> priorityAbc;
  final Value<String> domain;
  final Value<int?> estMinutes;
  final Value<int?> plannedStart;
  final Value<int?> plannedEnd;
  final Value<String> status;
  final Value<int?> doneAt;
  final Value<String> resultNote;
  final Value<int> isHabitRef;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const PlanItemCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.title = const Value.absent(),
    this.detail = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourceTodoId = const Value.absent(),
    this.quadrant = const Value.absent(),
    this.priorityAbc = const Value.absent(),
    this.domain = const Value.absent(),
    this.estMinutes = const Value.absent(),
    this.plannedStart = const Value.absent(),
    this.plannedEnd = const Value.absent(),
    this.status = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.resultNote = const Value.absent(),
    this.isHabitRef = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanItemCompanion.insert({
    required String id,
    required String date,
    required String title,
    this.detail = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourceTodoId = const Value.absent(),
    this.quadrant = const Value.absent(),
    this.priorityAbc = const Value.absent(),
    this.domain = const Value.absent(),
    this.estMinutes = const Value.absent(),
    this.plannedStart = const Value.absent(),
    this.plannedEnd = const Value.absent(),
    this.status = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.resultNote = const Value.absent(),
    this.isHabitRef = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<PlanItemData> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? title,
    Expression<String>? detail,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? sourceTodoId,
    Expression<String>? quadrant,
    Expression<String>? priorityAbc,
    Expression<String>? domain,
    Expression<int>? estMinutes,
    Expression<int>? plannedStart,
    Expression<int>? plannedEnd,
    Expression<String>? status,
    Expression<int>? doneAt,
    Expression<String>? resultNote,
    Expression<int>? isHabitRef,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (title != null) 'title': title,
      if (detail != null) 'detail': detail,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (sourceTodoId != null) 'source_todo_id': sourceTodoId,
      if (quadrant != null) 'quadrant': quadrant,
      if (priorityAbc != null) 'priority_abc': priorityAbc,
      if (domain != null) 'domain': domain,
      if (estMinutes != null) 'est_minutes': estMinutes,
      if (plannedStart != null) 'planned_start': plannedStart,
      if (plannedEnd != null) 'planned_end': plannedEnd,
      if (status != null) 'status': status,
      if (doneAt != null) 'done_at': doneAt,
      if (resultNote != null) 'result_note': resultNote,
      if (isHabitRef != null) 'is_habit_ref': isHabitRef,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanItemCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String>? title,
    Value<String>? detail,
    Value<String>? sourceType,
    Value<String?>? sourceId,
    Value<String?>? sourceTodoId,
    Value<String?>? quadrant,
    Value<String?>? priorityAbc,
    Value<String>? domain,
    Value<int?>? estMinutes,
    Value<int?>? plannedStart,
    Value<int?>? plannedEnd,
    Value<String>? status,
    Value<int?>? doneAt,
    Value<String>? resultNote,
    Value<int>? isHabitRef,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return PlanItemCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceTodoId: sourceTodoId ?? this.sourceTodoId,
      quadrant: quadrant ?? this.quadrant,
      priorityAbc: priorityAbc ?? this.priorityAbc,
      domain: domain ?? this.domain,
      estMinutes: estMinutes ?? this.estMinutes,
      plannedStart: plannedStart ?? this.plannedStart,
      plannedEnd: plannedEnd ?? this.plannedEnd,
      status: status ?? this.status,
      doneAt: doneAt ?? this.doneAt,
      resultNote: resultNote ?? this.resultNote,
      isHabitRef: isHabitRef ?? this.isHabitRef,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sourceTodoId.present) {
      map['source_todo_id'] = Variable<String>(sourceTodoId.value);
    }
    if (quadrant.present) {
      map['quadrant'] = Variable<String>(quadrant.value);
    }
    if (priorityAbc.present) {
      map['priority_abc'] = Variable<String>(priorityAbc.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (estMinutes.present) {
      map['est_minutes'] = Variable<int>(estMinutes.value);
    }
    if (plannedStart.present) {
      map['planned_start'] = Variable<int>(plannedStart.value);
    }
    if (plannedEnd.present) {
      map['planned_end'] = Variable<int>(plannedEnd.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<int>(doneAt.value);
    }
    if (resultNote.present) {
      map['result_note'] = Variable<String>(resultNote.value);
    }
    if (isHabitRef.present) {
      map['is_habit_ref'] = Variable<int>(isHabitRef.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanItemCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('title: $title, ')
          ..write('detail: $detail, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceTodoId: $sourceTodoId, ')
          ..write('quadrant: $quadrant, ')
          ..write('priorityAbc: $priorityAbc, ')
          ..write('domain: $domain, ')
          ..write('estMinutes: $estMinutes, ')
          ..write('plannedStart: $plannedStart, ')
          ..write('plannedEnd: $plannedEnd, ')
          ..write('status: $status, ')
          ..write('doneAt: $doneAt, ')
          ..write('resultNote: $resultNote, ')
          ..write('isHabitRef: $isHabitRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitTable extends Habit with TableInfo<$HabitTable, HabitData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _targetCountMeta = const VerificationMeta(
    'targetCount',
  );
  @override
  late final GeneratedColumn<double> targetCount = GeneratedColumn<double>(
    'target_count',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetUnitMeta = const VerificationMeta(
    'targetUnit',
  );
  @override
  late final GeneratedColumn<String> targetUnit = GeneratedColumn<String>(
    'target_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _scheduleTypeMeta = const VerificationMeta(
    'scheduleType',
  );
  @override
  late final GeneratedColumn<String> scheduleType = GeneratedColumn<String>(
    'schedule_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('daily'),
  );
  static const VerificationMeta _weeklyNMeta = const VerificationMeta(
    'weeklyN',
  );
  @override
  late final GeneratedColumn<int> weeklyN = GeneratedColumn<int>(
    'weekly_n',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weekdaysMeta = const VerificationMeta(
    'weekdays',
  );
  @override
  late final GeneratedColumn<String> weekdays = GeneratedColumn<String>(
    'weekdays',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _checklistJsonMeta = const VerificationMeta(
    'checklistJson',
  );
  @override
  late final GeneratedColumn<String> checklistJson = GeneratedColumn<String>(
    'checklist_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<int> archived = GeneratedColumn<int>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pausedUntilMeta = const VerificationMeta(
    'pausedUntil',
  );
  @override
  late final GeneratedColumn<String> pausedUntil = GeneratedColumn<String>(
    'paused_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    type,
    targetCount,
    targetUnit,
    scheduleType,
    weeklyN,
    weekdays,
    checklistJson,
    domain,
    startDate,
    archived,
    pausedUntil,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('target_count')) {
      context.handle(
        _targetCountMeta,
        targetCount.isAcceptableOrUnknown(
          data['target_count']!,
          _targetCountMeta,
        ),
      );
    }
    if (data.containsKey('target_unit')) {
      context.handle(
        _targetUnitMeta,
        targetUnit.isAcceptableOrUnknown(data['target_unit']!, _targetUnitMeta),
      );
    }
    if (data.containsKey('schedule_type')) {
      context.handle(
        _scheduleTypeMeta,
        scheduleType.isAcceptableOrUnknown(
          data['schedule_type']!,
          _scheduleTypeMeta,
        ),
      );
    }
    if (data.containsKey('weekly_n')) {
      context.handle(
        _weeklyNMeta,
        weeklyN.isAcceptableOrUnknown(data['weekly_n']!, _weeklyNMeta),
      );
    }
    if (data.containsKey('weekdays')) {
      context.handle(
        _weekdaysMeta,
        weekdays.isAcceptableOrUnknown(data['weekdays']!, _weekdaysMeta),
      );
    }
    if (data.containsKey('checklist_json')) {
      context.handle(
        _checklistJsonMeta,
        checklistJson.isAcceptableOrUnknown(
          data['checklist_json']!,
          _checklistJsonMeta,
        ),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('paused_until')) {
      context.handle(
        _pausedUntilMeta,
        pausedUntil.isAcceptableOrUnknown(
          data['paused_until']!,
          _pausedUntilMeta,
        ),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      targetCount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_count'],
      ),
      targetUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_unit'],
      )!,
      scheduleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_type'],
      )!,
      weeklyN: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekly_n'],
      ),
      weekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekdays'],
      )!,
      checklistJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checklist_json'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived'],
      )!,
      pausedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paused_until'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $HabitTable createAlias(String alias) {
    return $HabitTable(attachedDatabase, alias);
  }
}

class HabitData extends DataClass implements Insertable<HabitData> {
  /// 实体 ID。
  final String id;

  /// 名称。
  final String name;

  /// 描述。
  final String description;

  /// 打卡类型。
  final String type;

  /// 计数型目标值。
  final double? targetCount;

  /// 计数单位。
  final String targetUnit;

  /// 排程方式。
  final String scheduleType;

  /// 每周 N 次。
  final int? weeklyN;

  /// 指定星期 '1,3,5'。
  final String weekdays;

  /// 清单式子项 JSON 数组字符串。
  final String checklistJson;

  /// 领域标签。
  final String domain;

  /// 开始日期。
  final String startDate;

  /// 是否归档。
  final int archived;

  /// 合法中断出口（假期模式）。
  final String? pausedUntil;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const HabitData({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.targetCount,
    required this.targetUnit,
    required this.scheduleType,
    this.weeklyN,
    required this.weekdays,
    required this.checklistJson,
    required this.domain,
    required this.startDate,
    required this.archived,
    this.pausedUntil,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || targetCount != null) {
      map['target_count'] = Variable<double>(targetCount);
    }
    map['target_unit'] = Variable<String>(targetUnit);
    map['schedule_type'] = Variable<String>(scheduleType);
    if (!nullToAbsent || weeklyN != null) {
      map['weekly_n'] = Variable<int>(weeklyN);
    }
    map['weekdays'] = Variable<String>(weekdays);
    map['checklist_json'] = Variable<String>(checklistJson);
    map['domain'] = Variable<String>(domain);
    map['start_date'] = Variable<String>(startDate);
    map['archived'] = Variable<int>(archived);
    if (!nullToAbsent || pausedUntil != null) {
      map['paused_until'] = Variable<String>(pausedUntil);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  HabitCompanion toCompanion(bool nullToAbsent) {
    return HabitCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      type: Value(type),
      targetCount: targetCount == null && nullToAbsent
          ? const Value.absent()
          : Value(targetCount),
      targetUnit: Value(targetUnit),
      scheduleType: Value(scheduleType),
      weeklyN: weeklyN == null && nullToAbsent
          ? const Value.absent()
          : Value(weeklyN),
      weekdays: Value(weekdays),
      checklistJson: Value(checklistJson),
      domain: Value(domain),
      startDate: Value(startDate),
      archived: Value(archived),
      pausedUntil: pausedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedUntil),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory HabitData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      targetCount: serializer.fromJson<double?>(json['targetCount']),
      targetUnit: serializer.fromJson<String>(json['targetUnit']),
      scheduleType: serializer.fromJson<String>(json['scheduleType']),
      weeklyN: serializer.fromJson<int?>(json['weeklyN']),
      weekdays: serializer.fromJson<String>(json['weekdays']),
      checklistJson: serializer.fromJson<String>(json['checklistJson']),
      domain: serializer.fromJson<String>(json['domain']),
      startDate: serializer.fromJson<String>(json['startDate']),
      archived: serializer.fromJson<int>(json['archived']),
      pausedUntil: serializer.fromJson<String?>(json['pausedUntil']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<String>(type),
      'targetCount': serializer.toJson<double?>(targetCount),
      'targetUnit': serializer.toJson<String>(targetUnit),
      'scheduleType': serializer.toJson<String>(scheduleType),
      'weeklyN': serializer.toJson<int?>(weeklyN),
      'weekdays': serializer.toJson<String>(weekdays),
      'checklistJson': serializer.toJson<String>(checklistJson),
      'domain': serializer.toJson<String>(domain),
      'startDate': serializer.toJson<String>(startDate),
      'archived': serializer.toJson<int>(archived),
      'pausedUntil': serializer.toJson<String?>(pausedUntil),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  HabitData copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    Value<double?> targetCount = const Value.absent(),
    String? targetUnit,
    String? scheduleType,
    Value<int?> weeklyN = const Value.absent(),
    String? weekdays,
    String? checklistJson,
    String? domain,
    String? startDate,
    int? archived,
    Value<String?> pausedUntil = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => HabitData(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type ?? this.type,
    targetCount: targetCount.present ? targetCount.value : this.targetCount,
    targetUnit: targetUnit ?? this.targetUnit,
    scheduleType: scheduleType ?? this.scheduleType,
    weeklyN: weeklyN.present ? weeklyN.value : this.weeklyN,
    weekdays: weekdays ?? this.weekdays,
    checklistJson: checklistJson ?? this.checklistJson,
    domain: domain ?? this.domain,
    startDate: startDate ?? this.startDate,
    archived: archived ?? this.archived,
    pausedUntil: pausedUntil.present ? pausedUntil.value : this.pausedUntil,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  HabitData copyWithCompanion(HabitCompanion data) {
    return HabitData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      targetCount: data.targetCount.present
          ? data.targetCount.value
          : this.targetCount,
      targetUnit: data.targetUnit.present
          ? data.targetUnit.value
          : this.targetUnit,
      scheduleType: data.scheduleType.present
          ? data.scheduleType.value
          : this.scheduleType,
      weeklyN: data.weeklyN.present ? data.weeklyN.value : this.weeklyN,
      weekdays: data.weekdays.present ? data.weekdays.value : this.weekdays,
      checklistJson: data.checklistJson.present
          ? data.checklistJson.value
          : this.checklistJson,
      domain: data.domain.present ? data.domain.value : this.domain,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      archived: data.archived.present ? data.archived.value : this.archived,
      pausedUntil: data.pausedUntil.present
          ? data.pausedUntil.value
          : this.pausedUntil,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('targetCount: $targetCount, ')
          ..write('targetUnit: $targetUnit, ')
          ..write('scheduleType: $scheduleType, ')
          ..write('weeklyN: $weeklyN, ')
          ..write('weekdays: $weekdays, ')
          ..write('checklistJson: $checklistJson, ')
          ..write('domain: $domain, ')
          ..write('startDate: $startDate, ')
          ..write('archived: $archived, ')
          ..write('pausedUntil: $pausedUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    type,
    targetCount,
    targetUnit,
    scheduleType,
    weeklyN,
    weekdays,
    checklistJson,
    domain,
    startDate,
    archived,
    pausedUntil,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.type == this.type &&
          other.targetCount == this.targetCount &&
          other.targetUnit == this.targetUnit &&
          other.scheduleType == this.scheduleType &&
          other.weeklyN == this.weeklyN &&
          other.weekdays == this.weekdays &&
          other.checklistJson == this.checklistJson &&
          other.domain == this.domain &&
          other.startDate == this.startDate &&
          other.archived == this.archived &&
          other.pausedUntil == this.pausedUntil &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class HabitCompanion extends UpdateCompanion<HabitData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String> type;
  final Value<double?> targetCount;
  final Value<String> targetUnit;
  final Value<String> scheduleType;
  final Value<int?> weeklyN;
  final Value<String> weekdays;
  final Value<String> checklistJson;
  final Value<String> domain;
  final Value<String> startDate;
  final Value<int> archived;
  final Value<String?> pausedUntil;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const HabitCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.targetCount = const Value.absent(),
    this.targetUnit = const Value.absent(),
    this.scheduleType = const Value.absent(),
    this.weeklyN = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.checklistJson = const Value.absent(),
    this.domain = const Value.absent(),
    this.startDate = const Value.absent(),
    this.archived = const Value.absent(),
    this.pausedUntil = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.targetCount = const Value.absent(),
    this.targetUnit = const Value.absent(),
    this.scheduleType = const Value.absent(),
    this.weeklyN = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.checklistJson = const Value.absent(),
    this.domain = const Value.absent(),
    required String startDate,
    this.archived = const Value.absent(),
    this.pausedUntil = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       startDate = Value(startDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<HabitData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? type,
    Expression<double>? targetCount,
    Expression<String>? targetUnit,
    Expression<String>? scheduleType,
    Expression<int>? weeklyN,
    Expression<String>? weekdays,
    Expression<String>? checklistJson,
    Expression<String>? domain,
    Expression<String>? startDate,
    Expression<int>? archived,
    Expression<String>? pausedUntil,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (targetCount != null) 'target_count': targetCount,
      if (targetUnit != null) 'target_unit': targetUnit,
      if (scheduleType != null) 'schedule_type': scheduleType,
      if (weeklyN != null) 'weekly_n': weeklyN,
      if (weekdays != null) 'weekdays': weekdays,
      if (checklistJson != null) 'checklist_json': checklistJson,
      if (domain != null) 'domain': domain,
      if (startDate != null) 'start_date': startDate,
      if (archived != null) 'archived': archived,
      if (pausedUntil != null) 'paused_until': pausedUntil,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<String>? type,
    Value<double?>? targetCount,
    Value<String>? targetUnit,
    Value<String>? scheduleType,
    Value<int?>? weeklyN,
    Value<String>? weekdays,
    Value<String>? checklistJson,
    Value<String>? domain,
    Value<String>? startDate,
    Value<int>? archived,
    Value<String?>? pausedUntil,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return HabitCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      targetUnit: targetUnit ?? this.targetUnit,
      scheduleType: scheduleType ?? this.scheduleType,
      weeklyN: weeklyN ?? this.weeklyN,
      weekdays: weekdays ?? this.weekdays,
      checklistJson: checklistJson ?? this.checklistJson,
      domain: domain ?? this.domain,
      startDate: startDate ?? this.startDate,
      archived: archived ?? this.archived,
      pausedUntil: pausedUntil ?? this.pausedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (targetCount.present) {
      map['target_count'] = Variable<double>(targetCount.value);
    }
    if (targetUnit.present) {
      map['target_unit'] = Variable<String>(targetUnit.value);
    }
    if (scheduleType.present) {
      map['schedule_type'] = Variable<String>(scheduleType.value);
    }
    if (weeklyN.present) {
      map['weekly_n'] = Variable<int>(weeklyN.value);
    }
    if (weekdays.present) {
      map['weekdays'] = Variable<String>(weekdays.value);
    }
    if (checklistJson.present) {
      map['checklist_json'] = Variable<String>(checklistJson.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (archived.present) {
      map['archived'] = Variable<int>(archived.value);
    }
    if (pausedUntil.present) {
      map['paused_until'] = Variable<String>(pausedUntil.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('targetCount: $targetCount, ')
          ..write('targetUnit: $targetUnit, ')
          ..write('scheduleType: $scheduleType, ')
          ..write('weeklyN: $weeklyN, ')
          ..write('weekdays: $weekdays, ')
          ..write('checklistJson: $checklistJson, ')
          ..write('domain: $domain, ')
          ..write('startDate: $startDate, ')
          ..write('archived: $archived, ')
          ..write('pausedUntil: $pausedUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitCheckinTable extends HabitCheckin
    with TableInfo<$HabitCheckinTable, HabitCheckinData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitCheckinTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habit (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1',
    defaultValue: const CustomExpression('1'),
    clientDefault: () => 1.0,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('done'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    habitId,
    date,
    value,
    status,
    note,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_checkin';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitCheckinData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitCheckinData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitCheckinData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $HabitCheckinTable createAlias(String alias) {
    return $HabitCheckinTable(attachedDatabase, alias);
  }
}

class HabitCheckinData extends DataClass
    implements Insertable<HabitCheckinData> {
  /// 实体 ID。
  final String id;

  /// 所属习惯。
  final String habitId;

  /// 打卡日期 'YYYY-MM-DD'。
  final String date;

  /// 计数型完成量。
  ///
  /// 权威 DDL 为 `value REAL NOT NULL DEFAULT 1`。drift 的 `real()` 列会把
  /// 默认值推断成 double 并写成 `DEFAULT 1.0`，与 schema_v1.sql 的字面量
  /// 不一致；这里改用列级自定义约束输出 `DEFAULT 1`，同时用 [clientDefault]
  /// 保留 drift 侧的客户端默认值（插入时可省略该列）。
  final double value;

  /// 打卡状态。
  final String status;

  /// 备注。
  final String note;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const HabitCheckinData({
    required this.id,
    required this.habitId,
    required this.date,
    required this.value,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habit_id'] = Variable<String>(habitId);
    map['date'] = Variable<String>(date);
    map['value'] = Variable<double>(value);
    map['status'] = Variable<String>(status);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  HabitCheckinCompanion toCompanion(bool nullToAbsent) {
    return HabitCheckinCompanion(
      id: Value(id),
      habitId: Value(habitId),
      date: Value(date),
      value: Value(value),
      status: Value(status),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory HabitCheckinData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitCheckinData(
      id: serializer.fromJson<String>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      date: serializer.fromJson<String>(json['date']),
      value: serializer.fromJson<double>(json['value']),
      status: serializer.fromJson<String>(json['status']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitId': serializer.toJson<String>(habitId),
      'date': serializer.toJson<String>(date),
      'value': serializer.toJson<double>(value),
      'status': serializer.toJson<String>(status),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  HabitCheckinData copyWith({
    String? id,
    String? habitId,
    String? date,
    double? value,
    String? status,
    String? note,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => HabitCheckinData(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    date: date ?? this.date,
    value: value ?? this.value,
    status: status ?? this.status,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  HabitCheckinData copyWithCompanion(HabitCheckinCompanion data) {
    return HabitCheckinData(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      date: data.date.present ? data.date.value : this.date,
      value: data.value.present ? data.value.value : this.value,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitCheckinData(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('value: $value, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    habitId,
    date,
    value,
    status,
    note,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitCheckinData &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.date == this.date &&
          other.value == this.value &&
          other.status == this.status &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class HabitCheckinCompanion extends UpdateCompanion<HabitCheckinData> {
  final Value<String> id;
  final Value<String> habitId;
  final Value<String> date;
  final Value<double> value;
  final Value<String> status;
  final Value<String> note;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const HabitCheckinCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.date = const Value.absent(),
    this.value = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitCheckinCompanion.insert({
    required String id,
    required String habitId,
    required String date,
    this.value = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       habitId = Value(habitId),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<HabitCheckinData> custom({
    Expression<String>? id,
    Expression<String>? habitId,
    Expression<String>? date,
    Expression<double>? value,
    Expression<String>? status,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (date != null) 'date': date,
      if (value != null) 'value': value,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitCheckinCompanion copyWith({
    Value<String>? id,
    Value<String>? habitId,
    Value<String>? date,
    Value<double>? value,
    Value<String>? status,
    Value<String>? note,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return HabitCheckinCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      value: value ?? this.value,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitCheckinCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('value: $value, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitScoreTable extends HabitScore
    with TableInfo<$HabitScoreTable, HabitScoreData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitScoreTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habit (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
    clientDefault: () => 0.0,
  );
  static const VerificationMeta _streakMeta = const VerificationMeta('streak');
  @override
  late final GeneratedColumn<int> streak = GeneratedColumn<int>(
    'streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _longestStreakMeta = const VerificationMeta(
    'longestStreak',
  );
  @override
  late final GeneratedColumn<int> longestStreak = GeneratedColumn<int>(
    'longest_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    habitId,
    date,
    score,
    streak,
    longestStreak,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_score';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitScoreData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('streak')) {
      context.handle(
        _streakMeta,
        streak.isAcceptableOrUnknown(data['streak']!, _streakMeta),
      );
    }
    if (data.containsKey('longest_streak')) {
      context.handle(
        _longestStreakMeta,
        longestStreak.isAcceptableOrUnknown(
          data['longest_streak']!,
          _longestStreakMeta,
        ),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitScoreData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitScoreData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      streak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak'],
      )!,
      longestStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_streak'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $HabitScoreTable createAlias(String alias) {
    return $HabitScoreTable(attachedDatabase, alias);
  }
}

class HabitScoreData extends DataClass implements Insertable<HabitScoreData> {
  /// 实体 ID。
  final String id;

  /// 所属习惯。
  final String habitId;

  /// 日期 'YYYY-MM-DD'。
  final String date;

  /// 当日强度评分（0–100）。
  ///
  /// 与 [HabitCheckins.value] 同理：用列级自定义约束输出 schema_v1.sql 的
  /// 字面量 `DEFAULT 0`（drift 的 real() 默认值会被写成 `0.0`）。
  final double score;

  /// 当前连续天数。
  final int streak;

  /// 历史最长连续天数。
  final int longestStreak;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const HabitScoreData({
    required this.id,
    required this.habitId,
    required this.date,
    required this.score,
    required this.streak,
    required this.longestStreak,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habit_id'] = Variable<String>(habitId);
    map['date'] = Variable<String>(date);
    map['score'] = Variable<double>(score);
    map['streak'] = Variable<int>(streak);
    map['longest_streak'] = Variable<int>(longestStreak);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  HabitScoreCompanion toCompanion(bool nullToAbsent) {
    return HabitScoreCompanion(
      id: Value(id),
      habitId: Value(habitId),
      date: Value(date),
      score: Value(score),
      streak: Value(streak),
      longestStreak: Value(longestStreak),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory HabitScoreData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitScoreData(
      id: serializer.fromJson<String>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      date: serializer.fromJson<String>(json['date']),
      score: serializer.fromJson<double>(json['score']),
      streak: serializer.fromJson<int>(json['streak']),
      longestStreak: serializer.fromJson<int>(json['longestStreak']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitId': serializer.toJson<String>(habitId),
      'date': serializer.toJson<String>(date),
      'score': serializer.toJson<double>(score),
      'streak': serializer.toJson<int>(streak),
      'longestStreak': serializer.toJson<int>(longestStreak),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  HabitScoreData copyWith({
    String? id,
    String? habitId,
    String? date,
    double? score,
    int? streak,
    int? longestStreak,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => HabitScoreData(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    date: date ?? this.date,
    score: score ?? this.score,
    streak: streak ?? this.streak,
    longestStreak: longestStreak ?? this.longestStreak,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  HabitScoreData copyWithCompanion(HabitScoreCompanion data) {
    return HabitScoreData(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      date: data.date.present ? data.date.value : this.date,
      score: data.score.present ? data.score.value : this.score,
      streak: data.streak.present ? data.streak.value : this.streak,
      longestStreak: data.longestStreak.present
          ? data.longestStreak.value
          : this.longestStreak,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitScoreData(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('score: $score, ')
          ..write('streak: $streak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    habitId,
    date,
    score,
    streak,
    longestStreak,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitScoreData &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.date == this.date &&
          other.score == this.score &&
          other.streak == this.streak &&
          other.longestStreak == this.longestStreak &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class HabitScoreCompanion extends UpdateCompanion<HabitScoreData> {
  final Value<String> id;
  final Value<String> habitId;
  final Value<String> date;
  final Value<double> score;
  final Value<int> streak;
  final Value<int> longestStreak;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const HabitScoreCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.date = const Value.absent(),
    this.score = const Value.absent(),
    this.streak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitScoreCompanion.insert({
    required String id,
    required String habitId,
    required String date,
    this.score = const Value.absent(),
    this.streak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       habitId = Value(habitId),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<HabitScoreData> custom({
    Expression<String>? id,
    Expression<String>? habitId,
    Expression<String>? date,
    Expression<double>? score,
    Expression<int>? streak,
    Expression<int>? longestStreak,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (date != null) 'date': date,
      if (score != null) 'score': score,
      if (streak != null) 'streak': streak,
      if (longestStreak != null) 'longest_streak': longestStreak,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitScoreCompanion copyWith({
    Value<String>? id,
    Value<String>? habitId,
    Value<String>? date,
    Value<double>? score,
    Value<int>? streak,
    Value<int>? longestStreak,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return HabitScoreCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      score: score ?? this.score,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (streak.present) {
      map['streak'] = Variable<int>(streak.value);
    }
    if (longestStreak.present) {
      map['longest_streak'] = Variable<int>(longestStreak.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitScoreCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('score: $score, ')
          ..write('streak: $streak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectMilestoneTable extends ProjectMilestone
    with TableInfo<$ProjectMilestoneTable, ProjectMilestoneData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectMilestoneTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES project (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _achievedAtMeta = const VerificationMeta(
    'achievedAt',
  );
  @override
  late final GeneratedColumn<int> achievedAt = GeneratedColumn<int>(
    'achieved_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    title,
    targetDate,
    achievedAt,
    note,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_milestone';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectMilestoneData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('achieved_at')) {
      context.handle(
        _achievedAtMeta,
        achievedAt.isAcceptableOrUnknown(data['achieved_at']!, _achievedAtMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectMilestoneData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectMilestoneData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_date'],
      ),
      achievedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}achieved_at'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $ProjectMilestoneTable createAlias(String alias) {
    return $ProjectMilestoneTable(attachedDatabase, alias);
  }
}

class ProjectMilestoneData extends DataClass
    implements Insertable<ProjectMilestoneData> {
  /// 实体 ID。
  final String id;

  /// 所属项目。
  final String projectId;

  /// 标题。
  final String title;

  /// 目标日期。
  final String? targetDate;

  /// 达成时刻。
  final int? achievedAt;

  /// 备注。
  final String note;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const ProjectMilestoneData({
    required this.id,
    required this.projectId,
    required this.title,
    this.targetDate,
    this.achievedAt,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<String>(targetDate);
    }
    if (!nullToAbsent || achievedAt != null) {
      map['achieved_at'] = Variable<int>(achievedAt);
    }
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  ProjectMilestoneCompanion toCompanion(bool nullToAbsent) {
    return ProjectMilestoneCompanion(
      id: Value(id),
      projectId: Value(projectId),
      title: Value(title),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      achievedAt: achievedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(achievedAt),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory ProjectMilestoneData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectMilestoneData(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      title: serializer.fromJson<String>(json['title']),
      targetDate: serializer.fromJson<String?>(json['targetDate']),
      achievedAt: serializer.fromJson<int?>(json['achievedAt']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'title': serializer.toJson<String>(title),
      'targetDate': serializer.toJson<String?>(targetDate),
      'achievedAt': serializer.toJson<int?>(achievedAt),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  ProjectMilestoneData copyWith({
    String? id,
    String? projectId,
    String? title,
    Value<String?> targetDate = const Value.absent(),
    Value<int?> achievedAt = const Value.absent(),
    String? note,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => ProjectMilestoneData(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    title: title ?? this.title,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    achievedAt: achievedAt.present ? achievedAt.value : this.achievedAt,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  ProjectMilestoneData copyWithCompanion(ProjectMilestoneCompanion data) {
    return ProjectMilestoneData(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      title: data.title.present ? data.title.value : this.title,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      achievedAt: data.achievedAt.present
          ? data.achievedAt.value
          : this.achievedAt,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectMilestoneData(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('targetDate: $targetDate, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    title,
    targetDate,
    achievedAt,
    note,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectMilestoneData &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.title == this.title &&
          other.targetDate == this.targetDate &&
          other.achievedAt == this.achievedAt &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class ProjectMilestoneCompanion extends UpdateCompanion<ProjectMilestoneData> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> title;
  final Value<String?> targetDate;
  final Value<int?> achievedAt;
  final Value<String> note;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const ProjectMilestoneCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectMilestoneCompanion.insert({
    required String id,
    required String projectId,
    required String title,
    this.targetDate = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.note = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<ProjectMilestoneData> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? title,
    Expression<String>? targetDate,
    Expression<int>? achievedAt,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (title != null) 'title': title,
      if (targetDate != null) 'target_date': targetDate,
      if (achievedAt != null) 'achieved_at': achievedAt,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectMilestoneCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? title,
    Value<String?>? targetDate,
    Value<int?>? achievedAt,
    Value<String>? note,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return ProjectMilestoneCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      achievedAt: achievedAt ?? this.achievedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (achievedAt.present) {
      map['achieved_at'] = Variable<int>(achievedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectMilestoneCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('targetDate: $targetDate, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectIncrementTable extends ProjectIncrement
    with TableInfo<$ProjectIncrementTable, ProjectIncrementData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectIncrementTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES project (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planItemIdMeta = const VerificationMeta(
    'planItemId',
  );
  @override
  late final GeneratedColumn<String> planItemId = GeneratedColumn<String>(
    'plan_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plan_item (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<String> progress = GeneratedColumn<String>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _blockersMeta = const VerificationMeta(
    'blockers',
  );
  @override
  late final GeneratedColumn<String> blockers = GeneratedColumn<String>(
    'blockers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nextStepMeta = const VerificationMeta(
    'nextStep',
  );
  @override
  late final GeneratedColumn<String> nextStep = GeneratedColumn<String>(
    'next_step',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    date,
    planItemId,
    progress,
    blockers,
    nextStep,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_increment';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectIncrementData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('plan_item_id')) {
      context.handle(
        _planItemIdMeta,
        planItemId.isAcceptableOrUnknown(
          data['plan_item_id']!,
          _planItemIdMeta,
        ),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('blockers')) {
      context.handle(
        _blockersMeta,
        blockers.isAcceptableOrUnknown(data['blockers']!, _blockersMeta),
      );
    }
    if (data.containsKey('next_step')) {
      context.handle(
        _nextStepMeta,
        nextStep.isAcceptableOrUnknown(data['next_step']!, _nextStepMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectIncrementData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectIncrementData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      planItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_item_id'],
      ),
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}progress'],
      )!,
      blockers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blockers'],
      )!,
      nextStep: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_step'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $ProjectIncrementTable createAlias(String alias) {
    return $ProjectIncrementTable(attachedDatabase, alias);
  }
}

class ProjectIncrementData extends DataClass
    implements Insertable<ProjectIncrementData> {
  /// 实体 ID。
  final String id;

  /// 所属项目。
  final String projectId;

  /// 日期 'YYYY-MM-DD'。
  final String date;

  /// 关联的计划条目。
  final String? planItemId;

  /// 进展。
  final String progress;

  /// 阻塞项。
  final String blockers;

  /// 下一步。
  final String nextStep;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const ProjectIncrementData({
    required this.id,
    required this.projectId,
    required this.date,
    this.planItemId,
    required this.progress,
    required this.blockers,
    required this.nextStep,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || planItemId != null) {
      map['plan_item_id'] = Variable<String>(planItemId);
    }
    map['progress'] = Variable<String>(progress);
    map['blockers'] = Variable<String>(blockers);
    map['next_step'] = Variable<String>(nextStep);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  ProjectIncrementCompanion toCompanion(bool nullToAbsent) {
    return ProjectIncrementCompanion(
      id: Value(id),
      projectId: Value(projectId),
      date: Value(date),
      planItemId: planItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(planItemId),
      progress: Value(progress),
      blockers: Value(blockers),
      nextStep: Value(nextStep),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory ProjectIncrementData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectIncrementData(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      date: serializer.fromJson<String>(json['date']),
      planItemId: serializer.fromJson<String?>(json['planItemId']),
      progress: serializer.fromJson<String>(json['progress']),
      blockers: serializer.fromJson<String>(json['blockers']),
      nextStep: serializer.fromJson<String>(json['nextStep']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'date': serializer.toJson<String>(date),
      'planItemId': serializer.toJson<String?>(planItemId),
      'progress': serializer.toJson<String>(progress),
      'blockers': serializer.toJson<String>(blockers),
      'nextStep': serializer.toJson<String>(nextStep),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  ProjectIncrementData copyWith({
    String? id,
    String? projectId,
    String? date,
    Value<String?> planItemId = const Value.absent(),
    String? progress,
    String? blockers,
    String? nextStep,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => ProjectIncrementData(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    date: date ?? this.date,
    planItemId: planItemId.present ? planItemId.value : this.planItemId,
    progress: progress ?? this.progress,
    blockers: blockers ?? this.blockers,
    nextStep: nextStep ?? this.nextStep,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  ProjectIncrementData copyWithCompanion(ProjectIncrementCompanion data) {
    return ProjectIncrementData(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      date: data.date.present ? data.date.value : this.date,
      planItemId: data.planItemId.present
          ? data.planItemId.value
          : this.planItemId,
      progress: data.progress.present ? data.progress.value : this.progress,
      blockers: data.blockers.present ? data.blockers.value : this.blockers,
      nextStep: data.nextStep.present ? data.nextStep.value : this.nextStep,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectIncrementData(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('date: $date, ')
          ..write('planItemId: $planItemId, ')
          ..write('progress: $progress, ')
          ..write('blockers: $blockers, ')
          ..write('nextStep: $nextStep, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    date,
    planItemId,
    progress,
    blockers,
    nextStep,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectIncrementData &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.date == this.date &&
          other.planItemId == this.planItemId &&
          other.progress == this.progress &&
          other.blockers == this.blockers &&
          other.nextStep == this.nextStep &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class ProjectIncrementCompanion extends UpdateCompanion<ProjectIncrementData> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> date;
  final Value<String?> planItemId;
  final Value<String> progress;
  final Value<String> blockers;
  final Value<String> nextStep;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const ProjectIncrementCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.date = const Value.absent(),
    this.planItemId = const Value.absent(),
    this.progress = const Value.absent(),
    this.blockers = const Value.absent(),
    this.nextStep = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectIncrementCompanion.insert({
    required String id,
    required String projectId,
    required String date,
    this.planItemId = const Value.absent(),
    this.progress = const Value.absent(),
    this.blockers = const Value.absent(),
    this.nextStep = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<ProjectIncrementData> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? date,
    Expression<String>? planItemId,
    Expression<String>? progress,
    Expression<String>? blockers,
    Expression<String>? nextStep,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (date != null) 'date': date,
      if (planItemId != null) 'plan_item_id': planItemId,
      if (progress != null) 'progress': progress,
      if (blockers != null) 'blockers': blockers,
      if (nextStep != null) 'next_step': nextStep,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectIncrementCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? date,
    Value<String?>? planItemId,
    Value<String>? progress,
    Value<String>? blockers,
    Value<String>? nextStep,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return ProjectIncrementCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      planItemId: planItemId ?? this.planItemId,
      progress: progress ?? this.progress,
      blockers: blockers ?? this.blockers,
      nextStep: nextStep ?? this.nextStep,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (planItemId.present) {
      map['plan_item_id'] = Variable<String>(planItemId.value);
    }
    if (progress.present) {
      map['progress'] = Variable<String>(progress.value);
    }
    if (blockers.present) {
      map['blockers'] = Variable<String>(blockers.value);
    }
    if (nextStep.present) {
      map['next_step'] = Variable<String>(nextStep.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectIncrementCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('date: $date, ')
          ..write('planItemId: $planItemId, ')
          ..write('progress: $progress, ')
          ..write('blockers: $blockers, ')
          ..write('nextStep: $nextStep, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReminderTable extends Reminder
    with TableInfo<$ReminderTable, ReminderData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remindAtMeta = const VerificationMeta(
    'remindAt',
  );
  @override
  late final GeneratedColumn<int> remindAt = GeneratedColumn<int>(
    'remind_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repeatRuleMeta = const VerificationMeta(
    'repeatRule',
  );
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
    'repeat_rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _repeatDetailMeta = const VerificationMeta(
    'repeatDetail',
  );
  @override
  late final GeneratedColumn<String> repeatDetail = GeneratedColumn<String>(
    'repeat_detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<int> enabled = GeneratedColumn<int>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastFiredAtMeta = const VerificationMeta(
    'lastFiredAt',
  );
  @override
  late final GeneratedColumn<int> lastFiredAt = GeneratedColumn<int>(
    'last_fired_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetType,
    targetId,
    remindAt,
    repeatRule,
    repeatDetail,
    enabled,
    lastFiredAt,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('remind_at')) {
      context.handle(
        _remindAtMeta,
        remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta),
      );
    } else if (isInserting) {
      context.missing(_remindAtMeta);
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
        _repeatRuleMeta,
        repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta),
      );
    }
    if (data.containsKey('repeat_detail')) {
      context.handle(
        _repeatDetailMeta,
        repeatDetail.isAcceptableOrUnknown(
          data['repeat_detail']!,
          _repeatDetailMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('last_fired_at')) {
      context.handle(
        _lastFiredAtMeta,
        lastFiredAt.isAcceptableOrUnknown(
          data['last_fired_at']!,
          _lastFiredAtMeta,
        ),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      remindAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_at'],
      )!,
      repeatRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_rule'],
      )!,
      repeatDetail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_detail'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}enabled'],
      )!,
      lastFiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_fired_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $ReminderTable createAlias(String alias) {
    return $ReminderTable(attachedDatabase, alias);
  }
}

class ReminderData extends DataClass implements Insertable<ReminderData> {
  /// 实体 ID。
  final String id;

  /// 目标实体类型。
  final String targetType;

  /// 目标实体 ID（多态指针，不设 FK）。
  final String targetId;

  /// 提醒时刻。
  final int remindAt;

  /// 重复规则。
  final String repeatRule;

  /// 重复附加参数。
  final String repeatDetail;

  /// 是否启用。
  final int enabled;

  /// 上次触发时刻。
  final int? lastFiredAt;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const ReminderData({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.remindAt,
    required this.repeatRule,
    required this.repeatDetail,
    required this.enabled,
    this.lastFiredAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<String>(targetId);
    map['remind_at'] = Variable<int>(remindAt);
    map['repeat_rule'] = Variable<String>(repeatRule);
    map['repeat_detail'] = Variable<String>(repeatDetail);
    map['enabled'] = Variable<int>(enabled);
    if (!nullToAbsent || lastFiredAt != null) {
      map['last_fired_at'] = Variable<int>(lastFiredAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  ReminderCompanion toCompanion(bool nullToAbsent) {
    return ReminderCompanion(
      id: Value(id),
      targetType: Value(targetType),
      targetId: Value(targetId),
      remindAt: Value(remindAt),
      repeatRule: Value(repeatRule),
      repeatDetail: Value(repeatDetail),
      enabled: Value(enabled),
      lastFiredAt: lastFiredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFiredAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory ReminderData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderData(
      id: serializer.fromJson<String>(json['id']),
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String>(json['targetId']),
      remindAt: serializer.fromJson<int>(json['remindAt']),
      repeatRule: serializer.fromJson<String>(json['repeatRule']),
      repeatDetail: serializer.fromJson<String>(json['repeatDetail']),
      enabled: serializer.fromJson<int>(json['enabled']),
      lastFiredAt: serializer.fromJson<int?>(json['lastFiredAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String>(targetId),
      'remindAt': serializer.toJson<int>(remindAt),
      'repeatRule': serializer.toJson<String>(repeatRule),
      'repeatDetail': serializer.toJson<String>(repeatDetail),
      'enabled': serializer.toJson<int>(enabled),
      'lastFiredAt': serializer.toJson<int?>(lastFiredAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  ReminderData copyWith({
    String? id,
    String? targetType,
    String? targetId,
    int? remindAt,
    String? repeatRule,
    String? repeatDetail,
    int? enabled,
    Value<int?> lastFiredAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => ReminderData(
    id: id ?? this.id,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    remindAt: remindAt ?? this.remindAt,
    repeatRule: repeatRule ?? this.repeatRule,
    repeatDetail: repeatDetail ?? this.repeatDetail,
    enabled: enabled ?? this.enabled,
    lastFiredAt: lastFiredAt.present ? lastFiredAt.value : this.lastFiredAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  ReminderData copyWithCompanion(ReminderCompanion data) {
    return ReminderData(
      id: data.id.present ? data.id.value : this.id,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
      repeatRule: data.repeatRule.present
          ? data.repeatRule.value
          : this.repeatRule,
      repeatDetail: data.repeatDetail.present
          ? data.repeatDetail.value
          : this.repeatDetail,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      lastFiredAt: data.lastFiredAt.present
          ? data.lastFiredAt.value
          : this.lastFiredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderData(')
          ..write('id: $id, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('remindAt: $remindAt, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('repeatDetail: $repeatDetail, ')
          ..write('enabled: $enabled, ')
          ..write('lastFiredAt: $lastFiredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetType,
    targetId,
    remindAt,
    repeatRule,
    repeatDetail,
    enabled,
    lastFiredAt,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderData &&
          other.id == this.id &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.remindAt == this.remindAt &&
          other.repeatRule == this.repeatRule &&
          other.repeatDetail == this.repeatDetail &&
          other.enabled == this.enabled &&
          other.lastFiredAt == this.lastFiredAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class ReminderCompanion extends UpdateCompanion<ReminderData> {
  final Value<String> id;
  final Value<String> targetType;
  final Value<String> targetId;
  final Value<int> remindAt;
  final Value<String> repeatRule;
  final Value<String> repeatDetail;
  final Value<int> enabled;
  final Value<int?> lastFiredAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const ReminderCompanion({
    this.id = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.repeatDetail = const Value.absent(),
    this.enabled = const Value.absent(),
    this.lastFiredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderCompanion.insert({
    required String id,
    required String targetType,
    required String targetId,
    required int remindAt,
    this.repeatRule = const Value.absent(),
    this.repeatDetail = const Value.absent(),
    this.enabled = const Value.absent(),
    this.lastFiredAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       targetType = Value(targetType),
       targetId = Value(targetId),
       remindAt = Value(remindAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<ReminderData> custom({
    Expression<String>? id,
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<int>? remindAt,
    Expression<String>? repeatRule,
    Expression<String>? repeatDetail,
    Expression<int>? enabled,
    Expression<int>? lastFiredAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (remindAt != null) 'remind_at': remindAt,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (repeatDetail != null) 'repeat_detail': repeatDetail,
      if (enabled != null) 'enabled': enabled,
      if (lastFiredAt != null) 'last_fired_at': lastFiredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderCompanion copyWith({
    Value<String>? id,
    Value<String>? targetType,
    Value<String>? targetId,
    Value<int>? remindAt,
    Value<String>? repeatRule,
    Value<String>? repeatDetail,
    Value<int>? enabled,
    Value<int?>? lastFiredAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return ReminderCompanion(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      remindAt: remindAt ?? this.remindAt,
      repeatRule: repeatRule ?? this.repeatRule,
      repeatDetail: repeatDetail ?? this.repeatDetail,
      enabled: enabled ?? this.enabled,
      lastFiredAt: lastFiredAt ?? this.lastFiredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<int>(remindAt.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (repeatDetail.present) {
      map['repeat_detail'] = Variable<String>(repeatDetail.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<int>(enabled.value);
    }
    if (lastFiredAt.present) {
      map['last_fired_at'] = Variable<int>(lastFiredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderCompanion(')
          ..write('id: $id, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('remindAt: $remindAt, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('repeatDetail: $repeatDetail, ')
          ..write('enabled: $enabled, ')
          ..write('lastFiredAt: $lastFiredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OplogTable extends Oplog with TableInfo<$OplogTable, OplogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OplogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTableMeta = const VerificationMeta(
    'entityTable',
  );
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
    'entity_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lamportMeta = const VerificationMeta(
    'lamport',
  );
  @override
  late final GeneratedColumn<int> lamport = GeneratedColumn<int>(
    'lamport',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityTable,
    entityId,
    op,
    payload,
    lamport,
    deviceId,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oplog';
  @override
  VerificationContext validateIntegrity(
    Insertable<OplogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_table')) {
      context.handle(
        _entityTableMeta,
        entityTable.isAcceptableOrUnknown(
          data['entity_table']!,
          _entityTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('lamport')) {
      context.handle(
        _lamportMeta,
        lamport.isAcceptableOrUnknown(data['lamport']!, _lamportMeta),
      );
    } else if (isInserting) {
      context.missing(_lamportMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OplogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OplogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_table'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      lamport: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lamport'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $OplogTable createAlias(String alias) {
    return $OplogTable(attachedDatabase, alias);
  }
}

class OplogData extends DataClass implements Insertable<OplogData> {
  /// 自增 ID。
  final int id;

  /// 实体表名。
  final String entityTable;

  /// 实体 ID。
  final String entityId;

  /// 操作类型：upsert / delete。
  final String op;

  /// JSON 字段级 diff；delete 时为 {"deleted_at": ms}。
  final String? payload;

  /// 跨设备逻辑时钟（LWW 定序）。
  final int lamport;

  /// 产生该条变更的设备。
  final String deviceId;

  /// 记录时刻（Unix 毫秒）。
  final int createdAt;

  /// 是否已确认中继已收。
  final int synced;
  const OplogData({
    required this.id,
    required this.entityTable,
    required this.entityId,
    required this.op,
    this.payload,
    required this.lamport,
    required this.deviceId,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_table'] = Variable<String>(entityTable);
    map['entity_id'] = Variable<String>(entityId);
    map['op'] = Variable<String>(op);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['lamport'] = Variable<int>(lamport);
    map['device_id'] = Variable<String>(deviceId);
    map['created_at'] = Variable<int>(createdAt);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  OplogCompanion toCompanion(bool nullToAbsent) {
    return OplogCompanion(
      id: Value(id),
      entityTable: Value(entityTable),
      entityId: Value(entityId),
      op: Value(op),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      lamport: Value(lamport),
      deviceId: Value(deviceId),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory OplogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OplogData(
      id: serializer.fromJson<int>(json['id']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      entityId: serializer.fromJson<String>(json['entityId']),
      op: serializer.fromJson<String>(json['op']),
      payload: serializer.fromJson<String?>(json['payload']),
      lamport: serializer.fromJson<int>(json['lamport']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityTable': serializer.toJson<String>(entityTable),
      'entityId': serializer.toJson<String>(entityId),
      'op': serializer.toJson<String>(op),
      'payload': serializer.toJson<String?>(payload),
      'lamport': serializer.toJson<int>(lamport),
      'deviceId': serializer.toJson<String>(deviceId),
      'createdAt': serializer.toJson<int>(createdAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  OplogData copyWith({
    int? id,
    String? entityTable,
    String? entityId,
    String? op,
    Value<String?> payload = const Value.absent(),
    int? lamport,
    String? deviceId,
    int? createdAt,
    int? synced,
  }) => OplogData(
    id: id ?? this.id,
    entityTable: entityTable ?? this.entityTable,
    entityId: entityId ?? this.entityId,
    op: op ?? this.op,
    payload: payload.present ? payload.value : this.payload,
    lamport: lamport ?? this.lamport,
    deviceId: deviceId ?? this.deviceId,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  OplogData copyWithCompanion(OplogCompanion data) {
    return OplogData(
      id: data.id.present ? data.id.value : this.id,
      entityTable: data.entityTable.present
          ? data.entityTable.value
          : this.entityTable,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      lamport: data.lamport.present ? data.lamport.value : this.lamport,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OplogData(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('lamport: $lamport, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityTable,
    entityId,
    op,
    payload,
    lamport,
    deviceId,
    createdAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OplogData &&
          other.id == this.id &&
          other.entityTable == this.entityTable &&
          other.entityId == this.entityId &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.lamport == this.lamport &&
          other.deviceId == this.deviceId &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class OplogCompanion extends UpdateCompanion<OplogData> {
  final Value<int> id;
  final Value<String> entityTable;
  final Value<String> entityId;
  final Value<String> op;
  final Value<String?> payload;
  final Value<int> lamport;
  final Value<String> deviceId;
  final Value<int> createdAt;
  final Value<int> synced;
  const OplogCompanion({
    this.id = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.entityId = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.lamport = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  OplogCompanion.insert({
    this.id = const Value.absent(),
    required String entityTable,
    required String entityId,
    required String op,
    this.payload = const Value.absent(),
    required int lamport,
    required String deviceId,
    required int createdAt,
    this.synced = const Value.absent(),
  }) : entityTable = Value(entityTable),
       entityId = Value(entityId),
       op = Value(op),
       lamport = Value(lamport),
       deviceId = Value(deviceId),
       createdAt = Value(createdAt);
  static Insertable<OplogData> custom({
    Expression<int>? id,
    Expression<String>? entityTable,
    Expression<String>? entityId,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<int>? lamport,
    Expression<String>? deviceId,
    Expression<int>? createdAt,
    Expression<int>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityTable != null) 'entity_table': entityTable,
      if (entityId != null) 'entity_id': entityId,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (lamport != null) 'lamport': lamport,
      if (deviceId != null) 'device_id': deviceId,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  OplogCompanion copyWith({
    Value<int>? id,
    Value<String>? entityTable,
    Value<String>? entityId,
    Value<String>? op,
    Value<String?>? payload,
    Value<int>? lamport,
    Value<String>? deviceId,
    Value<int>? createdAt,
    Value<int>? synced,
  }) {
    return OplogCompanion(
      id: id ?? this.id,
      entityTable: entityTable ?? this.entityTable,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      lamport: lamport ?? this.lamport,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (lamport.present) {
      map['lamport'] = Variable<int>(lamport.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OplogCompanion(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('lamport: $lamport, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    key,
    value,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  /// 实体 ID。
  final String id;

  /// 键。
  final String key;

  /// 值。
  final String value;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const SyncStateData({
    required this.id,
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      id: serializer.fromJson<String>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  SyncStateData copyWith({
    String? id,
    String? key,
    String? value,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => SyncStateData(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value ?? this.value,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    key,
    value,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> id;
  final Value<String> key;
  final Value<String> value;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String id,
    required String key,
    this.value = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       key = Value(key),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<SyncStateData> custom({
    Expression<String>? id,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? id,
    Value<String>? key,
    Value<String>? value,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SnapshotMetaTable extends SnapshotMeta
    with TableInfo<$SnapshotMetaTable, SnapshotMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnapshotMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    kind,
    sha256,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snapshot_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnapshotMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SnapshotMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnapshotMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $SnapshotMetaTable createAlias(String alias) {
    return $SnapshotMetaTable(attachedDatabase, alias);
  }
}

class SnapshotMetaData extends DataClass
    implements Insertable<SnapshotMetaData> {
  /// 实体 ID。
  final String id;

  /// 快照文件路径。
  final String path;

  /// 快照类型。
  final String kind;

  /// 快照内容哈希。
  final String sha256;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const SnapshotMetaData({
    required this.id,
    required this.path,
    required this.kind,
    required this.sha256,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['path'] = Variable<String>(path);
    map['kind'] = Variable<String>(kind);
    map['sha256'] = Variable<String>(sha256);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  SnapshotMetaCompanion toCompanion(bool nullToAbsent) {
    return SnapshotMetaCompanion(
      id: Value(id),
      path: Value(path),
      kind: Value(kind),
      sha256: Value(sha256),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory SnapshotMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnapshotMetaData(
      id: serializer.fromJson<String>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      kind: serializer.fromJson<String>(json['kind']),
      sha256: serializer.fromJson<String>(json['sha256']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'path': serializer.toJson<String>(path),
      'kind': serializer.toJson<String>(kind),
      'sha256': serializer.toJson<String>(sha256),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  SnapshotMetaData copyWith({
    String? id,
    String? path,
    String? kind,
    String? sha256,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => SnapshotMetaData(
    id: id ?? this.id,
    path: path ?? this.path,
    kind: kind ?? this.kind,
    sha256: sha256 ?? this.sha256,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  SnapshotMetaData copyWithCompanion(SnapshotMetaCompanion data) {
    return SnapshotMetaData(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      kind: data.kind.present ? data.kind.value : this.kind,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotMetaData(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('kind: $kind, ')
          ..write('sha256: $sha256, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    path,
    kind,
    sha256,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotMetaData &&
          other.id == this.id &&
          other.path == this.path &&
          other.kind == this.kind &&
          other.sha256 == this.sha256 &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class SnapshotMetaCompanion extends UpdateCompanion<SnapshotMetaData> {
  final Value<String> id;
  final Value<String> path;
  final Value<String> kind;
  final Value<String> sha256;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const SnapshotMetaCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.kind = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnapshotMetaCompanion.insert({
    required String id,
    required String path,
    required String kind,
    required String sha256,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       path = Value(path),
       kind = Value(kind),
       sha256 = Value(sha256),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<SnapshotMetaData> custom({
    Expression<String>? id,
    Expression<String>? path,
    Expression<String>? kind,
    Expression<String>? sha256,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (kind != null) 'kind': kind,
      if (sha256 != null) 'sha256': sha256,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnapshotMetaCompanion copyWith({
    Value<String>? id,
    Value<String>? path,
    Value<String>? kind,
    Value<String>? sha256,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return SnapshotMetaCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      kind: kind ?? this.kind,
      sha256: sha256 ?? this.sha256,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotMetaCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('kind: $kind, ')
          ..write('sha256: $sha256, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringTaskTable extends RecurringTask
    with TableInfo<$RecurringTaskTable, RecurringTaskData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringTaskTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _weekdayMaskMeta = const VerificationMeta(
    'weekdayMask',
  );
  @override
  late final GeneratedColumn<int> weekdayMask = GeneratedColumn<int>(
    'weekday_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinuteMeta = const VerificationMeta(
    'startMinute',
  );
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<int> active = GeneratedColumn<int>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    note,
    weekdayMask,
    startMinute,
    durationMinutes,
    active,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_task';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringTaskData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('weekday_mask')) {
      context.handle(
        _weekdayMaskMeta,
        weekdayMask.isAcceptableOrUnknown(
          data['weekday_mask']!,
          _weekdayMaskMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weekdayMaskMeta);
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(
          data['start_minute']!,
          _startMinuteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinuteMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringTaskData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringTaskData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      weekdayMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday_mask'],
      )!,
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $RecurringTaskTable createAlias(String alias) {
    return $RecurringTaskTable(attachedDatabase, alias);
  }
}

class RecurringTaskData extends DataClass
    implements Insertable<RecurringTaskData> {
  /// 实体 ID。
  final String id;

  /// 标题（物化时作为 `plan_item.title` 的初值）。
  final String title;

  /// 备注。
  final String note;

  /// 星期掩码：bit0 = 周一 … bit6 = 周日（0..127）。
  final int weekdayMask;

  /// 起始时刻（一天中的第几分钟，0..1439）。
  final int startMinute;

  /// 时长（分钟）。
  final int durationMinutes;

  /// 是否启用（0/1）；停用只影响**后续**物化，已生成的实例保留。
  final int active;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const RecurringTaskData({
    required this.id,
    required this.title,
    required this.note,
    required this.weekdayMask,
    required this.startMinute,
    required this.durationMinutes,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['note'] = Variable<String>(note);
    map['weekday_mask'] = Variable<int>(weekdayMask);
    map['start_minute'] = Variable<int>(startMinute);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['active'] = Variable<int>(active);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  RecurringTaskCompanion toCompanion(bool nullToAbsent) {
    return RecurringTaskCompanion(
      id: Value(id),
      title: Value(title),
      note: Value(note),
      weekdayMask: Value(weekdayMask),
      startMinute: Value(startMinute),
      durationMinutes: Value(durationMinutes),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory RecurringTaskData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringTaskData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String>(json['note']),
      weekdayMask: serializer.fromJson<int>(json['weekdayMask']),
      startMinute: serializer.fromJson<int>(json['startMinute']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      active: serializer.fromJson<int>(json['active']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String>(note),
      'weekdayMask': serializer.toJson<int>(weekdayMask),
      'startMinute': serializer.toJson<int>(startMinute),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'active': serializer.toJson<int>(active),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  RecurringTaskData copyWith({
    String? id,
    String? title,
    String? note,
    int? weekdayMask,
    int? startMinute,
    int? durationMinutes,
    int? active,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => RecurringTaskData(
    id: id ?? this.id,
    title: title ?? this.title,
    note: note ?? this.note,
    weekdayMask: weekdayMask ?? this.weekdayMask,
    startMinute: startMinute ?? this.startMinute,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  RecurringTaskData copyWithCompanion(RecurringTaskCompanion data) {
    return RecurringTaskData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      weekdayMask: data.weekdayMask.present
          ? data.weekdayMask.value
          : this.weekdayMask,
      startMinute: data.startMinute.present
          ? data.startMinute.value
          : this.startMinute,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTaskData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('weekdayMask: $weekdayMask, ')
          ..write('startMinute: $startMinute, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    note,
    weekdayMask,
    startMinute,
    durationMinutes,
    active,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringTaskData &&
          other.id == this.id &&
          other.title == this.title &&
          other.note == this.note &&
          other.weekdayMask == this.weekdayMask &&
          other.startMinute == this.startMinute &&
          other.durationMinutes == this.durationMinutes &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class RecurringTaskCompanion extends UpdateCompanion<RecurringTaskData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> note;
  final Value<int> weekdayMask;
  final Value<int> startMinute;
  final Value<int> durationMinutes;
  final Value<int> active;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const RecurringTaskCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.weekdayMask = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringTaskCompanion.insert({
    required String id,
    required String title,
    this.note = const Value.absent(),
    required int weekdayMask,
    required int startMinute,
    this.durationMinutes = const Value.absent(),
    this.active = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       weekdayMask = Value(weekdayMask),
       startMinute = Value(startMinute),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<RecurringTaskData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? note,
    Expression<int>? weekdayMask,
    Expression<int>? startMinute,
    Expression<int>? durationMinutes,
    Expression<int>? active,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (weekdayMask != null) 'weekday_mask': weekdayMask,
      if (startMinute != null) 'start_minute': startMinute,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringTaskCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? note,
    Value<int>? weekdayMask,
    Value<int>? startMinute,
    Value<int>? durationMinutes,
    Value<int>? active,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return RecurringTaskCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      weekdayMask: weekdayMask ?? this.weekdayMask,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (weekdayMask.present) {
      map['weekday_mask'] = Variable<int>(weekdayMask.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (active.present) {
      map['active'] = Variable<int>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTaskCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('weekdayMask: $weekdayMask, ')
          ..write('startMinute: $startMinute, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringOccurrenceTable extends RecurringOccurrence
    with TableInfo<$RecurringOccurrenceTable, RecurringOccurrenceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringOccurrenceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recurring_task (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planItemIdMeta = const VerificationMeta(
    'planItemId',
  );
  @override
  late final GeneratedColumn<String> planItemId = GeneratedColumn<String>(
    'plan_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plan_item (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    date,
    planItemId,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_occurrence';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringOccurrenceData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('plan_item_id')) {
      context.handle(
        _planItemIdMeta,
        planItemId.isAcceptableOrUnknown(
          data['plan_item_id']!,
          _planItemIdMeta,
        ),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringOccurrenceData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringOccurrenceData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      planItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_item_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
    );
  }

  @override
  $RecurringOccurrenceTable createAlias(String alias) {
    return $RecurringOccurrenceTable(attachedDatabase, alias);
  }
}

class RecurringOccurrenceData extends DataClass
    implements Insertable<RecurringOccurrenceData> {
  /// 实体 ID。
  final String id;

  /// 所属循环任务。
  final String taskId;

  /// 日历日 `YYYY-MM-DD`。
  final String date;

  /// 生成出来的计划条目；该行被物理删除时置空（**不**影响幂等性）。
  final String? planItemId;

  /// 创建时刻（Unix 毫秒）。
  final int createdAt;

  /// 最后更新时刻（Unix 毫秒）。
  final int updatedAt;

  /// 删除时刻（Unix 毫秒）；非空 = 墓碑。
  final int? deletedAt;

  /// 最后写入本行的设备 ID。
  final String originDeviceId;

  /// 本地修订号。
  final int rev;
  const RecurringOccurrenceData({
    required this.id,
    required this.taskId,
    required this.date,
    this.planItemId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.originDeviceId,
    required this.rev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || planItemId != null) {
      map['plan_item_id'] = Variable<String>(planItemId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['rev'] = Variable<int>(rev);
    return map;
  }

  RecurringOccurrenceCompanion toCompanion(bool nullToAbsent) {
    return RecurringOccurrenceCompanion(
      id: Value(id),
      taskId: Value(taskId),
      date: Value(date),
      planItemId: planItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(planItemId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      rev: Value(rev),
    );
  }

  factory RecurringOccurrenceData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringOccurrenceData(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      date: serializer.fromJson<String>(json['date']),
      planItemId: serializer.fromJson<String?>(json['planItemId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      rev: serializer.fromJson<int>(json['rev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'date': serializer.toJson<String>(date),
      'planItemId': serializer.toJson<String?>(planItemId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'rev': serializer.toJson<int>(rev),
    };
  }

  RecurringOccurrenceData copyWith({
    String? id,
    String? taskId,
    String? date,
    Value<String?> planItemId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? originDeviceId,
    int? rev,
  }) => RecurringOccurrenceData(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    date: date ?? this.date,
    planItemId: planItemId.present ? planItemId.value : this.planItemId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    rev: rev ?? this.rev,
  );
  RecurringOccurrenceData copyWithCompanion(RecurringOccurrenceCompanion data) {
    return RecurringOccurrenceData(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      date: data.date.present ? data.date.value : this.date,
      planItemId: data.planItemId.present
          ? data.planItemId.value
          : this.planItemId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      rev: data.rev.present ? data.rev.value : this.rev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringOccurrenceData(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('date: $date, ')
          ..write('planItemId: $planItemId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    date,
    planItemId,
    createdAt,
    updatedAt,
    deletedAt,
    originDeviceId,
    rev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringOccurrenceData &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.date == this.date &&
          other.planItemId == this.planItemId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.rev == this.rev);
}

class RecurringOccurrenceCompanion
    extends UpdateCompanion<RecurringOccurrenceData> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> date;
  final Value<String?> planItemId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> originDeviceId;
  final Value<int> rev;
  final Value<int> rowid;
  const RecurringOccurrenceCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.date = const Value.absent(),
    this.planItemId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringOccurrenceCompanion.insert({
    required String id,
    required String taskId,
    required String date,
    this.planItemId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    this.rev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       originDeviceId = Value(originDeviceId);
  static Insertable<RecurringOccurrenceData> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? date,
    Expression<String>? planItemId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (date != null) 'date': date,
      if (planItemId != null) 'plan_item_id': planItemId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rev != null) 'rev': rev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringOccurrenceCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? date,
    Value<String?>? planItemId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? originDeviceId,
    Value<int>? rev,
    Value<int>? rowid,
  }) {
    return RecurringOccurrenceCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      date: date ?? this.date,
      planItemId: planItemId ?? this.planItemId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rev: rev ?? this.rev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (planItemId.present) {
      map['plan_item_id'] = Variable<String>(planItemId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringOccurrenceCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('date: $date, ')
          ..write('planItemId: $planItemId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rev: $rev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ActLogDatabase extends GeneratedDatabase {
  _$ActLogDatabase(QueryExecutor e) : super(e);
  $ActLogDatabaseManager get managers => $ActLogDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $DayLogTable dayLog = $DayLogTable(this);
  late final $ProjectTable project = $ProjectTable(this);
  late final $TodoTable todo = $TodoTable(this);
  late final $PlanItemTable planItem = $PlanItemTable(this);
  late final $HabitTable habit = $HabitTable(this);
  late final $HabitCheckinTable habitCheckin = $HabitCheckinTable(this);
  late final $HabitScoreTable habitScore = $HabitScoreTable(this);
  late final $ProjectMilestoneTable projectMilestone = $ProjectMilestoneTable(
    this,
  );
  late final $ProjectIncrementTable projectIncrement = $ProjectIncrementTable(
    this,
  );
  late final $ReminderTable reminder = $ReminderTable(this);
  late final $OplogTable oplog = $OplogTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $SnapshotMetaTable snapshotMeta = $SnapshotMetaTable(this);
  late final $RecurringTaskTable recurringTask = $RecurringTaskTable(this);
  late final $RecurringOccurrenceTable recurringOccurrence =
      $RecurringOccurrenceTable(this);
  late final Index idxSettingsUpdatedAt = Index(
    'idx_settings_updated_at',
    'CREATE INDEX idx_settings_updated_at ON settings (updated_at)',
  );
  late final Index idxDayLogUpdatedAt = Index(
    'idx_day_log_updated_at',
    'CREATE INDEX idx_day_log_updated_at ON day_log (updated_at)',
  );
  late final Index idxPlanItemDate = Index(
    'idx_plan_item_date',
    'CREATE INDEX idx_plan_item_date ON plan_item (date)',
  );
  late final Index idxPlanItemDateStatus = Index(
    'idx_plan_item_date_status',
    'CREATE INDEX idx_plan_item_date_status ON plan_item (date, status)',
  );
  late final Index idxPlanItemSourceTodo = Index(
    'idx_plan_item_source_todo',
    'CREATE INDEX idx_plan_item_source_todo ON plan_item (source_todo_id)',
  );
  late final Index idxPlanItemSource = Index(
    'idx_plan_item_source',
    'CREATE INDEX idx_plan_item_source ON plan_item (source_type, source_id)',
  );
  late final Index idxPlanItemUpdatedAt = Index(
    'idx_plan_item_updated_at',
    'CREATE INDEX idx_plan_item_updated_at ON plan_item (updated_at)',
  );
  late final Index idxTodoStatus = Index(
    'idx_todo_status',
    'CREATE INDEX idx_todo_status ON todo (status)',
  );
  late final Index idxTodoDueDate = Index(
    'idx_todo_due_date',
    'CREATE INDEX idx_todo_due_date ON todo (due_date)',
  );
  late final Index idxTodoProject = Index(
    'idx_todo_project',
    'CREATE INDEX idx_todo_project ON todo (project_id)',
  );
  late final Index idxTodoUpdatedAt = Index(
    'idx_todo_updated_at',
    'CREATE INDEX idx_todo_updated_at ON todo (updated_at)',
  );
  late final Index idxHabitArchived = Index(
    'idx_habit_archived',
    'CREATE INDEX idx_habit_archived ON habit (archived)',
  );
  late final Index idxHabitUpdatedAt = Index(
    'idx_habit_updated_at',
    'CREATE INDEX idx_habit_updated_at ON habit (updated_at)',
  );
  late final Index idxHabitCheckinDate = Index(
    'idx_habit_checkin_date',
    'CREATE INDEX idx_habit_checkin_date ON habit_checkin (date)',
  );
  late final Index idxHabitCheckinUpdatedAt = Index(
    'idx_habit_checkin_updated_at',
    'CREATE INDEX idx_habit_checkin_updated_at ON habit_checkin (updated_at)',
  );
  late final Index idxHabitScoreHabitDate = Index(
    'idx_habit_score_habit_date',
    'CREATE INDEX idx_habit_score_habit_date ON habit_score (habit_id, date)',
  );
  late final Index idxProjectStatus = Index(
    'idx_project_status',
    'CREATE INDEX idx_project_status ON project (status)',
  );
  late final Index idxProjectUpdatedAt = Index(
    'idx_project_updated_at',
    'CREATE INDEX idx_project_updated_at ON project (updated_at)',
  );
  late final Index idxProjectMilestoneProject = Index(
    'idx_project_milestone_project',
    'CREATE INDEX idx_project_milestone_project ON project_milestone (project_id)',
  );
  late final Index idxProjectMilestoneTargetDate = Index(
    'idx_project_milestone_target_date',
    'CREATE INDEX idx_project_milestone_target_date ON project_milestone (target_date)',
  );
  late final Index idxProjectIncrementProjectDate = Index(
    'idx_project_increment_project_date',
    'CREATE INDEX idx_project_increment_project_date ON project_increment (project_id, date)',
  );
  late final Index idxProjectIncrementDate = Index(
    'idx_project_increment_date',
    'CREATE INDEX idx_project_increment_date ON project_increment (date)',
  );
  late final Index idxReminderTarget = Index(
    'idx_reminder_target',
    'CREATE INDEX idx_reminder_target ON reminder (target_type, target_id)',
  );
  late final Index idxReminderRemindAt = Index(
    'idx_reminder_remind_at',
    'CREATE INDEX idx_reminder_remind_at ON reminder (remind_at)',
  );
  late final Index idxReminderEnabled = Index(
    'idx_reminder_enabled',
    'CREATE INDEX idx_reminder_enabled ON reminder (enabled, remind_at)',
  );
  late final Index idxOplogEntity = Index(
    'idx_oplog_entity',
    'CREATE INDEX idx_oplog_entity ON oplog (entity_table, entity_id)',
  );
  late final Index idxOplogSynced = Index(
    'idx_oplog_synced',
    'CREATE INDEX idx_oplog_synced ON oplog (synced, id)',
  );
  late final Index idxOplogLamport = Index(
    'idx_oplog_lamport',
    'CREATE INDEX idx_oplog_lamport ON oplog (lamport)',
  );
  late final Index idxOplogDevice = Index(
    'idx_oplog_device',
    'CREATE INDEX idx_oplog_device ON oplog (device_id)',
  );
  late final Index idxSnapshotMetaKind = Index(
    'idx_snapshot_meta_kind',
    'CREATE INDEX idx_snapshot_meta_kind ON snapshot_meta (kind)',
  );
  late final Index idxRecurringTaskActive = Index(
    'idx_recurring_task_active',
    'CREATE INDEX idx_recurring_task_active ON recurring_task (active)',
  );
  late final Index idxRecurringTaskUpdatedAt = Index(
    'idx_recurring_task_updated_at',
    'CREATE INDEX idx_recurring_task_updated_at ON recurring_task (updated_at)',
  );
  late final Index idxRecurringOccurrenceDate = Index(
    'idx_recurring_occurrence_date',
    'CREATE INDEX idx_recurring_occurrence_date ON recurring_occurrence (date)',
  );
  late final Index idxRecurringOccurrenceUpdatedAt = Index(
    'idx_recurring_occurrence_updated_at',
    'CREATE INDEX idx_recurring_occurrence_updated_at ON recurring_occurrence (updated_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    dayLog,
    project,
    todo,
    planItem,
    habit,
    habitCheckin,
    habitScore,
    projectMilestone,
    projectIncrement,
    reminder,
    oplog,
    syncState,
    snapshotMeta,
    recurringTask,
    recurringOccurrence,
    idxSettingsUpdatedAt,
    idxDayLogUpdatedAt,
    idxPlanItemDate,
    idxPlanItemDateStatus,
    idxPlanItemSourceTodo,
    idxPlanItemSource,
    idxPlanItemUpdatedAt,
    idxTodoStatus,
    idxTodoDueDate,
    idxTodoProject,
    idxTodoUpdatedAt,
    idxHabitArchived,
    idxHabitUpdatedAt,
    idxHabitCheckinDate,
    idxHabitCheckinUpdatedAt,
    idxHabitScoreHabitDate,
    idxProjectStatus,
    idxProjectUpdatedAt,
    idxProjectMilestoneProject,
    idxProjectMilestoneTargetDate,
    idxProjectIncrementProjectDate,
    idxProjectIncrementDate,
    idxReminderTarget,
    idxReminderRemindAt,
    idxReminderEnabled,
    idxOplogEntity,
    idxOplogSynced,
    idxOplogLamport,
    idxOplogDevice,
    idxSnapshotMetaKind,
    idxRecurringTaskActive,
    idxRecurringTaskUpdatedAt,
    idxRecurringOccurrenceDate,
    idxRecurringOccurrenceUpdatedAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'project',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('todo', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'todo',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('plan_item', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habit',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habit_checkin', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habit',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habit_score', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'project',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('project_milestone', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'project',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('project_increment', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plan_item',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('project_increment', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recurring_task',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recurring_occurrence', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plan_item',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recurring_occurrence', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String id,
  required String key,
  Value<String> value,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> id,
  Value<String> key,
  Value<String> value,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$ActLogDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$ActLogDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$ActLogDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$ActLogDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                key: key,
                value: value,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String key,
                Value<String> value = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                key: key,
                value: value,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$ActLogDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$ActLogDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$DayLogTableCreateCompanionBuilder = DayLogCompanion Function({
  required String id,
  required String date,
  Value<String> mode,
  Value<String> learning,
  Value<String> good,
  Value<String> improve,
  Value<String> controllable,
  Value<String> uncontrollable,
  Value<String> nextAction,
  Value<String> moodNote,
  Value<int?> mood1,
  Value<int?> mood2,
  Value<int?> mood3,
  Value<int?> mood4,
  Value<int?> mood5,
  Value<int?> mood6,
  Value<int?> mood7,
  Value<int?> mood8,
  Value<int> moodFailed,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});
typedef $$DayLogTableUpdateCompanionBuilder = DayLogCompanion Function({
  Value<String> id,
  Value<String> date,
  Value<String> mode,
  Value<String> learning,
  Value<String> good,
  Value<String> improve,
  Value<String> controllable,
  Value<String> uncontrollable,
  Value<String> nextAction,
  Value<String> moodNote,
  Value<int?> mood1,
  Value<int?> mood2,
  Value<int?> mood3,
  Value<int?> mood4,
  Value<int?> mood5,
  Value<int?> mood6,
  Value<int?> mood7,
  Value<int?> mood8,
  Value<int> moodFailed,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});

class $$DayLogTableFilterComposer
    extends Composer<_$ActLogDatabase, $DayLogTable> {
  $$DayLogTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get learning => $composableBuilder(
    column: $table.learning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get good => $composableBuilder(
    column: $table.good,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get improve => $composableBuilder(
    column: $table.improve,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get controllable => $composableBuilder(
    column: $table.controllable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uncontrollable => $composableBuilder(
    column: $table.uncontrollable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextAction => $composableBuilder(
    column: $table.nextAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moodNote => $composableBuilder(
    column: $table.moodNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood1 => $composableBuilder(
    column: $table.mood1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood2 => $composableBuilder(
    column: $table.mood2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood3 => $composableBuilder(
    column: $table.mood3,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood4 => $composableBuilder(
    column: $table.mood4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood5 => $composableBuilder(
    column: $table.mood5,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood6 => $composableBuilder(
    column: $table.mood6,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood7 => $composableBuilder(
    column: $table.mood7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood8 => $composableBuilder(
    column: $table.mood8,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get moodFailed => $composableBuilder(
    column: $table.moodFailed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayLogTableOrderingComposer
    extends Composer<_$ActLogDatabase, $DayLogTable> {
  $$DayLogTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get learning => $composableBuilder(
    column: $table.learning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get good => $composableBuilder(
    column: $table.good,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get improve => $composableBuilder(
    column: $table.improve,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get controllable => $composableBuilder(
    column: $table.controllable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uncontrollable => $composableBuilder(
    column: $table.uncontrollable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextAction => $composableBuilder(
    column: $table.nextAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moodNote => $composableBuilder(
    column: $table.moodNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood1 => $composableBuilder(
    column: $table.mood1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood2 => $composableBuilder(
    column: $table.mood2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood3 => $composableBuilder(
    column: $table.mood3,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood4 => $composableBuilder(
    column: $table.mood4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood5 => $composableBuilder(
    column: $table.mood5,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood6 => $composableBuilder(
    column: $table.mood6,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood7 => $composableBuilder(
    column: $table.mood7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood8 => $composableBuilder(
    column: $table.mood8,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get moodFailed => $composableBuilder(
    column: $table.moodFailed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayLogTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $DayLogTable> {
  $$DayLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get learning =>
      $composableBuilder(column: $table.learning, builder: (column) => column);

  GeneratedColumn<String> get good =>
      $composableBuilder(column: $table.good, builder: (column) => column);

  GeneratedColumn<String> get improve =>
      $composableBuilder(column: $table.improve, builder: (column) => column);

  GeneratedColumn<String> get controllable => $composableBuilder(
    column: $table.controllable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uncontrollable => $composableBuilder(
    column: $table.uncontrollable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextAction => $composableBuilder(
    column: $table.nextAction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get moodNote =>
      $composableBuilder(column: $table.moodNote, builder: (column) => column);

  GeneratedColumn<int> get mood1 =>
      $composableBuilder(column: $table.mood1, builder: (column) => column);

  GeneratedColumn<int> get mood2 =>
      $composableBuilder(column: $table.mood2, builder: (column) => column);

  GeneratedColumn<int> get mood3 =>
      $composableBuilder(column: $table.mood3, builder: (column) => column);

  GeneratedColumn<int> get mood4 =>
      $composableBuilder(column: $table.mood4, builder: (column) => column);

  GeneratedColumn<int> get mood5 =>
      $composableBuilder(column: $table.mood5, builder: (column) => column);

  GeneratedColumn<int> get mood6 =>
      $composableBuilder(column: $table.mood6, builder: (column) => column);

  GeneratedColumn<int> get mood7 =>
      $composableBuilder(column: $table.mood7, builder: (column) => column);

  GeneratedColumn<int> get mood8 =>
      $composableBuilder(column: $table.mood8, builder: (column) => column);

  GeneratedColumn<int> get moodFailed => $composableBuilder(
    column: $table.moodFailed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);
}

class $$DayLogTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $DayLogTable,
          DayLogData,
          $$DayLogTableFilterComposer,
          $$DayLogTableOrderingComposer,
          $$DayLogTableAnnotationComposer,
          $$DayLogTableCreateCompanionBuilder,
          $$DayLogTableUpdateCompanionBuilder,
          (
            DayLogData,
            BaseReferences<_$ActLogDatabase, $DayLogTable, DayLogData>,
          ),
          DayLogData,
          PrefetchHooks Function()
        > {
  $$DayLogTableTableManager(_$ActLogDatabase db, $DayLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> learning = const Value.absent(),
                Value<String> good = const Value.absent(),
                Value<String> improve = const Value.absent(),
                Value<String> controllable = const Value.absent(),
                Value<String> uncontrollable = const Value.absent(),
                Value<String> nextAction = const Value.absent(),
                Value<String> moodNote = const Value.absent(),
                Value<int?> mood1 = const Value.absent(),
                Value<int?> mood2 = const Value.absent(),
                Value<int?> mood3 = const Value.absent(),
                Value<int?> mood4 = const Value.absent(),
                Value<int?> mood5 = const Value.absent(),
                Value<int?> mood6 = const Value.absent(),
                Value<int?> mood7 = const Value.absent(),
                Value<int?> mood8 = const Value.absent(),
                Value<int> moodFailed = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayLogCompanion(
                id: id,
                date: date,
                mode: mode,
                learning: learning,
                good: good,
                improve: improve,
                controllable: controllable,
                uncontrollable: uncontrollable,
                nextAction: nextAction,
                moodNote: moodNote,
                mood1: mood1,
                mood2: mood2,
                mood3: mood3,
                mood4: mood4,
                mood5: mood5,
                mood6: mood6,
                mood7: mood7,
                mood8: mood8,
                moodFailed: moodFailed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                Value<String> mode = const Value.absent(),
                Value<String> learning = const Value.absent(),
                Value<String> good = const Value.absent(),
                Value<String> improve = const Value.absent(),
                Value<String> controllable = const Value.absent(),
                Value<String> uncontrollable = const Value.absent(),
                Value<String> nextAction = const Value.absent(),
                Value<String> moodNote = const Value.absent(),
                Value<int?> mood1 = const Value.absent(),
                Value<int?> mood2 = const Value.absent(),
                Value<int?> mood3 = const Value.absent(),
                Value<int?> mood4 = const Value.absent(),
                Value<int?> mood5 = const Value.absent(),
                Value<int?> mood6 = const Value.absent(),
                Value<int?> mood7 = const Value.absent(),
                Value<int?> mood8 = const Value.absent(),
                Value<int> moodFailed = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayLogCompanion.insert(
                id: id,
                date: date,
                mode: mode,
                learning: learning,
                good: good,
                improve: improve,
                controllable: controllable,
                uncontrollable: uncontrollable,
                nextAction: nextAction,
                moodNote: moodNote,
                mood1: mood1,
                mood2: mood2,
                mood3: mood3,
                mood4: mood4,
                mood5: mood5,
                mood6: mood6,
                mood7: mood7,
                mood8: mood8,
                moodFailed: moodFailed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DayLogTable, DayLogData>(table),
                  BaseReferences<_$ActLogDatabase, $DayLogTable, DayLogData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayLogTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $DayLogTable,
      DayLogData,
      $$DayLogTableFilterComposer,
      $$DayLogTableOrderingComposer,
      $$DayLogTableAnnotationComposer,
      $$DayLogTableCreateCompanionBuilder,
      $$DayLogTableUpdateCompanionBuilder,
      (DayLogData, BaseReferences<_$ActLogDatabase, $DayLogTable, DayLogData>),
      DayLogData,
      PrefetchHooks Function()
    >;
typedef $$ProjectTableCreateCompanionBuilder = ProjectCompanion Function({
  required String id,
  required String name,
  Value<String> goal,
  Value<String?> startDate,
  Value<String?> endDate,
  Value<String> domain,
  Value<String> status,
  Value<int> archived,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});
typedef $$ProjectTableUpdateCompanionBuilder = ProjectCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> goal,
  Value<String?> startDate,
  Value<String?> endDate,
  Value<String> domain,
  Value<String> status,
  Value<int> archived,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});

final class $$ProjectTableReferences
    extends BaseReferences<_$ActLogDatabase, $ProjectTable, ProjectData> {
  $$ProjectTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TodoTable, List<TodoData>> _todoRefsTable(
    _$ActLogDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.todo,
    aliasName: 'project__id__todo__project_id',
  );

  $$TodoTableProcessedTableManager get todoRefs {
    final manager = $$TodoTableTableManager(
      $_db,
      $_db.todo,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_todoRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProjectMilestoneTable, List<ProjectMilestoneData>>
  _projectMilestoneRefsTable(_$ActLogDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.projectMilestone,
        aliasName: 'project__id__project_milestone__project_id',
      );

  $$ProjectMilestoneTableProcessedTableManager get projectMilestoneRefs {
    final manager = $$ProjectMilestoneTableTableManager(
      $_db,
      $_db.projectMilestone,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _projectMilestoneRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProjectIncrementTable, List<ProjectIncrementData>>
  _projectIncrementRefsTable(_$ActLogDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.projectIncrement,
        aliasName: 'project__id__project_increment__project_id',
      );

  $$ProjectIncrementTableProcessedTableManager get projectIncrementRefs {
    final manager = $$ProjectIncrementTableTableManager(
      $_db,
      $_db.projectIncrement,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _projectIncrementRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectTableFilterComposer
    extends Composer<_$ActLogDatabase, $ProjectTable> {
  $$ProjectTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> todoRefs(
    Expression<bool> Function($$TodoTableFilterComposer f) f,
  ) {
    final $$TodoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.todo,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodoTableFilterComposer(
            $db: $db,
            $table: $db.todo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> projectMilestoneRefs(
    Expression<bool> Function($$ProjectMilestoneTableFilterComposer f) f,
  ) {
    final $$ProjectMilestoneTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectMilestone,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectMilestoneTableFilterComposer(
            $db: $db,
            $table: $db.projectMilestone,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> projectIncrementRefs(
    Expression<bool> Function($$ProjectIncrementTableFilterComposer f) f,
  ) {
    final $$ProjectIncrementTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectIncrement,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectIncrementTableFilterComposer(
            $db: $db,
            $table: $db.projectIncrement,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectTableOrderingComposer
    extends Composer<_$ActLogDatabase, $ProjectTable> {
  $$ProjectTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $ProjectTable> {
  $$ProjectTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  Expression<T> todoRefs<T extends Object>(
    Expression<T> Function($$TodoTableAnnotationComposer a) f,
  ) {
    final $$TodoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.todo,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodoTableAnnotationComposer(
            $db: $db,
            $table: $db.todo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> projectMilestoneRefs<T extends Object>(
    Expression<T> Function($$ProjectMilestoneTableAnnotationComposer a) f,
  ) {
    final $$ProjectMilestoneTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectMilestone,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectMilestoneTableAnnotationComposer(
            $db: $db,
            $table: $db.projectMilestone,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> projectIncrementRefs<T extends Object>(
    Expression<T> Function($$ProjectIncrementTableAnnotationComposer a) f,
  ) {
    final $$ProjectIncrementTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectIncrement,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectIncrementTableAnnotationComposer(
            $db: $db,
            $table: $db.projectIncrement,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $ProjectTable,
          ProjectData,
          $$ProjectTableFilterComposer,
          $$ProjectTableOrderingComposer,
          $$ProjectTableAnnotationComposer,
          $$ProjectTableCreateCompanionBuilder,
          $$ProjectTableUpdateCompanionBuilder,
          (ProjectData, $$ProjectTableReferences),
          ProjectData,
          PrefetchHooks Function({
            bool todoRefs,
            bool projectMilestoneRefs,
            bool projectIncrementRefs,
          })
        > {
  $$ProjectTableTableManager(_$ActLogDatabase db, $ProjectTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> goal = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> archived = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectCompanion(
                id: id,
                name: name,
                goal: goal,
                startDate: startDate,
                endDate: endDate,
                domain: domain,
                status: status,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> goal = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> archived = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectCompanion.insert(
                id: id,
                name: name,
                goal: goal,
                startDate: startDate,
                endDate: endDate,
                domain: domain,
                status: status,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectTable, ProjectData>(table),
                  $$ProjectTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                todoRefs = false,
                projectMilestoneRefs = false,
                projectIncrementRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (todoRefs) db.todo,
                    if (projectMilestoneRefs) db.projectMilestone,
                    if (projectIncrementRefs) db.projectIncrement,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (todoRefs)
                        await $_getPrefetchedDataByColumns<
                          ProjectData,
                          $ProjectTable,
                          TodoData,
                          $TodoTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectTableReferences
                              ._todoRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectTableReferences(db, table, p0).todoRefs,
                          currentColumn: 'id',
                          referencedColumn: 'project_id',
                          typedResults: items,
                        ),
                      if (projectMilestoneRefs)
                        await $_getPrefetchedDataByColumns<
                          ProjectData,
                          $ProjectTable,
                          ProjectMilestoneData,
                          $ProjectMilestoneTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectTableReferences
                              ._projectMilestoneRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectTableReferences(
                                db,
                                table,
                                p0,
                              ).projectMilestoneRefs,
                          currentColumn: 'id',
                          referencedColumn: 'project_id',
                          typedResults: items,
                        ),
                      if (projectIncrementRefs)
                        await $_getPrefetchedDataByColumns<
                          ProjectData,
                          $ProjectTable,
                          ProjectIncrementData,
                          $ProjectIncrementTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectTableReferences
                              ._projectIncrementRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectTableReferences(
                                db,
                                table,
                                p0,
                              ).projectIncrementRefs,
                          currentColumn: 'id',
                          referencedColumn: 'project_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProjectTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $ProjectTable,
      ProjectData,
      $$ProjectTableFilterComposer,
      $$ProjectTableOrderingComposer,
      $$ProjectTableAnnotationComposer,
      $$ProjectTableCreateCompanionBuilder,
      $$ProjectTableUpdateCompanionBuilder,
      (ProjectData, $$ProjectTableReferences),
      ProjectData,
      PrefetchHooks Function({
        bool todoRefs,
        bool projectMilestoneRefs,
        bool projectIncrementRefs,
      })
    >;
typedef $$TodoTableCreateCompanionBuilder = TodoCompanion Function({
  required String id,
  required String title,
  Value<String> detail,
  Value<int?> estMinutes,
  Value<String?> dueDate,
  Value<String?> projectId,
  Value<String?> quadrant,
  Value<String?> priorityAbc,
  Value<String> status,
  Value<int?> completedAt,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});
typedef $$TodoTableUpdateCompanionBuilder = TodoCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> detail,
  Value<int?> estMinutes,
  Value<String?> dueDate,
  Value<String?> projectId,
  Value<String?> quadrant,
  Value<String?> priorityAbc,
  Value<String> status,
  Value<int?> completedAt,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});

final class $$TodoTableReferences
    extends BaseReferences<_$ActLogDatabase, $TodoTable, TodoData> {
  $$TodoTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectTable _projectIdTable(_$ActLogDatabase db) =>
      db.project.createAlias('todo__project_id__project__id');

  $$ProjectTableProcessedTableManager? get projectId {
    final $_column = $_itemColumn<String>('project_id');
    if ($_column == null) return null;
    final manager = $$ProjectTableTableManager(
      $_db,
      $_db.project,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlanItemTable, List<PlanItemData>>
  _planItemRefsTable(_$ActLogDatabase db) => MultiTypedResultKey.fromTable(
    db.planItem,
    aliasName: 'todo__id__plan_item__source_todo_id',
  );

  $$PlanItemTableProcessedTableManager get planItemRefs {
    final manager = $$PlanItemTableTableManager(
      $_db,
      $_db.planItem,
    ).filter((f) => f.sourceTodoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_planItemRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TodoTableFilterComposer extends Composer<_$ActLogDatabase, $TodoTable> {
  $$TodoTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quadrant => $composableBuilder(
    column: $table.quadrant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priorityAbc => $composableBuilder(
    column: $table.priorityAbc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectTableFilterComposer get projectId {
    final $$ProjectTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.project,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectTableFilterComposer(
            $db: $db,
            $table: $db.project,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> planItemRefs(
    Expression<bool> Function($$PlanItemTableFilterComposer f) f,
  ) {
    final $$PlanItemTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planItem,
      getReferencedColumn: (t) => t.sourceTodoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemTableFilterComposer(
            $db: $db,
            $table: $db.planItem,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TodoTableOrderingComposer
    extends Composer<_$ActLogDatabase, $TodoTable> {
  $$TodoTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quadrant => $composableBuilder(
    column: $table.quadrant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priorityAbc => $composableBuilder(
    column: $table.priorityAbc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectTableOrderingComposer get projectId {
    final $$ProjectTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.project,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectTableOrderingComposer(
            $db: $db,
            $table: $db.project,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TodoTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $TodoTable> {
  $$TodoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get quadrant =>
      $composableBuilder(column: $table.quadrant, builder: (column) => column);

  GeneratedColumn<String> get priorityAbc => $composableBuilder(
    column: $table.priorityAbc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  $$ProjectTableAnnotationComposer get projectId {
    final $$ProjectTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.project,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectTableAnnotationComposer(
            $db: $db,
            $table: $db.project,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> planItemRefs<T extends Object>(
    Expression<T> Function($$PlanItemTableAnnotationComposer a) f,
  ) {
    final $$PlanItemTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planItem,
      getReferencedColumn: (t) => t.sourceTodoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemTableAnnotationComposer(
            $db: $db,
            $table: $db.planItem,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TodoTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $TodoTable,
          TodoData,
          $$TodoTableFilterComposer,
          $$TodoTableOrderingComposer,
          $$TodoTableAnnotationComposer,
          $$TodoTableCreateCompanionBuilder,
          $$TodoTableUpdateCompanionBuilder,
          (TodoData, $$TodoTableReferences),
          TodoData,
          PrefetchHooks Function({bool projectId, bool planItemRefs})
        > {
  $$TodoTableTableManager(_$ActLogDatabase db, $TodoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> detail = const Value.absent(),
                Value<int?> estMinutes = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> quadrant = const Value.absent(),
                Value<String?> priorityAbc = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TodoCompanion(
                id: id,
                title: title,
                detail: detail,
                estMinutes: estMinutes,
                dueDate: dueDate,
                projectId: projectId,
                quadrant: quadrant,
                priorityAbc: priorityAbc,
                status: status,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> detail = const Value.absent(),
                Value<int?> estMinutes = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> quadrant = const Value.absent(),
                Value<String?> priorityAbc = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TodoCompanion.insert(
                id: id,
                title: title,
                detail: detail,
                estMinutes: estMinutes,
                dueDate: dueDate,
                projectId: projectId,
                quadrant: quadrant,
                priorityAbc: priorityAbc,
                status: status,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TodoTable, TodoData>(table),
                  $$TodoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false, planItemRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (planItemRefs) db.planItem],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$TodoTableReferences._projectIdTable(
                          db,
                        ),
                        referencedColumn: $$TodoTableReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (planItemRefs)
                    await $_getPrefetchedDataByColumns<
                      TodoData,
                      $TodoTable,
                      PlanItemData,
                      $PlanItemTable
                    >(
                      currentTable: table,
                      referencedTable: $$TodoTableReferences._planItemRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$TodoTableReferences(db, table, p0).planItemRefs,
                      currentColumn: 'id',
                      referencedColumn: 'source_todo_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TodoTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $TodoTable,
      TodoData,
      $$TodoTableFilterComposer,
      $$TodoTableOrderingComposer,
      $$TodoTableAnnotationComposer,
      $$TodoTableCreateCompanionBuilder,
      $$TodoTableUpdateCompanionBuilder,
      (TodoData, $$TodoTableReferences),
      TodoData,
      PrefetchHooks Function({bool projectId, bool planItemRefs})
    >;
typedef $$PlanItemTableCreateCompanionBuilder = PlanItemCompanion Function({
  required String id,
  required String date,
  required String title,
  Value<String> detail,
  Value<String> sourceType,
  Value<String?> sourceId,
  Value<String?> sourceTodoId,
  Value<String?> quadrant,
  Value<String?> priorityAbc,
  Value<String> domain,
  Value<int?> estMinutes,
  Value<int?> plannedStart,
  Value<int?> plannedEnd,
  Value<String> status,
  Value<int?> doneAt,
  Value<String> resultNote,
  Value<int> isHabitRef,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});
typedef $$PlanItemTableUpdateCompanionBuilder = PlanItemCompanion Function({
  Value<String> id,
  Value<String> date,
  Value<String> title,
  Value<String> detail,
  Value<String> sourceType,
  Value<String?> sourceId,
  Value<String?> sourceTodoId,
  Value<String?> quadrant,
  Value<String?> priorityAbc,
  Value<String> domain,
  Value<int?> estMinutes,
  Value<int?> plannedStart,
  Value<int?> plannedEnd,
  Value<String> status,
  Value<int?> doneAt,
  Value<String> resultNote,
  Value<int> isHabitRef,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});

final class $$PlanItemTableReferences
    extends BaseReferences<_$ActLogDatabase, $PlanItemTable, PlanItemData> {
  $$PlanItemTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TodoTable _sourceTodoIdTable(_$ActLogDatabase db) =>
      db.todo.createAlias('plan_item__source_todo_id__todo__id');

  $$TodoTableProcessedTableManager? get sourceTodoId {
    final $_column = $_itemColumn<String>('source_todo_id');
    if ($_column == null) return null;
    final manager = $$TodoTableTableManager(
      $_db,
      $_db.todo,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceTodoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProjectIncrementTable, List<ProjectIncrementData>>
  _projectIncrementRefsTable(_$ActLogDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.projectIncrement,
        aliasName: 'plan_item__id__project_increment__plan_item_id',
      );

  $$ProjectIncrementTableProcessedTableManager get projectIncrementRefs {
    final manager = $$ProjectIncrementTableTableManager(
      $_db,
      $_db.projectIncrement,
    ).filter((f) => f.planItemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _projectIncrementRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $RecurringOccurrenceTable,
    List<RecurringOccurrenceData>
  >
  _recurringOccurrenceRefsTable(_$ActLogDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recurringOccurrence,
        aliasName: 'plan_item__id__recurring_occurrence__plan_item_id',
      );

  $$RecurringOccurrenceTableProcessedTableManager get recurringOccurrenceRefs {
    final manager = $$RecurringOccurrenceTableTableManager(
      $_db,
      $_db.recurringOccurrence,
    ).filter((f) => f.planItemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recurringOccurrenceRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlanItemTableFilterComposer
    extends Composer<_$ActLogDatabase, $PlanItemTable> {
  $$PlanItemTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quadrant => $composableBuilder(
    column: $table.quadrant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priorityAbc => $composableBuilder(
    column: $table.priorityAbc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedStart => $composableBuilder(
    column: $table.plannedStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedEnd => $composableBuilder(
    column: $table.plannedEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultNote => $composableBuilder(
    column: $table.resultNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isHabitRef => $composableBuilder(
    column: $table.isHabitRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );

  $$TodoTableFilterComposer get sourceTodoId {
    final $$TodoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceTodoId,
      referencedTable: $db.todo,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodoTableFilterComposer(
            $db: $db,
            $table: $db.todo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> projectIncrementRefs(
    Expression<bool> Function($$ProjectIncrementTableFilterComposer f) f,
  ) {
    final $$ProjectIncrementTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectIncrement,
      getReferencedColumn: (t) => t.planItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectIncrementTableFilterComposer(
            $db: $db,
            $table: $db.projectIncrement,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recurringOccurrenceRefs(
    Expression<bool> Function($$RecurringOccurrenceTableFilterComposer f) f,
  ) {
    final $$RecurringOccurrenceTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurringOccurrence,
      getReferencedColumn: (t) => t.planItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringOccurrenceTableFilterComposer(
            $db: $db,
            $table: $db.recurringOccurrence,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlanItemTableOrderingComposer
    extends Composer<_$ActLogDatabase, $PlanItemTable> {
  $$PlanItemTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quadrant => $composableBuilder(
    column: $table.quadrant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priorityAbc => $composableBuilder(
    column: $table.priorityAbc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedStart => $composableBuilder(
    column: $table.plannedStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedEnd => $composableBuilder(
    column: $table.plannedEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultNote => $composableBuilder(
    column: $table.resultNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isHabitRef => $composableBuilder(
    column: $table.isHabitRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );

  $$TodoTableOrderingComposer get sourceTodoId {
    final $$TodoTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceTodoId,
      referencedTable: $db.todo,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodoTableOrderingComposer(
            $db: $db,
            $table: $db.todo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanItemTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $PlanItemTable> {
  $$PlanItemTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get quadrant =>
      $composableBuilder(column: $table.quadrant, builder: (column) => column);

  GeneratedColumn<String> get priorityAbc => $composableBuilder(
    column: $table.priorityAbc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plannedStart => $composableBuilder(
    column: $table.plannedStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plannedEnd => $composableBuilder(
    column: $table.plannedEnd,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  GeneratedColumn<String> get resultNote => $composableBuilder(
    column: $table.resultNote,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isHabitRef => $composableBuilder(
    column: $table.isHabitRef,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  $$TodoTableAnnotationComposer get sourceTodoId {
    final $$TodoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceTodoId,
      referencedTable: $db.todo,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodoTableAnnotationComposer(
            $db: $db,
            $table: $db.todo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> projectIncrementRefs<T extends Object>(
    Expression<T> Function($$ProjectIncrementTableAnnotationComposer a) f,
  ) {
    final $$ProjectIncrementTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectIncrement,
      getReferencedColumn: (t) => t.planItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectIncrementTableAnnotationComposer(
            $db: $db,
            $table: $db.projectIncrement,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recurringOccurrenceRefs<T extends Object>(
    Expression<T> Function($$RecurringOccurrenceTableAnnotationComposer a) f,
  ) {
    final $$RecurringOccurrenceTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recurringOccurrence,
          getReferencedColumn: (t) => t.planItemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecurringOccurrenceTableAnnotationComposer(
                $db: $db,
                $table: $db.recurringOccurrence,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlanItemTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $PlanItemTable,
          PlanItemData,
          $$PlanItemTableFilterComposer,
          $$PlanItemTableOrderingComposer,
          $$PlanItemTableAnnotationComposer,
          $$PlanItemTableCreateCompanionBuilder,
          $$PlanItemTableUpdateCompanionBuilder,
          (PlanItemData, $$PlanItemTableReferences),
          PlanItemData,
          PrefetchHooks Function({
            bool sourceTodoId,
            bool projectIncrementRefs,
            bool recurringOccurrenceRefs,
          })
        > {
  $$PlanItemTableTableManager(_$ActLogDatabase db, $PlanItemTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanItemTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanItemTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanItemTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> detail = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> sourceTodoId = const Value.absent(),
                Value<String?> quadrant = const Value.absent(),
                Value<String?> priorityAbc = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<int?> estMinutes = const Value.absent(),
                Value<int?> plannedStart = const Value.absent(),
                Value<int?> plannedEnd = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> doneAt = const Value.absent(),
                Value<String> resultNote = const Value.absent(),
                Value<int> isHabitRef = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanItemCompanion(
                id: id,
                date: date,
                title: title,
                detail: detail,
                sourceType: sourceType,
                sourceId: sourceId,
                sourceTodoId: sourceTodoId,
                quadrant: quadrant,
                priorityAbc: priorityAbc,
                domain: domain,
                estMinutes: estMinutes,
                plannedStart: plannedStart,
                plannedEnd: plannedEnd,
                status: status,
                doneAt: doneAt,
                resultNote: resultNote,
                isHabitRef: isHabitRef,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required String title,
                Value<String> detail = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> sourceTodoId = const Value.absent(),
                Value<String?> quadrant = const Value.absent(),
                Value<String?> priorityAbc = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<int?> estMinutes = const Value.absent(),
                Value<int?> plannedStart = const Value.absent(),
                Value<int?> plannedEnd = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> doneAt = const Value.absent(),
                Value<String> resultNote = const Value.absent(),
                Value<int> isHabitRef = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanItemCompanion.insert(
                id: id,
                date: date,
                title: title,
                detail: detail,
                sourceType: sourceType,
                sourceId: sourceId,
                sourceTodoId: sourceTodoId,
                quadrant: quadrant,
                priorityAbc: priorityAbc,
                domain: domain,
                estMinutes: estMinutes,
                plannedStart: plannedStart,
                plannedEnd: plannedEnd,
                status: status,
                doneAt: doneAt,
                resultNote: resultNote,
                isHabitRef: isHabitRef,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanItemTable, PlanItemData>(table),
                  $$PlanItemTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sourceTodoId = false,
                projectIncrementRefs = false,
                recurringOccurrenceRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (projectIncrementRefs) db.projectIncrement,
                    if (recurringOccurrenceRefs) db.recurringOccurrence,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceTodoId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceTodoId,
                            referencedTable: $$PlanItemTableReferences
                                ._sourceTodoIdTable(db),
                            referencedColumn: $$PlanItemTableReferences
                                ._sourceTodoIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (projectIncrementRefs)
                        await $_getPrefetchedDataByColumns<
                          PlanItemData,
                          $PlanItemTable,
                          ProjectIncrementData,
                          $ProjectIncrementTable
                        >(
                          currentTable: table,
                          referencedTable: $$PlanItemTableReferences
                              ._projectIncrementRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlanItemTableReferences(
                                db,
                                table,
                                p0,
                              ).projectIncrementRefs,
                          currentColumn: 'id',
                          referencedColumn: 'plan_item_id',
                          typedResults: items,
                        ),
                      if (recurringOccurrenceRefs)
                        await $_getPrefetchedDataByColumns<
                          PlanItemData,
                          $PlanItemTable,
                          RecurringOccurrenceData,
                          $RecurringOccurrenceTable
                        >(
                          currentTable: table,
                          referencedTable: $$PlanItemTableReferences
                              ._recurringOccurrenceRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlanItemTableReferences(
                                db,
                                table,
                                p0,
                              ).recurringOccurrenceRefs,
                          currentColumn: 'id',
                          referencedColumn: 'plan_item_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlanItemTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $PlanItemTable,
      PlanItemData,
      $$PlanItemTableFilterComposer,
      $$PlanItemTableOrderingComposer,
      $$PlanItemTableAnnotationComposer,
      $$PlanItemTableCreateCompanionBuilder,
      $$PlanItemTableUpdateCompanionBuilder,
      (PlanItemData, $$PlanItemTableReferences),
      PlanItemData,
      PrefetchHooks Function({
        bool sourceTodoId,
        bool projectIncrementRefs,
        bool recurringOccurrenceRefs,
      })
    >;
typedef $$HabitTableCreateCompanionBuilder = HabitCompanion Function({
  required String id,
  required String name,
  Value<String> description,
  Value<String> type,
  Value<double?> targetCount,
  Value<String> targetUnit,
  Value<String> scheduleType,
  Value<int?> weeklyN,
  Value<String> weekdays,
  Value<String> checklistJson,
  Value<String> domain,
  required String startDate,
  Value<int> archived,
  Value<String?> pausedUntil,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});
typedef $$HabitTableUpdateCompanionBuilder = HabitCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> description,
  Value<String> type,
  Value<double?> targetCount,
  Value<String> targetUnit,
  Value<String> scheduleType,
  Value<int?> weeklyN,
  Value<String> weekdays,
  Value<String> checklistJson,
  Value<String> domain,
  Value<String> startDate,
  Value<int> archived,
  Value<String?> pausedUntil,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});

final class $$HabitTableReferences
    extends BaseReferences<_$ActLogDatabase, $HabitTable, HabitData> {
  $$HabitTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HabitCheckinTable, List<HabitCheckinData>>
  _habitCheckinRefsTable(_$ActLogDatabase db) => MultiTypedResultKey.fromTable(
    db.habitCheckin,
    aliasName: 'habit__id__habit_checkin__habit_id',
  );

  $$HabitCheckinTableProcessedTableManager get habitCheckinRefs {
    final manager = $$HabitCheckinTableTableManager(
      $_db,
      $_db.habitCheckin,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitCheckinRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HabitScoreTable, List<HabitScoreData>>
  _habitScoreRefsTable(_$ActLogDatabase db) => MultiTypedResultKey.fromTable(
    db.habitScore,
    aliasName: 'habit__id__habit_score__habit_id',
  );

  $$HabitScoreTableProcessedTableManager get habitScoreRefs {
    final manager = $$HabitScoreTableTableManager(
      $_db,
      $_db.habitScore,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitScoreRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HabitTableFilterComposer
    extends Composer<_$ActLogDatabase, $HabitTable> {
  $$HabitTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetCount => $composableBuilder(
    column: $table.targetCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetUnit => $composableBuilder(
    column: $table.targetUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduleType => $composableBuilder(
    column: $table.scheduleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weeklyN => $composableBuilder(
    column: $table.weeklyN,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checklistJson => $composableBuilder(
    column: $table.checklistJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pausedUntil => $composableBuilder(
    column: $table.pausedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> habitCheckinRefs(
    Expression<bool> Function($$HabitCheckinTableFilterComposer f) f,
  ) {
    final $$HabitCheckinTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitCheckin,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitCheckinTableFilterComposer(
            $db: $db,
            $table: $db.habitCheckin,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> habitScoreRefs(
    Expression<bool> Function($$HabitScoreTableFilterComposer f) f,
  ) {
    final $$HabitScoreTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitScore,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitScoreTableFilterComposer(
            $db: $db,
            $table: $db.habitScore,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitTableOrderingComposer
    extends Composer<_$ActLogDatabase, $HabitTable> {
  $$HabitTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetCount => $composableBuilder(
    column: $table.targetCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetUnit => $composableBuilder(
    column: $table.targetUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduleType => $composableBuilder(
    column: $table.scheduleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weeklyN => $composableBuilder(
    column: $table.weeklyN,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checklistJson => $composableBuilder(
    column: $table.checklistJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pausedUntil => $composableBuilder(
    column: $table.pausedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $HabitTable> {
  $$HabitTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get targetCount => $composableBuilder(
    column: $table.targetCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetUnit => $composableBuilder(
    column: $table.targetUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scheduleType => $composableBuilder(
    column: $table.scheduleType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weeklyN =>
      $composableBuilder(column: $table.weeklyN, builder: (column) => column);

  GeneratedColumn<String> get weekdays =>
      $composableBuilder(column: $table.weekdays, builder: (column) => column);

  GeneratedColumn<String> get checklistJson => $composableBuilder(
    column: $table.checklistJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get pausedUntil => $composableBuilder(
    column: $table.pausedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  Expression<T> habitCheckinRefs<T extends Object>(
    Expression<T> Function($$HabitCheckinTableAnnotationComposer a) f,
  ) {
    final $$HabitCheckinTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitCheckin,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitCheckinTableAnnotationComposer(
            $db: $db,
            $table: $db.habitCheckin,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> habitScoreRefs<T extends Object>(
    Expression<T> Function($$HabitScoreTableAnnotationComposer a) f,
  ) {
    final $$HabitScoreTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitScore,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitScoreTableAnnotationComposer(
            $db: $db,
            $table: $db.habitScore,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $HabitTable,
          HabitData,
          $$HabitTableFilterComposer,
          $$HabitTableOrderingComposer,
          $$HabitTableAnnotationComposer,
          $$HabitTableCreateCompanionBuilder,
          $$HabitTableUpdateCompanionBuilder,
          (HabitData, $$HabitTableReferences),
          HabitData,
          PrefetchHooks Function({bool habitCheckinRefs, bool habitScoreRefs})
        > {
  $$HabitTableTableManager(_$ActLogDatabase db, $HabitTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double?> targetCount = const Value.absent(),
                Value<String> targetUnit = const Value.absent(),
                Value<String> scheduleType = const Value.absent(),
                Value<int?> weeklyN = const Value.absent(),
                Value<String> weekdays = const Value.absent(),
                Value<String> checklistJson = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<int> archived = const Value.absent(),
                Value<String?> pausedUntil = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCompanion(
                id: id,
                name: name,
                description: description,
                type: type,
                targetCount: targetCount,
                targetUnit: targetUnit,
                scheduleType: scheduleType,
                weeklyN: weeklyN,
                weekdays: weekdays,
                checklistJson: checklistJson,
                domain: domain,
                startDate: startDate,
                archived: archived,
                pausedUntil: pausedUntil,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> description = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double?> targetCount = const Value.absent(),
                Value<String> targetUnit = const Value.absent(),
                Value<String> scheduleType = const Value.absent(),
                Value<int?> weeklyN = const Value.absent(),
                Value<String> weekdays = const Value.absent(),
                Value<String> checklistJson = const Value.absent(),
                Value<String> domain = const Value.absent(),
                required String startDate,
                Value<int> archived = const Value.absent(),
                Value<String?> pausedUntil = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCompanion.insert(
                id: id,
                name: name,
                description: description,
                type: type,
                targetCount: targetCount,
                targetUnit: targetUnit,
                scheduleType: scheduleType,
                weeklyN: weeklyN,
                weekdays: weekdays,
                checklistJson: checklistJson,
                domain: domain,
                startDate: startDate,
                archived: archived,
                pausedUntil: pausedUntil,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitTable, HabitData>(table),
                  $$HabitTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({habitCheckinRefs = false, habitScoreRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (habitCheckinRefs) db.habitCheckin,
                    if (habitScoreRefs) db.habitScore,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (habitCheckinRefs)
                        await $_getPrefetchedDataByColumns<
                          HabitData,
                          $HabitTable,
                          HabitCheckinData,
                          $HabitCheckinTable
                        >(
                          currentTable: table,
                          referencedTable: $$HabitTableReferences
                              ._habitCheckinRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitTableReferences(
                                db,
                                table,
                                p0,
                              ).habitCheckinRefs,
                          currentColumn: 'id',
                          referencedColumn: 'habit_id',
                          typedResults: items,
                        ),
                      if (habitScoreRefs)
                        await $_getPrefetchedDataByColumns<
                          HabitData,
                          $HabitTable,
                          HabitScoreData,
                          $HabitScoreTable
                        >(
                          currentTable: table,
                          referencedTable: $$HabitTableReferences
                              ._habitScoreRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitTableReferences(
                                db,
                                table,
                                p0,
                              ).habitScoreRefs,
                          currentColumn: 'id',
                          referencedColumn: 'habit_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HabitTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $HabitTable,
      HabitData,
      $$HabitTableFilterComposer,
      $$HabitTableOrderingComposer,
      $$HabitTableAnnotationComposer,
      $$HabitTableCreateCompanionBuilder,
      $$HabitTableUpdateCompanionBuilder,
      (HabitData, $$HabitTableReferences),
      HabitData,
      PrefetchHooks Function({bool habitCheckinRefs, bool habitScoreRefs})
    >;
typedef $$HabitCheckinTableCreateCompanionBuilder =
    HabitCheckinCompanion Function({
      required String id,
      required String habitId,
      required String date,
      Value<double> value,
      Value<String> status,
      Value<String> note,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required String originDeviceId,
      Value<int> rev,
      Value<int> rowid,
    });
typedef $$HabitCheckinTableUpdateCompanionBuilder =
    HabitCheckinCompanion Function({
      Value<String> id,
      Value<String> habitId,
      Value<String> date,
      Value<double> value,
      Value<String> status,
      Value<String> note,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> originDeviceId,
      Value<int> rev,
      Value<int> rowid,
    });

final class $$HabitCheckinTableReferences
    extends
        BaseReferences<_$ActLogDatabase, $HabitCheckinTable, HabitCheckinData> {
  $$HabitCheckinTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitTable _habitIdTable(_$ActLogDatabase db) =>
      db.habit.createAlias('habit_checkin__habit_id__habit__id');

  $$HabitTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitTableTableManager(
      $_db,
      $_db.habit,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitCheckinTableFilterComposer
    extends Composer<_$ActLogDatabase, $HabitCheckinTable> {
  $$HabitCheckinTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitTableFilterComposer get habitId {
    final $$HabitTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habit,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitTableFilterComposer(
            $db: $db,
            $table: $db.habit,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitCheckinTableOrderingComposer
    extends Composer<_$ActLogDatabase, $HabitCheckinTable> {
  $$HabitCheckinTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitTableOrderingComposer get habitId {
    final $$HabitTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habit,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitTableOrderingComposer(
            $db: $db,
            $table: $db.habit,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitCheckinTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $HabitCheckinTable> {
  $$HabitCheckinTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  $$HabitTableAnnotationComposer get habitId {
    final $$HabitTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habit,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitTableAnnotationComposer(
            $db: $db,
            $table: $db.habit,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitCheckinTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $HabitCheckinTable,
          HabitCheckinData,
          $$HabitCheckinTableFilterComposer,
          $$HabitCheckinTableOrderingComposer,
          $$HabitCheckinTableAnnotationComposer,
          $$HabitCheckinTableCreateCompanionBuilder,
          $$HabitCheckinTableUpdateCompanionBuilder,
          (HabitCheckinData, $$HabitCheckinTableReferences),
          HabitCheckinData,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitCheckinTableTableManager(_$ActLogDatabase db, $HabitCheckinTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitCheckinTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitCheckinTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitCheckinTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> habitId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCheckinCompanion(
                id: id,
                habitId: habitId,
                date: date,
                value: value,
                status: status,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String habitId,
                required String date,
                Value<double> value = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> note = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCheckinCompanion.insert(
                id: id,
                habitId: habitId,
                date: date,
                value: value,
                status: status,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitCheckinTable, HabitCheckinData>(table),
                  $$HabitCheckinTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$HabitCheckinTableReferences
                            ._habitIdTable(db),
                        referencedColumn: $$HabitCheckinTableReferences
                            ._habitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HabitCheckinTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $HabitCheckinTable,
      HabitCheckinData,
      $$HabitCheckinTableFilterComposer,
      $$HabitCheckinTableOrderingComposer,
      $$HabitCheckinTableAnnotationComposer,
      $$HabitCheckinTableCreateCompanionBuilder,
      $$HabitCheckinTableUpdateCompanionBuilder,
      (HabitCheckinData, $$HabitCheckinTableReferences),
      HabitCheckinData,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$HabitScoreTableCreateCompanionBuilder = HabitScoreCompanion Function({
  required String id,
  required String habitId,
  required String date,
  Value<double> score,
  Value<int> streak,
  Value<int> longestStreak,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});
typedef $$HabitScoreTableUpdateCompanionBuilder = HabitScoreCompanion Function({
  Value<String> id,
  Value<String> habitId,
  Value<String> date,
  Value<double> score,
  Value<int> streak,
  Value<int> longestStreak,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});

final class $$HabitScoreTableReferences
    extends BaseReferences<_$ActLogDatabase, $HabitScoreTable, HabitScoreData> {
  $$HabitScoreTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitTable _habitIdTable(_$ActLogDatabase db) =>
      db.habit.createAlias('habit_score__habit_id__habit__id');

  $$HabitTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitTableTableManager(
      $_db,
      $_db.habit,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitScoreTableFilterComposer
    extends Composer<_$ActLogDatabase, $HabitScoreTable> {
  $$HabitScoreTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streak => $composableBuilder(
    column: $table.streak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitTableFilterComposer get habitId {
    final $$HabitTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habit,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitTableFilterComposer(
            $db: $db,
            $table: $db.habit,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitScoreTableOrderingComposer
    extends Composer<_$ActLogDatabase, $HabitScoreTable> {
  $$HabitScoreTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streak => $composableBuilder(
    column: $table.streak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitTableOrderingComposer get habitId {
    final $$HabitTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habit,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitTableOrderingComposer(
            $db: $db,
            $table: $db.habit,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitScoreTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $HabitScoreTable> {
  $$HabitScoreTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get streak =>
      $composableBuilder(column: $table.streak, builder: (column) => column);

  GeneratedColumn<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  $$HabitTableAnnotationComposer get habitId {
    final $$HabitTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habit,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitTableAnnotationComposer(
            $db: $db,
            $table: $db.habit,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitScoreTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $HabitScoreTable,
          HabitScoreData,
          $$HabitScoreTableFilterComposer,
          $$HabitScoreTableOrderingComposer,
          $$HabitScoreTableAnnotationComposer,
          $$HabitScoreTableCreateCompanionBuilder,
          $$HabitScoreTableUpdateCompanionBuilder,
          (HabitScoreData, $$HabitScoreTableReferences),
          HabitScoreData,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitScoreTableTableManager(_$ActLogDatabase db, $HabitScoreTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitScoreTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitScoreTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitScoreTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> habitId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<int> streak = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitScoreCompanion(
                id: id,
                habitId: habitId,
                date: date,
                score: score,
                streak: streak,
                longestStreak: longestStreak,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String habitId,
                required String date,
                Value<double> score = const Value.absent(),
                Value<int> streak = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitScoreCompanion.insert(
                id: id,
                habitId: habitId,
                date: date,
                score: score,
                streak: streak,
                longestStreak: longestStreak,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitScoreTable, HabitScoreData>(table),
                  $$HabitScoreTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$HabitScoreTableReferences
                            ._habitIdTable(db),
                        referencedColumn: $$HabitScoreTableReferences
                            ._habitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HabitScoreTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $HabitScoreTable,
      HabitScoreData,
      $$HabitScoreTableFilterComposer,
      $$HabitScoreTableOrderingComposer,
      $$HabitScoreTableAnnotationComposer,
      $$HabitScoreTableCreateCompanionBuilder,
      $$HabitScoreTableUpdateCompanionBuilder,
      (HabitScoreData, $$HabitScoreTableReferences),
      HabitScoreData,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$ProjectMilestoneTableCreateCompanionBuilder =
    ProjectMilestoneCompanion Function({
      required String id,
      required String projectId,
      required String title,
      Value<String?> targetDate,
      Value<int?> achievedAt,
      Value<String> note,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required String originDeviceId,
      Value<int> rev,
      Value<int> rowid,
    });
typedef $$ProjectMilestoneTableUpdateCompanionBuilder =
    ProjectMilestoneCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> title,
      Value<String?> targetDate,
      Value<int?> achievedAt,
      Value<String> note,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> originDeviceId,
      Value<int> rev,
      Value<int> rowid,
    });

final class $$ProjectMilestoneTableReferences
    extends
        BaseReferences<
          _$ActLogDatabase,
          $ProjectMilestoneTable,
          ProjectMilestoneData
        > {
  $$ProjectMilestoneTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProjectTable _projectIdTable(_$ActLogDatabase db) =>
      db.project.createAlias('project_milestone__project_id__project__id');

  $$ProjectTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectTableTableManager(
      $_db,
      $_db.project,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProjectMilestoneTableFilterComposer
    extends Composer<_$ActLogDatabase, $ProjectMilestoneTable> {
  $$ProjectMilestoneTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get achievedAt => $composableBuilder(
    column: $table.achievedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectTableFilterComposer get projectId {
    final $$ProjectTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.project,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectTableFilterComposer(
            $db: $db,
            $table: $db.project,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectMilestoneTableOrderingComposer
    extends Composer<_$ActLogDatabase, $ProjectMilestoneTable> {
  $$ProjectMilestoneTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get achievedAt => $composableBuilder(
    column: $table.achievedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectTableOrderingComposer get projectId {
    final $$ProjectTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.project,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectTableOrderingComposer(
            $db: $db,
            $table: $db.project,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectMilestoneTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $ProjectMilestoneTable> {
  $$ProjectMilestoneTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get achievedAt => $composableBuilder(
    column: $table.achievedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  $$ProjectTableAnnotationComposer get projectId {
    final $$ProjectTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.project,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectTableAnnotationComposer(
            $db: $db,
            $table: $db.project,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectMilestoneTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $ProjectMilestoneTable,
          ProjectMilestoneData,
          $$ProjectMilestoneTableFilterComposer,
          $$ProjectMilestoneTableOrderingComposer,
          $$ProjectMilestoneTableAnnotationComposer,
          $$ProjectMilestoneTableCreateCompanionBuilder,
          $$ProjectMilestoneTableUpdateCompanionBuilder,
          (ProjectMilestoneData, $$ProjectMilestoneTableReferences),
          ProjectMilestoneData,
          PrefetchHooks Function({bool projectId})
        > {
  $$ProjectMilestoneTableTableManager(
    _$ActLogDatabase db,
    $ProjectMilestoneTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectMilestoneTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectMilestoneTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectMilestoneTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> targetDate = const Value.absent(),
                Value<int?> achievedAt = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectMilestoneCompanion(
                id: id,
                projectId: projectId,
                title: title,
                targetDate: targetDate,
                achievedAt: achievedAt,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String title,
                Value<String?> targetDate = const Value.absent(),
                Value<int?> achievedAt = const Value.absent(),
                Value<String> note = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectMilestoneCompanion.insert(
                id: id,
                projectId: projectId,
                title: title,
                targetDate: targetDate,
                achievedAt: achievedAt,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectMilestoneTable, ProjectMilestoneData>(
                    table,
                  ),
                  $$ProjectMilestoneTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$ProjectMilestoneTableReferences
                            ._projectIdTable(db),
                        referencedColumn: $$ProjectMilestoneTableReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProjectMilestoneTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $ProjectMilestoneTable,
      ProjectMilestoneData,
      $$ProjectMilestoneTableFilterComposer,
      $$ProjectMilestoneTableOrderingComposer,
      $$ProjectMilestoneTableAnnotationComposer,
      $$ProjectMilestoneTableCreateCompanionBuilder,
      $$ProjectMilestoneTableUpdateCompanionBuilder,
      (ProjectMilestoneData, $$ProjectMilestoneTableReferences),
      ProjectMilestoneData,
      PrefetchHooks Function({bool projectId})
    >;
typedef $$ProjectIncrementTableCreateCompanionBuilder =
    ProjectIncrementCompanion Function({
      required String id,
      required String projectId,
      required String date,
      Value<String?> planItemId,
      Value<String> progress,
      Value<String> blockers,
      Value<String> nextStep,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required String originDeviceId,
      Value<int> rev,
      Value<int> rowid,
    });
typedef $$ProjectIncrementTableUpdateCompanionBuilder =
    ProjectIncrementCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> date,
      Value<String?> planItemId,
      Value<String> progress,
      Value<String> blockers,
      Value<String> nextStep,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> originDeviceId,
      Value<int> rev,
      Value<int> rowid,
    });

final class $$ProjectIncrementTableReferences
    extends
        BaseReferences<
          _$ActLogDatabase,
          $ProjectIncrementTable,
          ProjectIncrementData
        > {
  $$ProjectIncrementTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProjectTable _projectIdTable(_$ActLogDatabase db) =>
      db.project.createAlias('project_increment__project_id__project__id');

  $$ProjectTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectTableTableManager(
      $_db,
      $_db.project,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlanItemTable _planItemIdTable(_$ActLogDatabase db) =>
      db.planItem.createAlias('project_increment__plan_item_id__plan_item__id');

  $$PlanItemTableProcessedTableManager? get planItemId {
    final $_column = $_itemColumn<String>('plan_item_id');
    if ($_column == null) return null;
    final manager = $$PlanItemTableTableManager(
      $_db,
      $_db.planItem,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProjectIncrementTableFilterComposer
    extends Composer<_$ActLogDatabase, $ProjectIncrementTable> {
  $$ProjectIncrementTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockers => $composableBuilder(
    column: $table.blockers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextStep => $composableBuilder(
    column: $table.nextStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectTableFilterComposer get projectId {
    final $$ProjectTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.project,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectTableFilterComposer(
            $db: $db,
            $table: $db.project,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlanItemTableFilterComposer get planItemId {
    final $$PlanItemTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planItemId,
      referencedTable: $db.planItem,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemTableFilterComposer(
            $db: $db,
            $table: $db.planItem,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectIncrementTableOrderingComposer
    extends Composer<_$ActLogDatabase, $ProjectIncrementTable> {
  $$ProjectIncrementTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockers => $composableBuilder(
    column: $table.blockers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextStep => $composableBuilder(
    column: $table.nextStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectTableOrderingComposer get projectId {
    final $$ProjectTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.project,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectTableOrderingComposer(
            $db: $db,
            $table: $db.project,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlanItemTableOrderingComposer get planItemId {
    final $$PlanItemTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planItemId,
      referencedTable: $db.planItem,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemTableOrderingComposer(
            $db: $db,
            $table: $db.planItem,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectIncrementTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $ProjectIncrementTable> {
  $$ProjectIncrementTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get blockers =>
      $composableBuilder(column: $table.blockers, builder: (column) => column);

  GeneratedColumn<String> get nextStep =>
      $composableBuilder(column: $table.nextStep, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  $$ProjectTableAnnotationComposer get projectId {
    final $$ProjectTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.project,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectTableAnnotationComposer(
            $db: $db,
            $table: $db.project,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlanItemTableAnnotationComposer get planItemId {
    final $$PlanItemTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planItemId,
      referencedTable: $db.planItem,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemTableAnnotationComposer(
            $db: $db,
            $table: $db.planItem,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectIncrementTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $ProjectIncrementTable,
          ProjectIncrementData,
          $$ProjectIncrementTableFilterComposer,
          $$ProjectIncrementTableOrderingComposer,
          $$ProjectIncrementTableAnnotationComposer,
          $$ProjectIncrementTableCreateCompanionBuilder,
          $$ProjectIncrementTableUpdateCompanionBuilder,
          (ProjectIncrementData, $$ProjectIncrementTableReferences),
          ProjectIncrementData,
          PrefetchHooks Function({bool projectId, bool planItemId})
        > {
  $$ProjectIncrementTableTableManager(
    _$ActLogDatabase db,
    $ProjectIncrementTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectIncrementTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectIncrementTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectIncrementTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> planItemId = const Value.absent(),
                Value<String> progress = const Value.absent(),
                Value<String> blockers = const Value.absent(),
                Value<String> nextStep = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectIncrementCompanion(
                id: id,
                projectId: projectId,
                date: date,
                planItemId: planItemId,
                progress: progress,
                blockers: blockers,
                nextStep: nextStep,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String date,
                Value<String?> planItemId = const Value.absent(),
                Value<String> progress = const Value.absent(),
                Value<String> blockers = const Value.absent(),
                Value<String> nextStep = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectIncrementCompanion.insert(
                id: id,
                projectId: projectId,
                date: date,
                planItemId: planItemId,
                progress: progress,
                blockers: blockers,
                nextStep: nextStep,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectIncrementTable, ProjectIncrementData>(
                    table,
                  ),
                  $$ProjectIncrementTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false, planItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$ProjectIncrementTableReferences
                            ._projectIdTable(db),
                        referencedColumn: $$ProjectIncrementTableReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (planItemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.planItemId,
                        referencedTable: $$ProjectIncrementTableReferences
                            ._planItemIdTable(db),
                        referencedColumn: $$ProjectIncrementTableReferences
                            ._planItemIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProjectIncrementTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $ProjectIncrementTable,
      ProjectIncrementData,
      $$ProjectIncrementTableFilterComposer,
      $$ProjectIncrementTableOrderingComposer,
      $$ProjectIncrementTableAnnotationComposer,
      $$ProjectIncrementTableCreateCompanionBuilder,
      $$ProjectIncrementTableUpdateCompanionBuilder,
      (ProjectIncrementData, $$ProjectIncrementTableReferences),
      ProjectIncrementData,
      PrefetchHooks Function({bool projectId, bool planItemId})
    >;
typedef $$ReminderTableCreateCompanionBuilder = ReminderCompanion Function({
  required String id,
  required String targetType,
  required String targetId,
  required int remindAt,
  Value<String> repeatRule,
  Value<String> repeatDetail,
  Value<int> enabled,
  Value<int?> lastFiredAt,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});
typedef $$ReminderTableUpdateCompanionBuilder = ReminderCompanion Function({
  Value<String> id,
  Value<String> targetType,
  Value<String> targetId,
  Value<int> remindAt,
  Value<String> repeatRule,
  Value<String> repeatDetail,
  Value<int> enabled,
  Value<int?> lastFiredAt,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});

class $$ReminderTableFilterComposer
    extends Composer<_$ActLogDatabase, $ReminderTable> {
  $$ReminderTableFilterComposer({
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

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatDetail => $composableBuilder(
    column: $table.repeatDetail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastFiredAt => $composableBuilder(
    column: $table.lastFiredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReminderTableOrderingComposer
    extends Composer<_$ActLogDatabase, $ReminderTable> {
  $$ReminderTableOrderingComposer({
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

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatDetail => $composableBuilder(
    column: $table.repeatDetail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastFiredAt => $composableBuilder(
    column: $table.lastFiredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReminderTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $ReminderTable> {
  $$ReminderTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<int> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  GeneratedColumn<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeatDetail => $composableBuilder(
    column: $table.repeatDetail,
    builder: (column) => column,
  );

  GeneratedColumn<int> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get lastFiredAt => $composableBuilder(
    column: $table.lastFiredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);
}

class $$ReminderTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $ReminderTable,
          ReminderData,
          $$ReminderTableFilterComposer,
          $$ReminderTableOrderingComposer,
          $$ReminderTableAnnotationComposer,
          $$ReminderTableCreateCompanionBuilder,
          $$ReminderTableUpdateCompanionBuilder,
          (
            ReminderData,
            BaseReferences<_$ActLogDatabase, $ReminderTable, ReminderData>,
          ),
          ReminderData,
          PrefetchHooks Function()
        > {
  $$ReminderTableTableManager(_$ActLogDatabase db, $ReminderTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<int> remindAt = const Value.absent(),
                Value<String> repeatRule = const Value.absent(),
                Value<String> repeatDetail = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<int?> lastFiredAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderCompanion(
                id: id,
                targetType: targetType,
                targetId: targetId,
                remindAt: remindAt,
                repeatRule: repeatRule,
                repeatDetail: repeatDetail,
                enabled: enabled,
                lastFiredAt: lastFiredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String targetType,
                required String targetId,
                required int remindAt,
                Value<String> repeatRule = const Value.absent(),
                Value<String> repeatDetail = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<int?> lastFiredAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderCompanion.insert(
                id: id,
                targetType: targetType,
                targetId: targetId,
                remindAt: remindAt,
                repeatRule: repeatRule,
                repeatDetail: repeatDetail,
                enabled: enabled,
                lastFiredAt: lastFiredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReminderTable, ReminderData>(table),
                  BaseReferences<
                    _$ActLogDatabase,
                    $ReminderTable,
                    ReminderData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReminderTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $ReminderTable,
      ReminderData,
      $$ReminderTableFilterComposer,
      $$ReminderTableOrderingComposer,
      $$ReminderTableAnnotationComposer,
      $$ReminderTableCreateCompanionBuilder,
      $$ReminderTableUpdateCompanionBuilder,
      (
        ReminderData,
        BaseReferences<_$ActLogDatabase, $ReminderTable, ReminderData>,
      ),
      ReminderData,
      PrefetchHooks Function()
    >;
typedef $$OplogTableCreateCompanionBuilder = OplogCompanion Function({
  Value<int> id,
  required String entityTable,
  required String entityId,
  required String op,
  Value<String?> payload,
  required int lamport,
  required String deviceId,
  required int createdAt,
  Value<int> synced,
});
typedef $$OplogTableUpdateCompanionBuilder = OplogCompanion Function({
  Value<int> id,
  Value<String> entityTable,
  Value<String> entityId,
  Value<String> op,
  Value<String?> payload,
  Value<int> lamport,
  Value<String> deviceId,
  Value<int> createdAt,
  Value<int> synced,
});

class $$OplogTableFilterComposer
    extends Composer<_$ActLogDatabase, $OplogTable> {
  $$OplogTableFilterComposer({
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

  ColumnFilters<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OplogTableOrderingComposer
    extends Composer<_$ActLogDatabase, $OplogTable> {
  $$OplogTableOrderingComposer({
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

  ColumnOrderings<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OplogTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $OplogTable> {
  $$OplogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get lamport =>
      $composableBuilder(column: $table.lamport, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$OplogTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $OplogTable,
          OplogData,
          $$OplogTableFilterComposer,
          $$OplogTableOrderingComposer,
          $$OplogTableAnnotationComposer,
          $$OplogTableCreateCompanionBuilder,
          $$OplogTableUpdateCompanionBuilder,
          (OplogData, BaseReferences<_$ActLogDatabase, $OplogTable, OplogData>),
          OplogData,
          PrefetchHooks Function()
        > {
  $$OplogTableTableManager(_$ActLogDatabase db, $OplogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OplogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OplogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OplogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityTable = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<int> lamport = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => OplogCompanion(
                id: id,
                entityTable: entityTable,
                entityId: entityId,
                op: op,
                payload: payload,
                lamport: lamport,
                deviceId: deviceId,
                createdAt: createdAt,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityTable,
                required String entityId,
                required String op,
                Value<String?> payload = const Value.absent(),
                required int lamport,
                required String deviceId,
                required int createdAt,
                Value<int> synced = const Value.absent(),
              }) => OplogCompanion.insert(
                id: id,
                entityTable: entityTable,
                entityId: entityId,
                op: op,
                payload: payload,
                lamport: lamport,
                deviceId: deviceId,
                createdAt: createdAt,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OplogTable, OplogData>(table),
                  BaseReferences<_$ActLogDatabase, $OplogTable, OplogData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OplogTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $OplogTable,
      OplogData,
      $$OplogTableFilterComposer,
      $$OplogTableOrderingComposer,
      $$OplogTableAnnotationComposer,
      $$OplogTableCreateCompanionBuilder,
      $$OplogTableUpdateCompanionBuilder,
      (OplogData, BaseReferences<_$ActLogDatabase, $OplogTable, OplogData>),
      OplogData,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String id,
  required String key,
  Value<String> value,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> id,
  Value<String> key,
  Value<String> value,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> originDeviceId,
  Value<int> rev,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$ActLogDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
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

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$ActLogDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
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

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $SyncStateTable,
          SyncStateData,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateData,
            BaseReferences<_$ActLogDatabase, $SyncStateTable, SyncStateData>,
          ),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$ActLogDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                id: id,
                key: key,
                value: value,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String key,
                Value<String> value = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                id: id,
                key: key,
                value: value,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateData>(table),
                  BaseReferences<
                    _$ActLogDatabase,
                    $SyncStateTable,
                    SyncStateData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $SyncStateTable,
      SyncStateData,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateData,
        BaseReferences<_$ActLogDatabase, $SyncStateTable, SyncStateData>,
      ),
      SyncStateData,
      PrefetchHooks Function()
    >;
typedef $$SnapshotMetaTableCreateCompanionBuilder =
    SnapshotMetaCompanion Function({
      required String id,
      required String path,
      required String kind,
      required String sha256,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required String originDeviceId,
      Value<int> rev,
      Value<int> rowid,
    });
typedef $$SnapshotMetaTableUpdateCompanionBuilder =
    SnapshotMetaCompanion Function({
      Value<String> id,
      Value<String> path,
      Value<String> kind,
      Value<String> sha256,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> originDeviceId,
      Value<int> rev,
      Value<int> rowid,
    });

class $$SnapshotMetaTableFilterComposer
    extends Composer<_$ActLogDatabase, $SnapshotMetaTable> {
  $$SnapshotMetaTableFilterComposer({
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

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SnapshotMetaTableOrderingComposer
    extends Composer<_$ActLogDatabase, $SnapshotMetaTable> {
  $$SnapshotMetaTableOrderingComposer({
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

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SnapshotMetaTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $SnapshotMetaTable> {
  $$SnapshotMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);
}

class $$SnapshotMetaTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $SnapshotMetaTable,
          SnapshotMetaData,
          $$SnapshotMetaTableFilterComposer,
          $$SnapshotMetaTableOrderingComposer,
          $$SnapshotMetaTableAnnotationComposer,
          $$SnapshotMetaTableCreateCompanionBuilder,
          $$SnapshotMetaTableUpdateCompanionBuilder,
          (
            SnapshotMetaData,
            BaseReferences<
              _$ActLogDatabase,
              $SnapshotMetaTable,
              SnapshotMetaData
            >,
          ),
          SnapshotMetaData,
          PrefetchHooks Function()
        > {
  $$SnapshotMetaTableTableManager(_$ActLogDatabase db, $SnapshotMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnapshotMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnapshotMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnapshotMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotMetaCompanion(
                id: id,
                path: path,
                kind: kind,
                sha256: sha256,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String path,
                required String kind,
                required String sha256,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotMetaCompanion.insert(
                id: id,
                path: path,
                kind: kind,
                sha256: sha256,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SnapshotMetaTable, SnapshotMetaData>(table),
                  BaseReferences<
                    _$ActLogDatabase,
                    $SnapshotMetaTable,
                    SnapshotMetaData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SnapshotMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $SnapshotMetaTable,
      SnapshotMetaData,
      $$SnapshotMetaTableFilterComposer,
      $$SnapshotMetaTableOrderingComposer,
      $$SnapshotMetaTableAnnotationComposer,
      $$SnapshotMetaTableCreateCompanionBuilder,
      $$SnapshotMetaTableUpdateCompanionBuilder,
      (
        SnapshotMetaData,
        BaseReferences<_$ActLogDatabase, $SnapshotMetaTable, SnapshotMetaData>,
      ),
      SnapshotMetaData,
      PrefetchHooks Function()
    >;
typedef $$RecurringTaskTableCreateCompanionBuilder =
    RecurringTaskCompanion Function({
      required String id,
      required String title,
      Value<String> note,
      required int weekdayMask,
      required int startMinute,
      Value<int> durationMinutes,
      Value<int> active,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required String originDeviceId,
      Value<int> rev,
      Value<int> rowid,
    });
typedef $$RecurringTaskTableUpdateCompanionBuilder =
    RecurringTaskCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> note,
      Value<int> weekdayMask,
      Value<int> startMinute,
      Value<int> durationMinutes,
      Value<int> active,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> originDeviceId,
      Value<int> rev,
      Value<int> rowid,
    });

final class $$RecurringTaskTableReferences
    extends
        BaseReferences<
          _$ActLogDatabase,
          $RecurringTaskTable,
          RecurringTaskData
        > {
  $$RecurringTaskTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $RecurringOccurrenceTable,
    List<RecurringOccurrenceData>
  >
  _recurringOccurrenceRefsTable(_$ActLogDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recurringOccurrence,
        aliasName: 'recurring_task__id__recurring_occurrence__task_id',
      );

  $$RecurringOccurrenceTableProcessedTableManager get recurringOccurrenceRefs {
    final manager = $$RecurringOccurrenceTableTableManager(
      $_db,
      $_db.recurringOccurrence,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recurringOccurrenceRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecurringTaskTableFilterComposer
    extends Composer<_$ActLogDatabase, $RecurringTaskTable> {
  $$RecurringTaskTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekdayMask => $composableBuilder(
    column: $table.weekdayMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> recurringOccurrenceRefs(
    Expression<bool> Function($$RecurringOccurrenceTableFilterComposer f) f,
  ) {
    final $$RecurringOccurrenceTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurringOccurrence,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringOccurrenceTableFilterComposer(
            $db: $db,
            $table: $db.recurringOccurrence,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringTaskTableOrderingComposer
    extends Composer<_$ActLogDatabase, $RecurringTaskTable> {
  $$RecurringTaskTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekdayMask => $composableBuilder(
    column: $table.weekdayMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurringTaskTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $RecurringTaskTable> {
  $$RecurringTaskTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get weekdayMask => $composableBuilder(
    column: $table.weekdayMask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  Expression<T> recurringOccurrenceRefs<T extends Object>(
    Expression<T> Function($$RecurringOccurrenceTableAnnotationComposer a) f,
  ) {
    final $$RecurringOccurrenceTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recurringOccurrence,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecurringOccurrenceTableAnnotationComposer(
                $db: $db,
                $table: $db.recurringOccurrence,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RecurringTaskTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $RecurringTaskTable,
          RecurringTaskData,
          $$RecurringTaskTableFilterComposer,
          $$RecurringTaskTableOrderingComposer,
          $$RecurringTaskTableAnnotationComposer,
          $$RecurringTaskTableCreateCompanionBuilder,
          $$RecurringTaskTableUpdateCompanionBuilder,
          (RecurringTaskData, $$RecurringTaskTableReferences),
          RecurringTaskData,
          PrefetchHooks Function({bool recurringOccurrenceRefs})
        > {
  $$RecurringTaskTableTableManager(
    _$ActLogDatabase db,
    $RecurringTaskTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringTaskTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringTaskTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringTaskTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> weekdayMask = const Value.absent(),
                Value<int> startMinute = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<int> active = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringTaskCompanion(
                id: id,
                title: title,
                note: note,
                weekdayMask: weekdayMask,
                startMinute: startMinute,
                durationMinutes: durationMinutes,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> note = const Value.absent(),
                required int weekdayMask,
                required int startMinute,
                Value<int> durationMinutes = const Value.absent(),
                Value<int> active = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringTaskCompanion.insert(
                id: id,
                title: title,
                note: note,
                weekdayMask: weekdayMask,
                startMinute: startMinute,
                durationMinutes: durationMinutes,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurringTaskTable, RecurringTaskData>(table),
                  $$RecurringTaskTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recurringOccurrenceRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recurringOccurrenceRefs) db.recurringOccurrence,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recurringOccurrenceRefs)
                    await $_getPrefetchedDataByColumns<
                      RecurringTaskData,
                      $RecurringTaskTable,
                      RecurringOccurrenceData,
                      $RecurringOccurrenceTable
                    >(
                      currentTable: table,
                      referencedTable: $$RecurringTaskTableReferences
                          ._recurringOccurrenceRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RecurringTaskTableReferences(
                            db,
                            table,
                            p0,
                          ).recurringOccurrenceRefs,
                      currentColumn: 'id',
                      referencedColumn: 'task_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RecurringTaskTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $RecurringTaskTable,
      RecurringTaskData,
      $$RecurringTaskTableFilterComposer,
      $$RecurringTaskTableOrderingComposer,
      $$RecurringTaskTableAnnotationComposer,
      $$RecurringTaskTableCreateCompanionBuilder,
      $$RecurringTaskTableUpdateCompanionBuilder,
      (RecurringTaskData, $$RecurringTaskTableReferences),
      RecurringTaskData,
      PrefetchHooks Function({bool recurringOccurrenceRefs})
    >;
typedef $$RecurringOccurrenceTableCreateCompanionBuilder =
    RecurringOccurrenceCompanion Function({
      required String id,
      required String taskId,
      required String date,
      Value<String?> planItemId,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required String originDeviceId,
      Value<int> rev,
      Value<int> rowid,
    });
typedef $$RecurringOccurrenceTableUpdateCompanionBuilder =
    RecurringOccurrenceCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> date,
      Value<String?> planItemId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> originDeviceId,
      Value<int> rev,
      Value<int> rowid,
    });

final class $$RecurringOccurrenceTableReferences
    extends
        BaseReferences<
          _$ActLogDatabase,
          $RecurringOccurrenceTable,
          RecurringOccurrenceData
        > {
  $$RecurringOccurrenceTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecurringTaskTable _taskIdTable(_$ActLogDatabase db) => db
      .recurringTask
      .createAlias('recurring_occurrence__task_id__recurring_task__id');

  $$RecurringTaskTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$RecurringTaskTableTableManager(
      $_db,
      $_db.recurringTask,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlanItemTable _planItemIdTable(_$ActLogDatabase db) => db.planItem
      .createAlias('recurring_occurrence__plan_item_id__plan_item__id');

  $$PlanItemTableProcessedTableManager? get planItemId {
    final $_column = $_itemColumn<String>('plan_item_id');
    if ($_column == null) return null;
    final manager = $$PlanItemTableTableManager(
      $_db,
      $_db.planItem,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecurringOccurrenceTableFilterComposer
    extends Composer<_$ActLogDatabase, $RecurringOccurrenceTable> {
  $$RecurringOccurrenceTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnFilters(column),
  );

  $$RecurringTaskTableFilterComposer get taskId {
    final $$RecurringTaskTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.recurringTask,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringTaskTableFilterComposer(
            $db: $db,
            $table: $db.recurringTask,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlanItemTableFilterComposer get planItemId {
    final $$PlanItemTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planItemId,
      referencedTable: $db.planItem,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemTableFilterComposer(
            $db: $db,
            $table: $db.planItem,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringOccurrenceTableOrderingComposer
    extends Composer<_$ActLogDatabase, $RecurringOccurrenceTable> {
  $$RecurringOccurrenceTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rev => $composableBuilder(
    column: $table.rev,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecurringTaskTableOrderingComposer get taskId {
    final $$RecurringTaskTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.recurringTask,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringTaskTableOrderingComposer(
            $db: $db,
            $table: $db.recurringTask,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlanItemTableOrderingComposer get planItemId {
    final $$PlanItemTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planItemId,
      referencedTable: $db.planItem,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemTableOrderingComposer(
            $db: $db,
            $table: $db.planItem,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringOccurrenceTableAnnotationComposer
    extends Composer<_$ActLogDatabase, $RecurringOccurrenceTable> {
  $$RecurringOccurrenceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  $$RecurringTaskTableAnnotationComposer get taskId {
    final $$RecurringTaskTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.recurringTask,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringTaskTableAnnotationComposer(
            $db: $db,
            $table: $db.recurringTask,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlanItemTableAnnotationComposer get planItemId {
    final $$PlanItemTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planItemId,
      referencedTable: $db.planItem,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemTableAnnotationComposer(
            $db: $db,
            $table: $db.planItem,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringOccurrenceTableTableManager
    extends
        RootTableManager<
          _$ActLogDatabase,
          $RecurringOccurrenceTable,
          RecurringOccurrenceData,
          $$RecurringOccurrenceTableFilterComposer,
          $$RecurringOccurrenceTableOrderingComposer,
          $$RecurringOccurrenceTableAnnotationComposer,
          $$RecurringOccurrenceTableCreateCompanionBuilder,
          $$RecurringOccurrenceTableUpdateCompanionBuilder,
          (RecurringOccurrenceData, $$RecurringOccurrenceTableReferences),
          RecurringOccurrenceData,
          PrefetchHooks Function({bool taskId, bool planItemId})
        > {
  $$RecurringOccurrenceTableTableManager(
    _$ActLogDatabase db,
    $RecurringOccurrenceTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringOccurrenceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringOccurrenceTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RecurringOccurrenceTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> planItemId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringOccurrenceCompanion(
                id: id,
                taskId: taskId,
                date: date,
                planItemId: planItemId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String date,
                Value<String?> planItemId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String originDeviceId,
                Value<int> rev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringOccurrenceCompanion.insert(
                id: id,
                taskId: taskId,
                date: date,
                planItemId: planItemId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                originDeviceId: originDeviceId,
                rev: rev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $RecurringOccurrenceTable,
                    RecurringOccurrenceData
                  >(table),
                  $$RecurringOccurrenceTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false, planItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$RecurringOccurrenceTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$RecurringOccurrenceTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (planItemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.planItemId,
                        referencedTable: $$RecurringOccurrenceTableReferences
                            ._planItemIdTable(db),
                        referencedColumn: $$RecurringOccurrenceTableReferences
                            ._planItemIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecurringOccurrenceTableProcessedTableManager =
    ProcessedTableManager<
      _$ActLogDatabase,
      $RecurringOccurrenceTable,
      RecurringOccurrenceData,
      $$RecurringOccurrenceTableFilterComposer,
      $$RecurringOccurrenceTableOrderingComposer,
      $$RecurringOccurrenceTableAnnotationComposer,
      $$RecurringOccurrenceTableCreateCompanionBuilder,
      $$RecurringOccurrenceTableUpdateCompanionBuilder,
      (RecurringOccurrenceData, $$RecurringOccurrenceTableReferences),
      RecurringOccurrenceData,
      PrefetchHooks Function({bool taskId, bool planItemId})
    >;

class $ActLogDatabaseManager {
  final _$ActLogDatabase _db;
  $ActLogDatabaseManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$DayLogTableTableManager get dayLog =>
      $$DayLogTableTableManager(_db, _db.dayLog);
  $$ProjectTableTableManager get project =>
      $$ProjectTableTableManager(_db, _db.project);
  $$TodoTableTableManager get todo => $$TodoTableTableManager(_db, _db.todo);
  $$PlanItemTableTableManager get planItem =>
      $$PlanItemTableTableManager(_db, _db.planItem);
  $$HabitTableTableManager get habit =>
      $$HabitTableTableManager(_db, _db.habit);
  $$HabitCheckinTableTableManager get habitCheckin =>
      $$HabitCheckinTableTableManager(_db, _db.habitCheckin);
  $$HabitScoreTableTableManager get habitScore =>
      $$HabitScoreTableTableManager(_db, _db.habitScore);
  $$ProjectMilestoneTableTableManager get projectMilestone =>
      $$ProjectMilestoneTableTableManager(_db, _db.projectMilestone);
  $$ProjectIncrementTableTableManager get projectIncrement =>
      $$ProjectIncrementTableTableManager(_db, _db.projectIncrement);
  $$ReminderTableTableManager get reminder =>
      $$ReminderTableTableManager(_db, _db.reminder);
  $$OplogTableTableManager get oplog =>
      $$OplogTableTableManager(_db, _db.oplog);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$SnapshotMetaTableTableManager get snapshotMeta =>
      $$SnapshotMetaTableTableManager(_db, _db.snapshotMeta);
  $$RecurringTaskTableTableManager get recurringTask =>
      $$RecurringTaskTableTableManager(_db, _db.recurringTask);
  $$RecurringOccurrenceTableTableManager get recurringOccurrence =>
      $$RecurringOccurrenceTableTableManager(_db, _db.recurringOccurrence);
}
