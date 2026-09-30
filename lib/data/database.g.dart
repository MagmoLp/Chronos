// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $JobsTable extends Jobs with TableInfo<$JobsTable, JobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _colorArgbMeta = const VerificationMeta(
    'colorArgb',
  );
  @override
  late final GeneratedColumn<int> colorArgb = GeneratedColumn<int>(
    'color_argb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RoundingRule, String> rounding =
      GeneratedColumn<String>(
        'rounding',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RoundingRule>($JobsTable.$converterrounding);
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    name,
    colorArgb,
    rounding,
    archived,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<JobRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_argb')) {
      context.handle(
        _colorArgbMeta,
        colorArgb.isAcceptableOrUnknown(data['color_argb']!, _colorArgbMeta),
      );
    } else if (isInserting) {
      context.missing(_colorArgbMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_argb'],
      )!,
      rounding: $JobsTable.$converterrounding.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}rounding'],
        )!,
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $JobsTable createAlias(String alias) {
    return $JobsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RoundingRule, String, String> $converterrounding =
      const EnumNameConverter<RoundingRule>(RoundingRule.values);
}

class JobRow extends DataClass implements Insertable<JobRow> {
  final int id;
  final String uuid;
  final String name;
  final int colorArgb;
  final RoundingRule rounding;
  final bool archived;
  final int sortOrder;

  /// UTC epoch ms.
  final int createdAt;

  /// UTC epoch ms.
  final int updatedAt;
  const JobRow({
    required this.id,
    required this.uuid,
    required this.name,
    required this.colorArgb,
    required this.rounding,
    required this.archived,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['color_argb'] = Variable<int>(colorArgb);
    {
      map['rounding'] = Variable<String>(
        $JobsTable.$converterrounding.toSql(rounding),
      );
    }
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      colorArgb: Value(colorArgb),
      rounding: Value(rounding),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory JobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      colorArgb: serializer.fromJson<int>(json['colorArgb']),
      rounding: $JobsTable.$converterrounding.fromJson(
        serializer.fromJson<String>(json['rounding']),
      ),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'colorArgb': serializer.toJson<int>(colorArgb),
      'rounding': serializer.toJson<String>(
        $JobsTable.$converterrounding.toJson(rounding),
      ),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  JobRow copyWith({
    int? id,
    String? uuid,
    String? name,
    int? colorArgb,
    RoundingRule? rounding,
    bool? archived,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => JobRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    colorArgb: colorArgb ?? this.colorArgb,
    rounding: rounding ?? this.rounding,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  JobRow copyWithCompanion(JobsCompanion data) {
    return JobRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      colorArgb: data.colorArgb.present ? data.colorArgb.value : this.colorArgb,
      rounding: data.rounding.present ? data.rounding.value : this.rounding,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('rounding: $rounding, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    name,
    colorArgb,
    rounding,
    archived,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.colorArgb == this.colorArgb &&
          other.rounding == this.rounding &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class JobsCompanion extends UpdateCompanion<JobRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<int> colorArgb;
  final Value<RoundingRule> rounding;
  final Value<bool> archived;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const JobsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.colorArgb = const Value.absent(),
    this.rounding = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  JobsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String name,
    required int colorArgb,
    required RoundingRule rounding,
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : uuid = Value(uuid),
       name = Value(name),
       colorArgb = Value(colorArgb),
       rounding = Value(rounding),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<JobRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<int>? colorArgb,
    Expression<String>? rounding,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (colorArgb != null) 'color_argb': colorArgb,
      if (rounding != null) 'rounding': rounding,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  JobsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? name,
    Value<int>? colorArgb,
    Value<RoundingRule>? rounding,
    Value<bool>? archived,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return JobsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      colorArgb: colorArgb ?? this.colorArgb,
      rounding: rounding ?? this.rounding,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorArgb.present) {
      map['color_argb'] = Variable<int>(colorArgb.value);
    }
    if (rounding.present) {
      map['rounding'] = Variable<String>(
        $JobsTable.$converterrounding.toSql(rounding.value),
      );
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('rounding: $rounding, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WageRatesTable extends WageRates
    with TableInfo<$WageRatesTable, WageRateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WageRatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<int> jobId = GeneratedColumn<int>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES jobs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<int> validFrom = GeneratedColumn<int>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _centsPerHourMeta = const VerificationMeta(
    'centsPerHour',
  );
  @override
  late final GeneratedColumn<int> centsPerHour = GeneratedColumn<int>(
    'cents_per_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, jobId, validFrom, centsPerHour];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wage_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<WageRateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('cents_per_hour')) {
      context.handle(
        _centsPerHourMeta,
        centsPerHour.isAcceptableOrUnknown(
          data['cents_per_hour']!,
          _centsPerHourMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_centsPerHourMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WageRateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WageRateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}job_id'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valid_from'],
      )!,
      centsPerHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cents_per_hour'],
      )!,
    );
  }

  @override
  $WageRatesTable createAlias(String alias) {
    return $WageRatesTable(attachedDatabase, alias);
  }
}

class WageRateRow extends DataClass implements Insertable<WageRateRow> {
  final int id;
  final int jobId;

  /// Local date as `yyyymmdd`.
  final int validFrom;
  final int centsPerHour;
  const WageRateRow({
    required this.id,
    required this.jobId,
    required this.validFrom,
    required this.centsPerHour,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['job_id'] = Variable<int>(jobId);
    map['valid_from'] = Variable<int>(validFrom);
    map['cents_per_hour'] = Variable<int>(centsPerHour);
    return map;
  }

  WageRatesCompanion toCompanion(bool nullToAbsent) {
    return WageRatesCompanion(
      id: Value(id),
      jobId: Value(jobId),
      validFrom: Value(validFrom),
      centsPerHour: Value(centsPerHour),
    );
  }

  factory WageRateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WageRateRow(
      id: serializer.fromJson<int>(json['id']),
      jobId: serializer.fromJson<int>(json['jobId']),
      validFrom: serializer.fromJson<int>(json['validFrom']),
      centsPerHour: serializer.fromJson<int>(json['centsPerHour']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jobId': serializer.toJson<int>(jobId),
      'validFrom': serializer.toJson<int>(validFrom),
      'centsPerHour': serializer.toJson<int>(centsPerHour),
    };
  }

  WageRateRow copyWith({
    int? id,
    int? jobId,
    int? validFrom,
    int? centsPerHour,
  }) => WageRateRow(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    validFrom: validFrom ?? this.validFrom,
    centsPerHour: centsPerHour ?? this.centsPerHour,
  );
  WageRateRow copyWithCompanion(WageRatesCompanion data) {
    return WageRateRow(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      centsPerHour: data.centsPerHour.present
          ? data.centsPerHour.value
          : this.centsPerHour,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WageRateRow(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('validFrom: $validFrom, ')
          ..write('centsPerHour: $centsPerHour')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jobId, validFrom, centsPerHour);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WageRateRow &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.validFrom == this.validFrom &&
          other.centsPerHour == this.centsPerHour);
}

class WageRatesCompanion extends UpdateCompanion<WageRateRow> {
  final Value<int> id;
  final Value<int> jobId;
  final Value<int> validFrom;
  final Value<int> centsPerHour;
  const WageRatesCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.centsPerHour = const Value.absent(),
  });
  WageRatesCompanion.insert({
    this.id = const Value.absent(),
    required int jobId,
    required int validFrom,
    required int centsPerHour,
  }) : jobId = Value(jobId),
       validFrom = Value(validFrom),
       centsPerHour = Value(centsPerHour);
  static Insertable<WageRateRow> custom({
    Expression<int>? id,
    Expression<int>? jobId,
    Expression<int>? validFrom,
    Expression<int>? centsPerHour,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (validFrom != null) 'valid_from': validFrom,
      if (centsPerHour != null) 'cents_per_hour': centsPerHour,
    });
  }

  WageRatesCompanion copyWith({
    Value<int>? id,
    Value<int>? jobId,
    Value<int>? validFrom,
    Value<int>? centsPerHour,
  }) {
    return WageRatesCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      validFrom: validFrom ?? this.validFrom,
      centsPerHour: centsPerHour ?? this.centsPerHour,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<int>(jobId.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<int>(validFrom.value);
    }
    if (centsPerHour.present) {
      map['cents_per_hour'] = Variable<int>(centsPerHour.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WageRatesCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('validFrom: $validFrom, ')
          ..write('centsPerHour: $centsPerHour')
          ..write(')'))
        .toString();
  }
}

class $PayoutsTable extends Payouts with TableInfo<$PayoutsTable, PayoutRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PayoutsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<int> jobId = GeneratedColumn<int>(
    'job_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES jobs (id)',
    ),
  );
  static const VerificationMeta _untilDateMeta = const VerificationMeta(
    'untilDate',
  );
  @override
  late final GeneratedColumn<int> untilDate = GeneratedColumn<int>(
    'until_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidOnMeta = const VerificationMeta('paidOn');
  @override
  late final GeneratedColumn<int> paidOn = GeneratedColumn<int>(
    'paid_on',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedCentsMeta = const VerificationMeta(
    'expectedCents',
  );
  @override
  late final GeneratedColumn<int> expectedCents = GeneratedColumn<int>(
    'expected_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedCentsMeta = const VerificationMeta(
    'receivedCents',
  );
  @override
  late final GeneratedColumn<int> receivedCents = GeneratedColumn<int>(
    'received_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    jobId,
    untilDate,
    paidOn,
    expectedCents,
    receivedCents,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PayoutRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    }
    if (data.containsKey('until_date')) {
      context.handle(
        _untilDateMeta,
        untilDate.isAcceptableOrUnknown(data['until_date']!, _untilDateMeta),
      );
    } else if (isInserting) {
      context.missing(_untilDateMeta);
    }
    if (data.containsKey('paid_on')) {
      context.handle(
        _paidOnMeta,
        paidOn.isAcceptableOrUnknown(data['paid_on']!, _paidOnMeta),
      );
    } else if (isInserting) {
      context.missing(_paidOnMeta);
    }
    if (data.containsKey('expected_cents')) {
      context.handle(
        _expectedCentsMeta,
        expectedCents.isAcceptableOrUnknown(
          data['expected_cents']!,
          _expectedCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedCentsMeta);
    }
    if (data.containsKey('received_cents')) {
      context.handle(
        _receivedCentsMeta,
        receivedCents.isAcceptableOrUnknown(
          data['received_cents']!,
          _receivedCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receivedCentsMeta);
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
  PayoutRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PayoutRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}job_id'],
      ),
      untilDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}until_date'],
      )!,
      paidOn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_on'],
      )!,
      expectedCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_cents'],
      )!,
      receivedCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_cents'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PayoutsTable createAlias(String alias) {
    return $PayoutsTable(attachedDatabase, alias);
  }
}

class PayoutRow extends DataClass implements Insertable<PayoutRow> {
  final int id;
  final String uuid;

  /// `null` = all jobs.
  final int? jobId;

  /// Local date as `yyyymmdd`.
  final int untilDate;

  /// Local date as `yyyymmdd`.
  final int paidOn;
  final int expectedCents;
  final int receivedCents;
  final String? note;

  /// UTC epoch ms.
  final int createdAt;
  const PayoutRow({
    required this.id,
    required this.uuid,
    this.jobId,
    required this.untilDate,
    required this.paidOn,
    required this.expectedCents,
    required this.receivedCents,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<int>(jobId);
    }
    map['until_date'] = Variable<int>(untilDate);
    map['paid_on'] = Variable<int>(paidOn);
    map['expected_cents'] = Variable<int>(expectedCents);
    map['received_cents'] = Variable<int>(receivedCents);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PayoutsCompanion toCompanion(bool nullToAbsent) {
    return PayoutsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      jobId: jobId == null && nullToAbsent
          ? const Value.absent()
          : Value(jobId),
      untilDate: Value(untilDate),
      paidOn: Value(paidOn),
      expectedCents: Value(expectedCents),
      receivedCents: Value(receivedCents),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory PayoutRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PayoutRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      jobId: serializer.fromJson<int?>(json['jobId']),
      untilDate: serializer.fromJson<int>(json['untilDate']),
      paidOn: serializer.fromJson<int>(json['paidOn']),
      expectedCents: serializer.fromJson<int>(json['expectedCents']),
      receivedCents: serializer.fromJson<int>(json['receivedCents']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'jobId': serializer.toJson<int?>(jobId),
      'untilDate': serializer.toJson<int>(untilDate),
      'paidOn': serializer.toJson<int>(paidOn),
      'expectedCents': serializer.toJson<int>(expectedCents),
      'receivedCents': serializer.toJson<int>(receivedCents),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PayoutRow copyWith({
    int? id,
    String? uuid,
    Value<int?> jobId = const Value.absent(),
    int? untilDate,
    int? paidOn,
    int? expectedCents,
    int? receivedCents,
    Value<String?> note = const Value.absent(),
    int? createdAt,
  }) => PayoutRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    jobId: jobId.present ? jobId.value : this.jobId,
    untilDate: untilDate ?? this.untilDate,
    paidOn: paidOn ?? this.paidOn,
    expectedCents: expectedCents ?? this.expectedCents,
    receivedCents: receivedCents ?? this.receivedCents,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  PayoutRow copyWithCompanion(PayoutsCompanion data) {
    return PayoutRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      untilDate: data.untilDate.present ? data.untilDate.value : this.untilDate,
      paidOn: data.paidOn.present ? data.paidOn.value : this.paidOn,
      expectedCents: data.expectedCents.present
          ? data.expectedCents.value
          : this.expectedCents,
      receivedCents: data.receivedCents.present
          ? data.receivedCents.value
          : this.receivedCents,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PayoutRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('jobId: $jobId, ')
          ..write('untilDate: $untilDate, ')
          ..write('paidOn: $paidOn, ')
          ..write('expectedCents: $expectedCents, ')
          ..write('receivedCents: $receivedCents, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    jobId,
    untilDate,
    paidOn,
    expectedCents,
    receivedCents,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PayoutRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.jobId == this.jobId &&
          other.untilDate == this.untilDate &&
          other.paidOn == this.paidOn &&
          other.expectedCents == this.expectedCents &&
          other.receivedCents == this.receivedCents &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class PayoutsCompanion extends UpdateCompanion<PayoutRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int?> jobId;
  final Value<int> untilDate;
  final Value<int> paidOn;
  final Value<int> expectedCents;
  final Value<int> receivedCents;
  final Value<String?> note;
  final Value<int> createdAt;
  const PayoutsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.jobId = const Value.absent(),
    this.untilDate = const Value.absent(),
    this.paidOn = const Value.absent(),
    this.expectedCents = const Value.absent(),
    this.receivedCents = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PayoutsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    this.jobId = const Value.absent(),
    required int untilDate,
    required int paidOn,
    required int expectedCents,
    required int receivedCents,
    this.note = const Value.absent(),
    required int createdAt,
  }) : uuid = Value(uuid),
       untilDate = Value(untilDate),
       paidOn = Value(paidOn),
       expectedCents = Value(expectedCents),
       receivedCents = Value(receivedCents),
       createdAt = Value(createdAt);
  static Insertable<PayoutRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? jobId,
    Expression<int>? untilDate,
    Expression<int>? paidOn,
    Expression<int>? expectedCents,
    Expression<int>? receivedCents,
    Expression<String>? note,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (jobId != null) 'job_id': jobId,
      if (untilDate != null) 'until_date': untilDate,
      if (paidOn != null) 'paid_on': paidOn,
      if (expectedCents != null) 'expected_cents': expectedCents,
      if (receivedCents != null) 'received_cents': receivedCents,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PayoutsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int?>? jobId,
    Value<int>? untilDate,
    Value<int>? paidOn,
    Value<int>? expectedCents,
    Value<int>? receivedCents,
    Value<String?>? note,
    Value<int>? createdAt,
  }) {
    return PayoutsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      jobId: jobId ?? this.jobId,
      untilDate: untilDate ?? this.untilDate,
      paidOn: paidOn ?? this.paidOn,
      expectedCents: expectedCents ?? this.expectedCents,
      receivedCents: receivedCents ?? this.receivedCents,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<int>(jobId.value);
    }
    if (untilDate.present) {
      map['until_date'] = Variable<int>(untilDate.value);
    }
    if (paidOn.present) {
      map['paid_on'] = Variable<int>(paidOn.value);
    }
    if (expectedCents.present) {
      map['expected_cents'] = Variable<int>(expectedCents.value);
    }
    if (receivedCents.present) {
      map['received_cents'] = Variable<int>(receivedCents.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PayoutsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('jobId: $jobId, ')
          ..write('untilDate: $untilDate, ')
          ..write('paidOn: $paidOn, ')
          ..write('expectedCents: $expectedCents, ')
          ..write('receivedCents: $receivedCents, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ShiftsTable extends Shifts with TableInfo<$ShiftsTable, ShiftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<int> jobId = GeneratedColumn<int>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES jobs (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ShiftStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ShiftStatus>($ShiftsTable.$converterstatus);
  static const VerificationMeta _startUtcMeta = const VerificationMeta(
    'startUtc',
  );
  @override
  late final GeneratedColumn<int> startUtc = GeneratedColumn<int>(
    'start_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endUtcMeta = const VerificationMeta('endUtc');
  @override
  late final GeneratedColumn<int> endUtc = GeneratedColumn<int>(
    'end_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawStartUtcMeta = const VerificationMeta(
    'rawStartUtc',
  );
  @override
  late final GeneratedColumn<int> rawStartUtc = GeneratedColumn<int>(
    'raw_start_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawEndUtcMeta = const VerificationMeta(
    'rawEndUtc',
  );
  @override
  late final GeneratedColumn<int> rawEndUtc = GeneratedColumn<int>(
    'raw_end_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startOffsetMinMeta = const VerificationMeta(
    'startOffsetMin',
  );
  @override
  late final GeneratedColumn<int> startOffsetMin = GeneratedColumn<int>(
    'start_offset_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endOffsetMinMeta = const VerificationMeta(
    'endOffsetMin',
  );
  @override
  late final GeneratedColumn<int> endOffsetMin = GeneratedColumn<int>(
    'end_offset_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rateCentsPerHourMeta = const VerificationMeta(
    'rateCentsPerHour',
  );
  @override
  late final GeneratedColumn<int> rateCentsPerHour = GeneratedColumn<int>(
    'rate_cents_per_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breakMsMeta = const VerificationMeta(
    'breakMs',
  );
  @override
  late final GeneratedColumn<int> breakMs = GeneratedColumn<int>(
    'break_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pausedAtUtcMeta = const VerificationMeta(
    'pausedAtUtc',
  );
  @override
  late final GeneratedColumn<int> pausedAtUtc = GeneratedColumn<int>(
    'paused_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tipsCentsMeta = const VerificationMeta(
    'tipsCents',
  );
  @override
  late final GeneratedColumn<int> tipsCents = GeneratedColumn<int>(
    'tips_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _paidAtUtcMeta = const VerificationMeta(
    'paidAtUtc',
  );
  @override
  late final GeneratedColumn<int> paidAtUtc = GeneratedColumn<int>(
    'paid_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payoutIdMeta = const VerificationMeta(
    'payoutId',
  );
  @override
  late final GeneratedColumn<int> payoutId = GeneratedColumn<int>(
    'payout_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES payouts (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _legacyIdMeta = const VerificationMeta(
    'legacyId',
  );
  @override
  late final GeneratedColumn<String> legacyId = GeneratedColumn<String>(
    'legacy_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ShiftSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ShiftSource>($ShiftsTable.$convertersource);
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    jobId,
    status,
    startUtc,
    endUtc,
    rawStartUtc,
    rawEndUtc,
    startOffsetMin,
    endOffsetMin,
    rateCentsPerHour,
    breakMs,
    pausedAtUtc,
    tipsCents,
    note,
    paidAtUtc,
    payoutId,
    amountCents,
    legacyId,
    source,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shifts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShiftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('start_utc')) {
      context.handle(
        _startUtcMeta,
        startUtc.isAcceptableOrUnknown(data['start_utc']!, _startUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_startUtcMeta);
    }
    if (data.containsKey('end_utc')) {
      context.handle(
        _endUtcMeta,
        endUtc.isAcceptableOrUnknown(data['end_utc']!, _endUtcMeta),
      );
    }
    if (data.containsKey('raw_start_utc')) {
      context.handle(
        _rawStartUtcMeta,
        rawStartUtc.isAcceptableOrUnknown(
          data['raw_start_utc']!,
          _rawStartUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawStartUtcMeta);
    }
    if (data.containsKey('raw_end_utc')) {
      context.handle(
        _rawEndUtcMeta,
        rawEndUtc.isAcceptableOrUnknown(data['raw_end_utc']!, _rawEndUtcMeta),
      );
    }
    if (data.containsKey('start_offset_min')) {
      context.handle(
        _startOffsetMinMeta,
        startOffsetMin.isAcceptableOrUnknown(
          data['start_offset_min']!,
          _startOffsetMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startOffsetMinMeta);
    }
    if (data.containsKey('end_offset_min')) {
      context.handle(
        _endOffsetMinMeta,
        endOffsetMin.isAcceptableOrUnknown(
          data['end_offset_min']!,
          _endOffsetMinMeta,
        ),
      );
    }
    if (data.containsKey('rate_cents_per_hour')) {
      context.handle(
        _rateCentsPerHourMeta,
        rateCentsPerHour.isAcceptableOrUnknown(
          data['rate_cents_per_hour']!,
          _rateCentsPerHourMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rateCentsPerHourMeta);
    }
    if (data.containsKey('break_ms')) {
      context.handle(
        _breakMsMeta,
        breakMs.isAcceptableOrUnknown(data['break_ms']!, _breakMsMeta),
      );
    }
    if (data.containsKey('paused_at_utc')) {
      context.handle(
        _pausedAtUtcMeta,
        pausedAtUtc.isAcceptableOrUnknown(
          data['paused_at_utc']!,
          _pausedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('tips_cents')) {
      context.handle(
        _tipsCentsMeta,
        tipsCents.isAcceptableOrUnknown(data['tips_cents']!, _tipsCentsMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('paid_at_utc')) {
      context.handle(
        _paidAtUtcMeta,
        paidAtUtc.isAcceptableOrUnknown(data['paid_at_utc']!, _paidAtUtcMeta),
      );
    }
    if (data.containsKey('payout_id')) {
      context.handle(
        _payoutIdMeta,
        payoutId.isAcceptableOrUnknown(data['payout_id']!, _payoutIdMeta),
      );
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    }
    if (data.containsKey('legacy_id')) {
      context.handle(
        _legacyIdMeta,
        legacyId.isAcceptableOrUnknown(data['legacy_id']!, _legacyIdMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}job_id'],
      )!,
      status: $ShiftsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      startUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_utc'],
      )!,
      endUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_utc'],
      ),
      rawStartUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}raw_start_utc'],
      )!,
      rawEndUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}raw_end_utc'],
      ),
      startOffsetMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_offset_min'],
      )!,
      endOffsetMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_offset_min'],
      ),
      rateCentsPerHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_cents_per_hour'],
      )!,
      breakMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}break_ms'],
      )!,
      pausedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_at_utc'],
      ),
      tipsCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tips_cents'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      paidAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_at_utc'],
      ),
      payoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payout_id'],
      ),
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      ),
      legacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_id'],
      ),
      source: $ShiftsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
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
    );
  }

  @override
  $ShiftsTable createAlias(String alias) {
    return $ShiftsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ShiftStatus, String, String> $converterstatus =
      const EnumNameConverter<ShiftStatus>(ShiftStatus.values);
  static JsonTypeConverter2<ShiftSource, String, String> $convertersource =
      const EnumNameConverter<ShiftSource>(ShiftSource.values);
}

class ShiftRow extends DataClass implements Insertable<ShiftRow> {
  final int id;
  final String uuid;
  final int jobId;
  final ShiftStatus status;
  final int startUtc;
  final int? endUtc;
  final int rawStartUtc;
  final int? rawEndUtc;
  final int startOffsetMin;
  final int? endOffsetMin;
  final int rateCentsPerHour;
  final int breakMs;
  final int? pausedAtUtc;
  final int tipsCents;
  final String? note;
  final int? paidAtUtc;
  final int? payoutId;
  final int? amountCents;
  final String? legacyId;
  final ShiftSource source;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const ShiftRow({
    required this.id,
    required this.uuid,
    required this.jobId,
    required this.status,
    required this.startUtc,
    this.endUtc,
    required this.rawStartUtc,
    this.rawEndUtc,
    required this.startOffsetMin,
    this.endOffsetMin,
    required this.rateCentsPerHour,
    required this.breakMs,
    this.pausedAtUtc,
    required this.tipsCents,
    this.note,
    this.paidAtUtc,
    this.payoutId,
    this.amountCents,
    this.legacyId,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['job_id'] = Variable<int>(jobId);
    {
      map['status'] = Variable<String>(
        $ShiftsTable.$converterstatus.toSql(status),
      );
    }
    map['start_utc'] = Variable<int>(startUtc);
    if (!nullToAbsent || endUtc != null) {
      map['end_utc'] = Variable<int>(endUtc);
    }
    map['raw_start_utc'] = Variable<int>(rawStartUtc);
    if (!nullToAbsent || rawEndUtc != null) {
      map['raw_end_utc'] = Variable<int>(rawEndUtc);
    }
    map['start_offset_min'] = Variable<int>(startOffsetMin);
    if (!nullToAbsent || endOffsetMin != null) {
      map['end_offset_min'] = Variable<int>(endOffsetMin);
    }
    map['rate_cents_per_hour'] = Variable<int>(rateCentsPerHour);
    map['break_ms'] = Variable<int>(breakMs);
    if (!nullToAbsent || pausedAtUtc != null) {
      map['paused_at_utc'] = Variable<int>(pausedAtUtc);
    }
    map['tips_cents'] = Variable<int>(tipsCents);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || paidAtUtc != null) {
      map['paid_at_utc'] = Variable<int>(paidAtUtc);
    }
    if (!nullToAbsent || payoutId != null) {
      map['payout_id'] = Variable<int>(payoutId);
    }
    if (!nullToAbsent || amountCents != null) {
      map['amount_cents'] = Variable<int>(amountCents);
    }
    if (!nullToAbsent || legacyId != null) {
      map['legacy_id'] = Variable<String>(legacyId);
    }
    {
      map['source'] = Variable<String>(
        $ShiftsTable.$convertersource.toSql(source),
      );
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  ShiftsCompanion toCompanion(bool nullToAbsent) {
    return ShiftsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      jobId: Value(jobId),
      status: Value(status),
      startUtc: Value(startUtc),
      endUtc: endUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(endUtc),
      rawStartUtc: Value(rawStartUtc),
      rawEndUtc: rawEndUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(rawEndUtc),
      startOffsetMin: Value(startOffsetMin),
      endOffsetMin: endOffsetMin == null && nullToAbsent
          ? const Value.absent()
          : Value(endOffsetMin),
      rateCentsPerHour: Value(rateCentsPerHour),
      breakMs: Value(breakMs),
      pausedAtUtc: pausedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAtUtc),
      tipsCents: Value(tipsCents),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      paidAtUtc: paidAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(paidAtUtc),
      payoutId: payoutId == null && nullToAbsent
          ? const Value.absent()
          : Value(payoutId),
      amountCents: amountCents == null && nullToAbsent
          ? const Value.absent()
          : Value(amountCents),
      legacyId: legacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyId),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ShiftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      jobId: serializer.fromJson<int>(json['jobId']),
      status: $ShiftsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      startUtc: serializer.fromJson<int>(json['startUtc']),
      endUtc: serializer.fromJson<int?>(json['endUtc']),
      rawStartUtc: serializer.fromJson<int>(json['rawStartUtc']),
      rawEndUtc: serializer.fromJson<int?>(json['rawEndUtc']),
      startOffsetMin: serializer.fromJson<int>(json['startOffsetMin']),
      endOffsetMin: serializer.fromJson<int?>(json['endOffsetMin']),
      rateCentsPerHour: serializer.fromJson<int>(json['rateCentsPerHour']),
      breakMs: serializer.fromJson<int>(json['breakMs']),
      pausedAtUtc: serializer.fromJson<int?>(json['pausedAtUtc']),
      tipsCents: serializer.fromJson<int>(json['tipsCents']),
      note: serializer.fromJson<String?>(json['note']),
      paidAtUtc: serializer.fromJson<int?>(json['paidAtUtc']),
      payoutId: serializer.fromJson<int?>(json['payoutId']),
      amountCents: serializer.fromJson<int?>(json['amountCents']),
      legacyId: serializer.fromJson<String?>(json['legacyId']),
      source: $ShiftsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'jobId': serializer.toJson<int>(jobId),
      'status': serializer.toJson<String>(
        $ShiftsTable.$converterstatus.toJson(status),
      ),
      'startUtc': serializer.toJson<int>(startUtc),
      'endUtc': serializer.toJson<int?>(endUtc),
      'rawStartUtc': serializer.toJson<int>(rawStartUtc),
      'rawEndUtc': serializer.toJson<int?>(rawEndUtc),
      'startOffsetMin': serializer.toJson<int>(startOffsetMin),
      'endOffsetMin': serializer.toJson<int?>(endOffsetMin),
      'rateCentsPerHour': serializer.toJson<int>(rateCentsPerHour),
      'breakMs': serializer.toJson<int>(breakMs),
      'pausedAtUtc': serializer.toJson<int?>(pausedAtUtc),
      'tipsCents': serializer.toJson<int>(tipsCents),
      'note': serializer.toJson<String?>(note),
      'paidAtUtc': serializer.toJson<int?>(paidAtUtc),
      'payoutId': serializer.toJson<int?>(payoutId),
      'amountCents': serializer.toJson<int?>(amountCents),
      'legacyId': serializer.toJson<String?>(legacyId),
      'source': serializer.toJson<String>(
        $ShiftsTable.$convertersource.toJson(source),
      ),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  ShiftRow copyWith({
    int? id,
    String? uuid,
    int? jobId,
    ShiftStatus? status,
    int? startUtc,
    Value<int?> endUtc = const Value.absent(),
    int? rawStartUtc,
    Value<int?> rawEndUtc = const Value.absent(),
    int? startOffsetMin,
    Value<int?> endOffsetMin = const Value.absent(),
    int? rateCentsPerHour,
    int? breakMs,
    Value<int?> pausedAtUtc = const Value.absent(),
    int? tipsCents,
    Value<String?> note = const Value.absent(),
    Value<int?> paidAtUtc = const Value.absent(),
    Value<int?> payoutId = const Value.absent(),
    Value<int?> amountCents = const Value.absent(),
    Value<String?> legacyId = const Value.absent(),
    ShiftSource? source,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => ShiftRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    jobId: jobId ?? this.jobId,
    status: status ?? this.status,
    startUtc: startUtc ?? this.startUtc,
    endUtc: endUtc.present ? endUtc.value : this.endUtc,
    rawStartUtc: rawStartUtc ?? this.rawStartUtc,
    rawEndUtc: rawEndUtc.present ? rawEndUtc.value : this.rawEndUtc,
    startOffsetMin: startOffsetMin ?? this.startOffsetMin,
    endOffsetMin: endOffsetMin.present ? endOffsetMin.value : this.endOffsetMin,
    rateCentsPerHour: rateCentsPerHour ?? this.rateCentsPerHour,
    breakMs: breakMs ?? this.breakMs,
    pausedAtUtc: pausedAtUtc.present ? pausedAtUtc.value : this.pausedAtUtc,
    tipsCents: tipsCents ?? this.tipsCents,
    note: note.present ? note.value : this.note,
    paidAtUtc: paidAtUtc.present ? paidAtUtc.value : this.paidAtUtc,
    payoutId: payoutId.present ? payoutId.value : this.payoutId,
    amountCents: amountCents.present ? amountCents.value : this.amountCents,
    legacyId: legacyId.present ? legacyId.value : this.legacyId,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ShiftRow copyWithCompanion(ShiftsCompanion data) {
    return ShiftRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      status: data.status.present ? data.status.value : this.status,
      startUtc: data.startUtc.present ? data.startUtc.value : this.startUtc,
      endUtc: data.endUtc.present ? data.endUtc.value : this.endUtc,
      rawStartUtc: data.rawStartUtc.present
          ? data.rawStartUtc.value
          : this.rawStartUtc,
      rawEndUtc: data.rawEndUtc.present ? data.rawEndUtc.value : this.rawEndUtc,
      startOffsetMin: data.startOffsetMin.present
          ? data.startOffsetMin.value
          : this.startOffsetMin,
      endOffsetMin: data.endOffsetMin.present
          ? data.endOffsetMin.value
          : this.endOffsetMin,
      rateCentsPerHour: data.rateCentsPerHour.present
          ? data.rateCentsPerHour.value
          : this.rateCentsPerHour,
      breakMs: data.breakMs.present ? data.breakMs.value : this.breakMs,
      pausedAtUtc: data.pausedAtUtc.present
          ? data.pausedAtUtc.value
          : this.pausedAtUtc,
      tipsCents: data.tipsCents.present ? data.tipsCents.value : this.tipsCents,
      note: data.note.present ? data.note.value : this.note,
      paidAtUtc: data.paidAtUtc.present ? data.paidAtUtc.value : this.paidAtUtc,
      payoutId: data.payoutId.present ? data.payoutId.value : this.payoutId,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      legacyId: data.legacyId.present ? data.legacyId.value : this.legacyId,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('jobId: $jobId, ')
          ..write('status: $status, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('rawStartUtc: $rawStartUtc, ')
          ..write('rawEndUtc: $rawEndUtc, ')
          ..write('startOffsetMin: $startOffsetMin, ')
          ..write('endOffsetMin: $endOffsetMin, ')
          ..write('rateCentsPerHour: $rateCentsPerHour, ')
          ..write('breakMs: $breakMs, ')
          ..write('pausedAtUtc: $pausedAtUtc, ')
          ..write('tipsCents: $tipsCents, ')
          ..write('note: $note, ')
          ..write('paidAtUtc: $paidAtUtc, ')
          ..write('payoutId: $payoutId, ')
          ..write('amountCents: $amountCents, ')
          ..write('legacyId: $legacyId, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    uuid,
    jobId,
    status,
    startUtc,
    endUtc,
    rawStartUtc,
    rawEndUtc,
    startOffsetMin,
    endOffsetMin,
    rateCentsPerHour,
    breakMs,
    pausedAtUtc,
    tipsCents,
    note,
    paidAtUtc,
    payoutId,
    amountCents,
    legacyId,
    source,
    createdAt,
    updatedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.jobId == this.jobId &&
          other.status == this.status &&
          other.startUtc == this.startUtc &&
          other.endUtc == this.endUtc &&
          other.rawStartUtc == this.rawStartUtc &&
          other.rawEndUtc == this.rawEndUtc &&
          other.startOffsetMin == this.startOffsetMin &&
          other.endOffsetMin == this.endOffsetMin &&
          other.rateCentsPerHour == this.rateCentsPerHour &&
          other.breakMs == this.breakMs &&
          other.pausedAtUtc == this.pausedAtUtc &&
          other.tipsCents == this.tipsCents &&
          other.note == this.note &&
          other.paidAtUtc == this.paidAtUtc &&
          other.payoutId == this.payoutId &&
          other.amountCents == this.amountCents &&
          other.legacyId == this.legacyId &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ShiftsCompanion extends UpdateCompanion<ShiftRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> jobId;
  final Value<ShiftStatus> status;
  final Value<int> startUtc;
  final Value<int?> endUtc;
  final Value<int> rawStartUtc;
  final Value<int?> rawEndUtc;
  final Value<int> startOffsetMin;
  final Value<int?> endOffsetMin;
  final Value<int> rateCentsPerHour;
  final Value<int> breakMs;
  final Value<int?> pausedAtUtc;
  final Value<int> tipsCents;
  final Value<String?> note;
  final Value<int?> paidAtUtc;
  final Value<int?> payoutId;
  final Value<int?> amountCents;
  final Value<String?> legacyId;
  final Value<ShiftSource> source;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  const ShiftsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.jobId = const Value.absent(),
    this.status = const Value.absent(),
    this.startUtc = const Value.absent(),
    this.endUtc = const Value.absent(),
    this.rawStartUtc = const Value.absent(),
    this.rawEndUtc = const Value.absent(),
    this.startOffsetMin = const Value.absent(),
    this.endOffsetMin = const Value.absent(),
    this.rateCentsPerHour = const Value.absent(),
    this.breakMs = const Value.absent(),
    this.pausedAtUtc = const Value.absent(),
    this.tipsCents = const Value.absent(),
    this.note = const Value.absent(),
    this.paidAtUtc = const Value.absent(),
    this.payoutId = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  ShiftsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int jobId,
    required ShiftStatus status,
    required int startUtc,
    this.endUtc = const Value.absent(),
    required int rawStartUtc,
    this.rawEndUtc = const Value.absent(),
    required int startOffsetMin,
    this.endOffsetMin = const Value.absent(),
    required int rateCentsPerHour,
    this.breakMs = const Value.absent(),
    this.pausedAtUtc = const Value.absent(),
    this.tipsCents = const Value.absent(),
    this.note = const Value.absent(),
    this.paidAtUtc = const Value.absent(),
    this.payoutId = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.legacyId = const Value.absent(),
    required ShiftSource source,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       jobId = Value(jobId),
       status = Value(status),
       startUtc = Value(startUtc),
       rawStartUtc = Value(rawStartUtc),
       startOffsetMin = Value(startOffsetMin),
       rateCentsPerHour = Value(rateCentsPerHour),
       source = Value(source),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ShiftRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? jobId,
    Expression<String>? status,
    Expression<int>? startUtc,
    Expression<int>? endUtc,
    Expression<int>? rawStartUtc,
    Expression<int>? rawEndUtc,
    Expression<int>? startOffsetMin,
    Expression<int>? endOffsetMin,
    Expression<int>? rateCentsPerHour,
    Expression<int>? breakMs,
    Expression<int>? pausedAtUtc,
    Expression<int>? tipsCents,
    Expression<String>? note,
    Expression<int>? paidAtUtc,
    Expression<int>? payoutId,
    Expression<int>? amountCents,
    Expression<String>? legacyId,
    Expression<String>? source,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (jobId != null) 'job_id': jobId,
      if (status != null) 'status': status,
      if (startUtc != null) 'start_utc': startUtc,
      if (endUtc != null) 'end_utc': endUtc,
      if (rawStartUtc != null) 'raw_start_utc': rawStartUtc,
      if (rawEndUtc != null) 'raw_end_utc': rawEndUtc,
      if (startOffsetMin != null) 'start_offset_min': startOffsetMin,
      if (endOffsetMin != null) 'end_offset_min': endOffsetMin,
      if (rateCentsPerHour != null) 'rate_cents_per_hour': rateCentsPerHour,
      if (breakMs != null) 'break_ms': breakMs,
      if (pausedAtUtc != null) 'paused_at_utc': pausedAtUtc,
      if (tipsCents != null) 'tips_cents': tipsCents,
      if (note != null) 'note': note,
      if (paidAtUtc != null) 'paid_at_utc': paidAtUtc,
      if (payoutId != null) 'payout_id': payoutId,
      if (amountCents != null) 'amount_cents': amountCents,
      if (legacyId != null) 'legacy_id': legacyId,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  ShiftsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? jobId,
    Value<ShiftStatus>? status,
    Value<int>? startUtc,
    Value<int?>? endUtc,
    Value<int>? rawStartUtc,
    Value<int?>? rawEndUtc,
    Value<int>? startOffsetMin,
    Value<int?>? endOffsetMin,
    Value<int>? rateCentsPerHour,
    Value<int>? breakMs,
    Value<int?>? pausedAtUtc,
    Value<int>? tipsCents,
    Value<String?>? note,
    Value<int?>? paidAtUtc,
    Value<int?>? payoutId,
    Value<int?>? amountCents,
    Value<String?>? legacyId,
    Value<ShiftSource>? source,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
  }) {
    return ShiftsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
      rawStartUtc: rawStartUtc ?? this.rawStartUtc,
      rawEndUtc: rawEndUtc ?? this.rawEndUtc,
      startOffsetMin: startOffsetMin ?? this.startOffsetMin,
      endOffsetMin: endOffsetMin ?? this.endOffsetMin,
      rateCentsPerHour: rateCentsPerHour ?? this.rateCentsPerHour,
      breakMs: breakMs ?? this.breakMs,
      pausedAtUtc: pausedAtUtc ?? this.pausedAtUtc,
      tipsCents: tipsCents ?? this.tipsCents,
      note: note ?? this.note,
      paidAtUtc: paidAtUtc ?? this.paidAtUtc,
      payoutId: payoutId ?? this.payoutId,
      amountCents: amountCents ?? this.amountCents,
      legacyId: legacyId ?? this.legacyId,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<int>(jobId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ShiftsTable.$converterstatus.toSql(status.value),
      );
    }
    if (startUtc.present) {
      map['start_utc'] = Variable<int>(startUtc.value);
    }
    if (endUtc.present) {
      map['end_utc'] = Variable<int>(endUtc.value);
    }
    if (rawStartUtc.present) {
      map['raw_start_utc'] = Variable<int>(rawStartUtc.value);
    }
    if (rawEndUtc.present) {
      map['raw_end_utc'] = Variable<int>(rawEndUtc.value);
    }
    if (startOffsetMin.present) {
      map['start_offset_min'] = Variable<int>(startOffsetMin.value);
    }
    if (endOffsetMin.present) {
      map['end_offset_min'] = Variable<int>(endOffsetMin.value);
    }
    if (rateCentsPerHour.present) {
      map['rate_cents_per_hour'] = Variable<int>(rateCentsPerHour.value);
    }
    if (breakMs.present) {
      map['break_ms'] = Variable<int>(breakMs.value);
    }
    if (pausedAtUtc.present) {
      map['paused_at_utc'] = Variable<int>(pausedAtUtc.value);
    }
    if (tipsCents.present) {
      map['tips_cents'] = Variable<int>(tipsCents.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (paidAtUtc.present) {
      map['paid_at_utc'] = Variable<int>(paidAtUtc.value);
    }
    if (payoutId.present) {
      map['payout_id'] = Variable<int>(payoutId.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (legacyId.present) {
      map['legacy_id'] = Variable<String>(legacyId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $ShiftsTable.$convertersource.toSql(source.value),
      );
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('jobId: $jobId, ')
          ..write('status: $status, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('rawStartUtc: $rawStartUtc, ')
          ..write('rawEndUtc: $rawEndUtc, ')
          ..write('startOffsetMin: $startOffsetMin, ')
          ..write('endOffsetMin: $endOffsetMin, ')
          ..write('rateCentsPerHour: $rateCentsPerHour, ')
          ..write('breakMs: $breakMs, ')
          ..write('pausedAtUtc: $pausedAtUtc, ')
          ..write('tipsCents: $tipsCents, ')
          ..write('note: $note, ')
          ..write('paidAtUtc: $paidAtUtc, ')
          ..write('payoutId: $payoutId, ')
          ..write('amountCents: $amountCents, ')
          ..write('legacyId: $legacyId, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $MetaTable extends Meta with TableInfo<$MetaTable, MetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaTable(this.attachedDatabase, [this._alias]);
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MetaTable createAlias(String alias) {
    return $MetaTable(attachedDatabase, alias);
  }
}

class MetaRow extends DataClass implements Insertable<MetaRow> {
  final String key;
  final String value;
  const MetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaCompanion toCompanion(bool nullToAbsent) {
    return MetaCompanion(key: Value(key), value: Value(value));
  }

  factory MetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaRow copyWith({String? key, String? value}) =>
      MetaRow(key: key ?? this.key, value: value ?? this.value);
  MetaRow copyWithCompanion(MetaCompanion data) {
    return MetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaRow && other.key == this.key && other.value == this.value);
}

class MetaCompanion extends UpdateCompanion<MetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewItemsTable extends ReviewItems
    with TableInfo<$ReviewItemsTable, ReviewItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<int> shiftId = GeneratedColumn<int>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shifts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _reasonsMeta = const VerificationMeta(
    'reasons',
  );
  @override
  late final GeneratedColumn<String> reasons = GeneratedColumn<String>(
    'reasons',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relatedMeta = const VerificationMeta(
    'related',
  );
  @override
  late final GeneratedColumn<String> related = GeneratedColumn<String>(
    'related',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [shiftId, reasons, related];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    }
    if (data.containsKey('reasons')) {
      context.handle(
        _reasonsMeta,
        reasons.isAcceptableOrUnknown(data['reasons']!, _reasonsMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonsMeta);
    }
    if (data.containsKey('related')) {
      context.handle(
        _relatedMeta,
        related.isAcceptableOrUnknown(data['related']!, _relatedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shiftId};
  @override
  ReviewItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewItemRow(
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shift_id'],
      )!,
      reasons: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasons'],
      )!,
      related: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related'],
      )!,
    );
  }

  @override
  $ReviewItemsTable createAlias(String alias) {
    return $ReviewItemsTable(attachedDatabase, alias);
  }
}

class ReviewItemRow extends DataClass implements Insertable<ReviewItemRow> {
  final int shiftId;

  /// Comma-separated `ReviewReason` names.
  final String reasons;

  /// Comma-separated related shift ids.
  final String related;
  const ReviewItemRow({
    required this.shiftId,
    required this.reasons,
    required this.related,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shift_id'] = Variable<int>(shiftId);
    map['reasons'] = Variable<String>(reasons);
    map['related'] = Variable<String>(related);
    return map;
  }

  ReviewItemsCompanion toCompanion(bool nullToAbsent) {
    return ReviewItemsCompanion(
      shiftId: Value(shiftId),
      reasons: Value(reasons),
      related: Value(related),
    );
  }

  factory ReviewItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewItemRow(
      shiftId: serializer.fromJson<int>(json['shiftId']),
      reasons: serializer.fromJson<String>(json['reasons']),
      related: serializer.fromJson<String>(json['related']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shiftId': serializer.toJson<int>(shiftId),
      'reasons': serializer.toJson<String>(reasons),
      'related': serializer.toJson<String>(related),
    };
  }

  ReviewItemRow copyWith({int? shiftId, String? reasons, String? related}) =>
      ReviewItemRow(
        shiftId: shiftId ?? this.shiftId,
        reasons: reasons ?? this.reasons,
        related: related ?? this.related,
      );
  ReviewItemRow copyWithCompanion(ReviewItemsCompanion data) {
    return ReviewItemRow(
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      reasons: data.reasons.present ? data.reasons.value : this.reasons,
      related: data.related.present ? data.related.value : this.related,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewItemRow(')
          ..write('shiftId: $shiftId, ')
          ..write('reasons: $reasons, ')
          ..write('related: $related')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(shiftId, reasons, related);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewItemRow &&
          other.shiftId == this.shiftId &&
          other.reasons == this.reasons &&
          other.related == this.related);
}

class ReviewItemsCompanion extends UpdateCompanion<ReviewItemRow> {
  final Value<int> shiftId;
  final Value<String> reasons;
  final Value<String> related;
  const ReviewItemsCompanion({
    this.shiftId = const Value.absent(),
    this.reasons = const Value.absent(),
    this.related = const Value.absent(),
  });
  ReviewItemsCompanion.insert({
    this.shiftId = const Value.absent(),
    required String reasons,
    this.related = const Value.absent(),
  }) : reasons = Value(reasons);
  static Insertable<ReviewItemRow> custom({
    Expression<int>? shiftId,
    Expression<String>? reasons,
    Expression<String>? related,
  }) {
    return RawValuesInsertable({
      if (shiftId != null) 'shift_id': shiftId,
      if (reasons != null) 'reasons': reasons,
      if (related != null) 'related': related,
    });
  }

  ReviewItemsCompanion copyWith({
    Value<int>? shiftId,
    Value<String>? reasons,
    Value<String>? related,
  }) {
    return ReviewItemsCompanion(
      shiftId: shiftId ?? this.shiftId,
      reasons: reasons ?? this.reasons,
      related: related ?? this.related,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shiftId.present) {
      map['shift_id'] = Variable<int>(shiftId.value);
    }
    if (reasons.present) {
      map['reasons'] = Variable<String>(reasons.value);
    }
    if (related.present) {
      map['related'] = Variable<String>(related.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewItemsCompanion(')
          ..write('shiftId: $shiftId, ')
          ..write('reasons: $reasons, ')
          ..write('related: $related')
          ..write(')'))
        .toString();
  }
}

class $LegacyErrorsTable extends LegacyErrors
    with TableInfo<$LegacyErrorsTable, LegacyErrorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LegacyErrorsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawMeta = const VerificationMeta('raw');
  @override
  late final GeneratedColumn<String> raw = GeneratedColumn<String>(
    'raw',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    origin,
    raw,
    code,
    message,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'legacy_errors';
  @override
  VerificationContext validateIntegrity(
    Insertable<LegacyErrorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('raw')) {
      context.handle(
        _rawMeta,
        raw.isAcceptableOrUnknown(data['raw']!, _rawMeta),
      );
    } else if (isInserting) {
      context.missing(_rawMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
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
  LegacyErrorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LegacyErrorRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      raw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LegacyErrorsTable createAlias(String alias) {
    return $LegacyErrorsTable(attachedDatabase, alias);
  }
}

class LegacyErrorRow extends DataClass implements Insertable<LegacyErrorRow> {
  final int id;

  /// Where the value came from, e.g. `work_entries[3]` or `active_session`.
  final String origin;

  /// The raw value (JSON-encoded when it was not a string).
  final String raw;

  /// Machine-readable error code (`LegacyErrorCode` name).
  final String code;

  /// Diagnostic detail (exception text), not shown to users directly.
  final String? message;

  /// UTC epoch ms.
  final int createdAt;
  const LegacyErrorRow({
    required this.id,
    required this.origin,
    required this.raw,
    required this.code,
    this.message,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['origin'] = Variable<String>(origin);
    map['raw'] = Variable<String>(raw);
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  LegacyErrorsCompanion toCompanion(bool nullToAbsent) {
    return LegacyErrorsCompanion(
      id: Value(id),
      origin: Value(origin),
      raw: Value(raw),
      code: Value(code),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      createdAt: Value(createdAt),
    );
  }

  factory LegacyErrorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegacyErrorRow(
      id: serializer.fromJson<int>(json['id']),
      origin: serializer.fromJson<String>(json['origin']),
      raw: serializer.fromJson<String>(json['raw']),
      code: serializer.fromJson<String>(json['code']),
      message: serializer.fromJson<String?>(json['message']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'origin': serializer.toJson<String>(origin),
      'raw': serializer.toJson<String>(raw),
      'code': serializer.toJson<String>(code),
      'message': serializer.toJson<String?>(message),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  LegacyErrorRow copyWith({
    int? id,
    String? origin,
    String? raw,
    String? code,
    Value<String?> message = const Value.absent(),
    int? createdAt,
  }) => LegacyErrorRow(
    id: id ?? this.id,
    origin: origin ?? this.origin,
    raw: raw ?? this.raw,
    code: code ?? this.code,
    message: message.present ? message.value : this.message,
    createdAt: createdAt ?? this.createdAt,
  );
  LegacyErrorRow copyWithCompanion(LegacyErrorsCompanion data) {
    return LegacyErrorRow(
      id: data.id.present ? data.id.value : this.id,
      origin: data.origin.present ? data.origin.value : this.origin,
      raw: data.raw.present ? data.raw.value : this.raw,
      code: data.code.present ? data.code.value : this.code,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LegacyErrorRow(')
          ..write('id: $id, ')
          ..write('origin: $origin, ')
          ..write('raw: $raw, ')
          ..write('code: $code, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, origin, raw, code, message, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LegacyErrorRow &&
          other.id == this.id &&
          other.origin == this.origin &&
          other.raw == this.raw &&
          other.code == this.code &&
          other.message == this.message &&
          other.createdAt == this.createdAt);
}

class LegacyErrorsCompanion extends UpdateCompanion<LegacyErrorRow> {
  final Value<int> id;
  final Value<String> origin;
  final Value<String> raw;
  final Value<String> code;
  final Value<String?> message;
  final Value<int> createdAt;
  const LegacyErrorsCompanion({
    this.id = const Value.absent(),
    this.origin = const Value.absent(),
    this.raw = const Value.absent(),
    this.code = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LegacyErrorsCompanion.insert({
    this.id = const Value.absent(),
    required String origin,
    required String raw,
    required String code,
    this.message = const Value.absent(),
    required int createdAt,
  }) : origin = Value(origin),
       raw = Value(raw),
       code = Value(code),
       createdAt = Value(createdAt);
  static Insertable<LegacyErrorRow> custom({
    Expression<int>? id,
    Expression<String>? origin,
    Expression<String>? raw,
    Expression<String>? code,
    Expression<String>? message,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (origin != null) 'origin': origin,
      if (raw != null) 'raw': raw,
      if (code != null) 'code': code,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LegacyErrorsCompanion copyWith({
    Value<int>? id,
    Value<String>? origin,
    Value<String>? raw,
    Value<String>? code,
    Value<String?>? message,
    Value<int>? createdAt,
  }) {
    return LegacyErrorsCompanion(
      id: id ?? this.id,
      origin: origin ?? this.origin,
      raw: raw ?? this.raw,
      code: code ?? this.code,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (raw.present) {
      map['raw'] = Variable<String>(raw.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LegacyErrorsCompanion(')
          ..write('id: $id, ')
          ..write('origin: $origin, ')
          ..write('raw: $raw, ')
          ..write('code: $code, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $JobsTable jobs = $JobsTable(this);
  late final $WageRatesTable wageRates = $WageRatesTable(this);
  late final $PayoutsTable payouts = $PayoutsTable(this);
  late final $ShiftsTable shifts = $ShiftsTable(this);
  late final $MetaTable meta = $MetaTable(this);
  late final $ReviewItemsTable reviewItems = $ReviewItemsTable(this);
  late final $LegacyErrorsTable legacyErrors = $LegacyErrorsTable(this);
  late final Index wageRatesJobValidFrom = Index(
    'wage_rates_job_valid_from',
    'CREATE UNIQUE INDEX wage_rates_job_valid_from ON wage_rates (job_id, valid_from)',
  );
  late final Index shiftsStart = Index(
    'shifts_start',
    'CREATE INDEX shifts_start ON shifts (start_utc)',
  );
  late final Index shiftsJobStart = Index(
    'shifts_job_start',
    'CREATE INDEX shifts_job_start ON shifts (job_id, start_utc)',
  );
  late final Index shiftsPayout = Index(
    'shifts_payout',
    'CREATE INDEX shifts_payout ON shifts (payout_id)',
  );
  late final Index shiftsStatus = Index(
    'shifts_status',
    'CREATE INDEX shifts_status ON shifts (status)',
  );
  late final Index shiftsOneRunning = Index(
    'shifts_one_running',
    'CREATE UNIQUE INDEX shifts_one_running ON shifts (status) WHERE status = \'running\' AND deleted_at IS NULL',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    jobs,
    wageRates,
    payouts,
    shifts,
    meta,
    reviewItems,
    legacyErrors,
    wageRatesJobValidFrom,
    shiftsStart,
    shiftsJobStart,
    shiftsPayout,
    shiftsStatus,
    shiftsOneRunning,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'jobs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('wage_rates', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'payouts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('shifts', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'shifts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('review_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$JobsTableCreateCompanionBuilder = JobsCompanion Function({
  Value<int> id,
  required String uuid,
  required String name,
  required int colorArgb,
  required RoundingRule rounding,
  Value<bool> archived,
  Value<int> sortOrder,
  required int createdAt,
  required int updatedAt,
});
typedef $$JobsTableUpdateCompanionBuilder = JobsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> name,
  Value<int> colorArgb,
  Value<RoundingRule> rounding,
  Value<bool> archived,
  Value<int> sortOrder,
  Value<int> createdAt,
  Value<int> updatedAt,
});

final class $$JobsTableReferences
    extends BaseReferences<_$AppDatabase, $JobsTable, JobRow> {
  $$JobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WageRatesTable, List<WageRateRow>>
  _wageRatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wageRates,
    aliasName: 'jobs__id__wage_rates__job_id',
  );

  $$WageRatesTableProcessedTableManager get wageRatesRefs {
    final manager = $$WageRatesTableTableManager(
      $_db,
      $_db.wageRates,
    ).filter((f) => f.jobId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wageRatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PayoutsTable, List<PayoutRow>> _payoutsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.payouts,
    aliasName: 'jobs__id__payouts__job_id',
  );

  $$PayoutsTableProcessedTableManager get payoutsRefs {
    final manager = $$PayoutsTableTableManager(
      $_db,
      $_db.payouts,
    ).filter((f) => f.jobId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_payoutsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShiftsTable, List<ShiftRow>> _shiftsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.shifts,
    aliasName: 'jobs__id__shifts__job_id',
  );

  $$ShiftsTableProcessedTableManager get shiftsRefs {
    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.jobId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_shiftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$JobsTableFilterComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorArgb => $composableBuilder(
    column: $table.colorArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RoundingRule, RoundingRule, String>
  get rounding => $composableBuilder(
    column: $table.rounding,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
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

  Expression<bool> wageRatesRefs(
    Expression<bool> Function($$WageRatesTableFilterComposer f) f,
  ) {
    final $$WageRatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wageRates,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WageRatesTableFilterComposer(
            $db: $db,
            $table: $db.wageRates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> payoutsRefs(
    Expression<bool> Function($$PayoutsTableFilterComposer f) f,
  ) {
    final $$PayoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payouts,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayoutsTableFilterComposer(
            $db: $db,
            $table: $db.payouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shiftsRefs(
    Expression<bool> Function($$ShiftsTableFilterComposer f) f,
  ) {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JobsTableOrderingComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorArgb => $composableBuilder(
    column: $table.colorArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rounding => $composableBuilder(
    column: $table.rounding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
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
}

class $$JobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RoundingRule, String> get rounding =>
      $composableBuilder(column: $table.rounding, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> wageRatesRefs<T extends Object>(
    Expression<T> Function($$WageRatesTableAnnotationComposer a) f,
  ) {
    final $$WageRatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wageRates,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WageRatesTableAnnotationComposer(
            $db: $db,
            $table: $db.wageRates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> payoutsRefs<T extends Object>(
    Expression<T> Function($$PayoutsTableAnnotationComposer a) f,
  ) {
    final $$PayoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payouts,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.payouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shiftsRefs<T extends Object>(
    Expression<T> Function($$ShiftsTableAnnotationComposer a) f,
  ) {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobsTable,
          JobRow,
          $$JobsTableFilterComposer,
          $$JobsTableOrderingComposer,
          $$JobsTableAnnotationComposer,
          $$JobsTableCreateCompanionBuilder,
          $$JobsTableUpdateCompanionBuilder,
          (JobRow, $$JobsTableReferences),
          JobRow,
          PrefetchHooks Function({
            bool wageRatesRefs,
            bool payoutsRefs,
            bool shiftsRefs,
          })
        > {
  $$JobsTableTableManager(_$AppDatabase db, $JobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorArgb = const Value.absent(),
                Value<RoundingRule> rounding = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => JobsCompanion(
                id: id,
                uuid: uuid,
                name: name,
                colorArgb: colorArgb,
                rounding: rounding,
                archived: archived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String name,
                required int colorArgb,
                required RoundingRule rounding,
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => JobsCompanion.insert(
                id: id,
                uuid: uuid,
                name: name,
                colorArgb: colorArgb,
                rounding: rounding,
                archived: archived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobsTable, JobRow>(table),
                  $$JobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                wageRatesRefs = false,
                payoutsRefs = false,
                shiftsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (wageRatesRefs) db.wageRates,
                    if (payoutsRefs) db.payouts,
                    if (shiftsRefs) db.shifts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (wageRatesRefs)
                        await $_getPrefetchedData<
                          JobRow,
                          $JobsTable,
                          WageRateRow
                        >(
                          currentTable: table,
                          referencedTable: $$JobsTableReferences
                              ._wageRatesRefsTable(db),
                          managerFromTypedResult: (p0) => $$JobsTableReferences(
                            db,
                            table,
                            p0,
                          ).wageRatesRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.jobId == item.id),
                          typedResults: items,
                        ),
                      if (payoutsRefs)
                        await $_getPrefetchedData<
                          JobRow,
                          $JobsTable,
                          PayoutRow
                        >(
                          currentTable: table,
                          referencedTable: $$JobsTableReferences
                              ._payoutsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$JobsTableReferences(db, table, p0).payoutsRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.jobId == item.id),
                          typedResults: items,
                        ),
                      if (shiftsRefs)
                        await $_getPrefetchedData<JobRow, $JobsTable, ShiftRow>(
                          currentTable: table,
                          referencedTable: $$JobsTableReferences
                              ._shiftsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$JobsTableReferences(db, table, p0).shiftsRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.jobId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$JobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobsTable,
      JobRow,
      $$JobsTableFilterComposer,
      $$JobsTableOrderingComposer,
      $$JobsTableAnnotationComposer,
      $$JobsTableCreateCompanionBuilder,
      $$JobsTableUpdateCompanionBuilder,
      (JobRow, $$JobsTableReferences),
      JobRow,
      PrefetchHooks Function({
        bool wageRatesRefs,
        bool payoutsRefs,
        bool shiftsRefs,
      })
    >;
typedef $$WageRatesTableCreateCompanionBuilder = WageRatesCompanion Function({
  Value<int> id,
  required int jobId,
  required int validFrom,
  required int centsPerHour,
});
typedef $$WageRatesTableUpdateCompanionBuilder = WageRatesCompanion Function({
  Value<int> id,
  Value<int> jobId,
  Value<int> validFrom,
  Value<int> centsPerHour,
});

final class $$WageRatesTableReferences
    extends BaseReferences<_$AppDatabase, $WageRatesTable, WageRateRow> {
  $$WageRatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $JobsTable _jobIdTable(_$AppDatabase db) =>
      db.jobs.createAlias('wage_rates__job_id__jobs__id');

  $$JobsTableProcessedTableManager get jobId {
    final $_column = $_itemColumn<int>('job_id')!;

    final manager = $$JobsTableTableManager(
      $_db,
      $_db.jobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_jobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WageRatesTableFilterComposer
    extends Composer<_$AppDatabase, $WageRatesTable> {
  $$WageRatesTableFilterComposer({
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

  ColumnFilters<int> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get centsPerHour => $composableBuilder(
    column: $table.centsPerHour,
    builder: (column) => ColumnFilters(column),
  );

  $$JobsTableFilterComposer get jobId {
    final $$JobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableFilterComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WageRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $WageRatesTable> {
  $$WageRatesTableOrderingComposer({
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

  ColumnOrderings<int> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get centsPerHour => $composableBuilder(
    column: $table.centsPerHour,
    builder: (column) => ColumnOrderings(column),
  );

  $$JobsTableOrderingComposer get jobId {
    final $$JobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableOrderingComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WageRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WageRatesTable> {
  $$WageRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<int> get centsPerHour => $composableBuilder(
    column: $table.centsPerHour,
    builder: (column) => column,
  );

  $$JobsTableAnnotationComposer get jobId {
    final $$JobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableAnnotationComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WageRatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WageRatesTable,
          WageRateRow,
          $$WageRatesTableFilterComposer,
          $$WageRatesTableOrderingComposer,
          $$WageRatesTableAnnotationComposer,
          $$WageRatesTableCreateCompanionBuilder,
          $$WageRatesTableUpdateCompanionBuilder,
          (WageRateRow, $$WageRatesTableReferences),
          WageRateRow,
          PrefetchHooks Function({bool jobId})
        > {
  $$WageRatesTableTableManager(_$AppDatabase db, $WageRatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WageRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WageRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WageRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> jobId = const Value.absent(),
                Value<int> validFrom = const Value.absent(),
                Value<int> centsPerHour = const Value.absent(),
              }) => WageRatesCompanion(
                id: id,
                jobId: jobId,
                validFrom: validFrom,
                centsPerHour: centsPerHour,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int jobId,
                required int validFrom,
                required int centsPerHour,
              }) => WageRatesCompanion.insert(
                id: id,
                jobId: jobId,
                validFrom: validFrom,
                centsPerHour: centsPerHour,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WageRatesTable, WageRateRow>(table),
                  $$WageRatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({jobId = false}) {
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
                    if (jobId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.jobId,
                        referencedTable: $$WageRatesTableReferences._jobIdTable(
                          db,
                        ),
                        referencedColumn: $$WageRatesTableReferences
                            ._jobIdTable(db)
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

typedef $$WageRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WageRatesTable,
      WageRateRow,
      $$WageRatesTableFilterComposer,
      $$WageRatesTableOrderingComposer,
      $$WageRatesTableAnnotationComposer,
      $$WageRatesTableCreateCompanionBuilder,
      $$WageRatesTableUpdateCompanionBuilder,
      (WageRateRow, $$WageRatesTableReferences),
      WageRateRow,
      PrefetchHooks Function({bool jobId})
    >;
typedef $$PayoutsTableCreateCompanionBuilder = PayoutsCompanion Function({
  Value<int> id,
  required String uuid,
  Value<int?> jobId,
  required int untilDate,
  required int paidOn,
  required int expectedCents,
  required int receivedCents,
  Value<String?> note,
  required int createdAt,
});
typedef $$PayoutsTableUpdateCompanionBuilder = PayoutsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<int?> jobId,
  Value<int> untilDate,
  Value<int> paidOn,
  Value<int> expectedCents,
  Value<int> receivedCents,
  Value<String?> note,
  Value<int> createdAt,
});

final class $$PayoutsTableReferences
    extends BaseReferences<_$AppDatabase, $PayoutsTable, PayoutRow> {
  $$PayoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $JobsTable _jobIdTable(_$AppDatabase db) =>
      db.jobs.createAlias('payouts__job_id__jobs__id');

  $$JobsTableProcessedTableManager? get jobId {
    final $_column = $_itemColumn<int>('job_id');
    if ($_column == null) return null;
    final manager = $$JobsTableTableManager(
      $_db,
      $_db.jobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_jobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ShiftsTable, List<ShiftRow>> _shiftsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.shifts,
    aliasName: 'payouts__id__shifts__payout_id',
  );

  $$ShiftsTableProcessedTableManager get shiftsRefs {
    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.payoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_shiftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PayoutsTableFilterComposer
    extends Composer<_$AppDatabase, $PayoutsTable> {
  $$PayoutsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get untilDate => $composableBuilder(
    column: $table.untilDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidOn => $composableBuilder(
    column: $table.paidOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedCents => $composableBuilder(
    column: $table.expectedCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedCents => $composableBuilder(
    column: $table.receivedCents,
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

  $$JobsTableFilterComposer get jobId {
    final $$JobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableFilterComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> shiftsRefs(
    Expression<bool> Function($$ShiftsTableFilterComposer f) f,
  ) {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.payoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PayoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $PayoutsTable> {
  $$PayoutsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get untilDate => $composableBuilder(
    column: $table.untilDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidOn => $composableBuilder(
    column: $table.paidOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedCents => $composableBuilder(
    column: $table.expectedCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedCents => $composableBuilder(
    column: $table.receivedCents,
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

  $$JobsTableOrderingComposer get jobId {
    final $$JobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableOrderingComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PayoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PayoutsTable> {
  $$PayoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get untilDate =>
      $composableBuilder(column: $table.untilDate, builder: (column) => column);

  GeneratedColumn<int> get paidOn =>
      $composableBuilder(column: $table.paidOn, builder: (column) => column);

  GeneratedColumn<int> get expectedCents => $composableBuilder(
    column: $table.expectedCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receivedCents => $composableBuilder(
    column: $table.receivedCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$JobsTableAnnotationComposer get jobId {
    final $$JobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableAnnotationComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> shiftsRefs<T extends Object>(
    Expression<T> Function($$ShiftsTableAnnotationComposer a) f,
  ) {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.payoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PayoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PayoutsTable,
          PayoutRow,
          $$PayoutsTableFilterComposer,
          $$PayoutsTableOrderingComposer,
          $$PayoutsTableAnnotationComposer,
          $$PayoutsTableCreateCompanionBuilder,
          $$PayoutsTableUpdateCompanionBuilder,
          (PayoutRow, $$PayoutsTableReferences),
          PayoutRow,
          PrefetchHooks Function({bool jobId, bool shiftsRefs})
        > {
  $$PayoutsTableTableManager(_$AppDatabase db, $PayoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PayoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PayoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PayoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int?> jobId = const Value.absent(),
                Value<int> untilDate = const Value.absent(),
                Value<int> paidOn = const Value.absent(),
                Value<int> expectedCents = const Value.absent(),
                Value<int> receivedCents = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => PayoutsCompanion(
                id: id,
                uuid: uuid,
                jobId: jobId,
                untilDate: untilDate,
                paidOn: paidOn,
                expectedCents: expectedCents,
                receivedCents: receivedCents,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                Value<int?> jobId = const Value.absent(),
                required int untilDate,
                required int paidOn,
                required int expectedCents,
                required int receivedCents,
                Value<String?> note = const Value.absent(),
                required int createdAt,
              }) => PayoutsCompanion.insert(
                id: id,
                uuid: uuid,
                jobId: jobId,
                untilDate: untilDate,
                paidOn: paidOn,
                expectedCents: expectedCents,
                receivedCents: receivedCents,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PayoutsTable, PayoutRow>(table),
                  $$PayoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({jobId = false, shiftsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (shiftsRefs) db.shifts],
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
                    if (jobId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.jobId,
                        referencedTable: $$PayoutsTableReferences._jobIdTable(
                          db,
                        ),
                        referencedColumn: $$PayoutsTableReferences
                            ._jobIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shiftsRefs)
                    await $_getPrefetchedData<
                      PayoutRow,
                      $PayoutsTable,
                      ShiftRow
                    >(
                      currentTable: table,
                      referencedTable: $$PayoutsTableReferences
                          ._shiftsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PayoutsTableReferences(db, table, p0).shiftsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.payoutId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PayoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PayoutsTable,
      PayoutRow,
      $$PayoutsTableFilterComposer,
      $$PayoutsTableOrderingComposer,
      $$PayoutsTableAnnotationComposer,
      $$PayoutsTableCreateCompanionBuilder,
      $$PayoutsTableUpdateCompanionBuilder,
      (PayoutRow, $$PayoutsTableReferences),
      PayoutRow,
      PrefetchHooks Function({bool jobId, bool shiftsRefs})
    >;
typedef $$ShiftsTableCreateCompanionBuilder = ShiftsCompanion Function({
  Value<int> id,
  required String uuid,
  required int jobId,
  required ShiftStatus status,
  required int startUtc,
  Value<int?> endUtc,
  required int rawStartUtc,
  Value<int?> rawEndUtc,
  required int startOffsetMin,
  Value<int?> endOffsetMin,
  required int rateCentsPerHour,
  Value<int> breakMs,
  Value<int?> pausedAtUtc,
  Value<int> tipsCents,
  Value<String?> note,
  Value<int?> paidAtUtc,
  Value<int?> payoutId,
  Value<int?> amountCents,
  Value<String?> legacyId,
  required ShiftSource source,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
});
typedef $$ShiftsTableUpdateCompanionBuilder = ShiftsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> jobId,
  Value<ShiftStatus> status,
  Value<int> startUtc,
  Value<int?> endUtc,
  Value<int> rawStartUtc,
  Value<int?> rawEndUtc,
  Value<int> startOffsetMin,
  Value<int?> endOffsetMin,
  Value<int> rateCentsPerHour,
  Value<int> breakMs,
  Value<int?> pausedAtUtc,
  Value<int> tipsCents,
  Value<String?> note,
  Value<int?> paidAtUtc,
  Value<int?> payoutId,
  Value<int?> amountCents,
  Value<String?> legacyId,
  Value<ShiftSource> source,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
});

final class $$ShiftsTableReferences
    extends BaseReferences<_$AppDatabase, $ShiftsTable, ShiftRow> {
  $$ShiftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $JobsTable _jobIdTable(_$AppDatabase db) =>
      db.jobs.createAlias('shifts__job_id__jobs__id');

  $$JobsTableProcessedTableManager get jobId {
    final $_column = $_itemColumn<int>('job_id')!;

    final manager = $$JobsTableTableManager(
      $_db,
      $_db.jobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_jobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PayoutsTable _payoutIdTable(_$AppDatabase db) =>
      db.payouts.createAlias('shifts__payout_id__payouts__id');

  $$PayoutsTableProcessedTableManager? get payoutId {
    final $_column = $_itemColumn<int>('payout_id');
    if ($_column == null) return null;
    final manager = $$PayoutsTableTableManager(
      $_db,
      $_db.payouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_payoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReviewItemsTable, List<ReviewItemRow>>
  _reviewItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewItems,
    aliasName: 'shifts__id__review_items__shift_id',
  );

  $$ReviewItemsTableProcessedTableManager get reviewItemsRefs {
    final manager = $$ReviewItemsTableTableManager(
      $_db,
      $_db.reviewItems,
    ).filter((f) => f.shiftId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShiftsTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ShiftStatus, ShiftStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endUtc => $composableBuilder(
    column: $table.endUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rawStartUtc => $composableBuilder(
    column: $table.rawStartUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rawEndUtc => $composableBuilder(
    column: $table.rawEndUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startOffsetMin => $composableBuilder(
    column: $table.startOffsetMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endOffsetMin => $composableBuilder(
    column: $table.endOffsetMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateCentsPerHour => $composableBuilder(
    column: $table.rateCentsPerHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breakMs => $composableBuilder(
    column: $table.breakMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedAtUtc => $composableBuilder(
    column: $table.pausedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tipsCents => $composableBuilder(
    column: $table.tipsCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidAtUtc => $composableBuilder(
    column: $table.paidAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ShiftSource, ShiftSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
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

  $$JobsTableFilterComposer get jobId {
    final $$JobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableFilterComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PayoutsTableFilterComposer get payoutId {
    final $$PayoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.payoutId,
      referencedTable: $db.payouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayoutsTableFilterComposer(
            $db: $db,
            $table: $db.payouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> reviewItemsRefs(
    Expression<bool> Function($$ReviewItemsTableFilterComposer f) f,
  ) {
    final $$ReviewItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewItems,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewItemsTableFilterComposer(
            $db: $db,
            $table: $db.reviewItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShiftsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endUtc => $composableBuilder(
    column: $table.endUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rawStartUtc => $composableBuilder(
    column: $table.rawStartUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rawEndUtc => $composableBuilder(
    column: $table.rawEndUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startOffsetMin => $composableBuilder(
    column: $table.startOffsetMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endOffsetMin => $composableBuilder(
    column: $table.endOffsetMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateCentsPerHour => $composableBuilder(
    column: $table.rateCentsPerHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breakMs => $composableBuilder(
    column: $table.breakMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedAtUtc => $composableBuilder(
    column: $table.pausedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tipsCents => $composableBuilder(
    column: $table.tipsCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidAtUtc => $composableBuilder(
    column: $table.paidAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
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

  $$JobsTableOrderingComposer get jobId {
    final $$JobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableOrderingComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PayoutsTableOrderingComposer get payoutId {
    final $$PayoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.payoutId,
      referencedTable: $db.payouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayoutsTableOrderingComposer(
            $db: $db,
            $table: $db.payouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ShiftStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get startUtc =>
      $composableBuilder(column: $table.startUtc, builder: (column) => column);

  GeneratedColumn<int> get endUtc =>
      $composableBuilder(column: $table.endUtc, builder: (column) => column);

  GeneratedColumn<int> get rawStartUtc => $composableBuilder(
    column: $table.rawStartUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rawEndUtc =>
      $composableBuilder(column: $table.rawEndUtc, builder: (column) => column);

  GeneratedColumn<int> get startOffsetMin => $composableBuilder(
    column: $table.startOffsetMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endOffsetMin => $composableBuilder(
    column: $table.endOffsetMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rateCentsPerHour => $composableBuilder(
    column: $table.rateCentsPerHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get breakMs =>
      $composableBuilder(column: $table.breakMs, builder: (column) => column);

  GeneratedColumn<int> get pausedAtUtc => $composableBuilder(
    column: $table.pausedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tipsCents =>
      $composableBuilder(column: $table.tipsCents, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get paidAtUtc =>
      $composableBuilder(column: $table.paidAtUtc, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get legacyId =>
      $composableBuilder(column: $table.legacyId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ShiftSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$JobsTableAnnotationComposer get jobId {
    final $$JobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableAnnotationComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PayoutsTableAnnotationComposer get payoutId {
    final $$PayoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.payoutId,
      referencedTable: $db.payouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.payouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> reviewItemsRefs<T extends Object>(
    Expression<T> Function($$ReviewItemsTableAnnotationComposer a) f,
  ) {
    final $$ReviewItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewItems,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShiftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShiftsTable,
          ShiftRow,
          $$ShiftsTableFilterComposer,
          $$ShiftsTableOrderingComposer,
          $$ShiftsTableAnnotationComposer,
          $$ShiftsTableCreateCompanionBuilder,
          $$ShiftsTableUpdateCompanionBuilder,
          (ShiftRow, $$ShiftsTableReferences),
          ShiftRow,
          PrefetchHooks Function({
            bool jobId,
            bool payoutId,
            bool reviewItemsRefs,
          })
        > {
  $$ShiftsTableTableManager(_$AppDatabase db, $ShiftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> jobId = const Value.absent(),
                Value<ShiftStatus> status = const Value.absent(),
                Value<int> startUtc = const Value.absent(),
                Value<int?> endUtc = const Value.absent(),
                Value<int> rawStartUtc = const Value.absent(),
                Value<int?> rawEndUtc = const Value.absent(),
                Value<int> startOffsetMin = const Value.absent(),
                Value<int?> endOffsetMin = const Value.absent(),
                Value<int> rateCentsPerHour = const Value.absent(),
                Value<int> breakMs = const Value.absent(),
                Value<int?> pausedAtUtc = const Value.absent(),
                Value<int> tipsCents = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> paidAtUtc = const Value.absent(),
                Value<int?> payoutId = const Value.absent(),
                Value<int?> amountCents = const Value.absent(),
                Value<String?> legacyId = const Value.absent(),
                Value<ShiftSource> source = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => ShiftsCompanion(
                id: id,
                uuid: uuid,
                jobId: jobId,
                status: status,
                startUtc: startUtc,
                endUtc: endUtc,
                rawStartUtc: rawStartUtc,
                rawEndUtc: rawEndUtc,
                startOffsetMin: startOffsetMin,
                endOffsetMin: endOffsetMin,
                rateCentsPerHour: rateCentsPerHour,
                breakMs: breakMs,
                pausedAtUtc: pausedAtUtc,
                tipsCents: tipsCents,
                note: note,
                paidAtUtc: paidAtUtc,
                payoutId: payoutId,
                amountCents: amountCents,
                legacyId: legacyId,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int jobId,
                required ShiftStatus status,
                required int startUtc,
                Value<int?> endUtc = const Value.absent(),
                required int rawStartUtc,
                Value<int?> rawEndUtc = const Value.absent(),
                required int startOffsetMin,
                Value<int?> endOffsetMin = const Value.absent(),
                required int rateCentsPerHour,
                Value<int> breakMs = const Value.absent(),
                Value<int?> pausedAtUtc = const Value.absent(),
                Value<int> tipsCents = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> paidAtUtc = const Value.absent(),
                Value<int?> payoutId = const Value.absent(),
                Value<int?> amountCents = const Value.absent(),
                Value<String?> legacyId = const Value.absent(),
                required ShiftSource source,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
              }) => ShiftsCompanion.insert(
                id: id,
                uuid: uuid,
                jobId: jobId,
                status: status,
                startUtc: startUtc,
                endUtc: endUtc,
                rawStartUtc: rawStartUtc,
                rawEndUtc: rawEndUtc,
                startOffsetMin: startOffsetMin,
                endOffsetMin: endOffsetMin,
                rateCentsPerHour: rateCentsPerHour,
                breakMs: breakMs,
                pausedAtUtc: pausedAtUtc,
                tipsCents: tipsCents,
                note: note,
                paidAtUtc: paidAtUtc,
                payoutId: payoutId,
                amountCents: amountCents,
                legacyId: legacyId,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShiftsTable, ShiftRow>(table),
                  $$ShiftsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({jobId = false, payoutId = false, reviewItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reviewItemsRefs) db.reviewItems,
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
                        if (jobId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.jobId,
                            referencedTable: $$ShiftsTableReferences
                                ._jobIdTable(db),
                            referencedColumn: $$ShiftsTableReferences
                                ._jobIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (payoutId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.payoutId,
                            referencedTable: $$ShiftsTableReferences
                                ._payoutIdTable(db),
                            referencedColumn: $$ShiftsTableReferences
                                ._payoutIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reviewItemsRefs)
                        await $_getPrefetchedData<
                          ShiftRow,
                          $ShiftsTable,
                          ReviewItemRow
                        >(
                          currentTable: table,
                          referencedTable: $$ShiftsTableReferences
                              ._reviewItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShiftsTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shiftId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ShiftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShiftsTable,
      ShiftRow,
      $$ShiftsTableFilterComposer,
      $$ShiftsTableOrderingComposer,
      $$ShiftsTableAnnotationComposer,
      $$ShiftsTableCreateCompanionBuilder,
      $$ShiftsTableUpdateCompanionBuilder,
      (ShiftRow, $$ShiftsTableReferences),
      ShiftRow,
      PrefetchHooks Function({bool jobId, bool payoutId, bool reviewItemsRefs})
    >;
typedef $$MetaTableCreateCompanionBuilder = MetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$MetaTableUpdateCompanionBuilder = MetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$MetaTableFilterComposer extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetaTableOrderingComposer extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetaTable,
          MetaRow,
          $$MetaTableFilterComposer,
          $$MetaTableOrderingComposer,
          $$MetaTableAnnotationComposer,
          $$MetaTableCreateCompanionBuilder,
          $$MetaTableUpdateCompanionBuilder,
          (MetaRow, BaseReferences<_$AppDatabase, $MetaTable, MetaRow>),
          MetaRow,
          PrefetchHooks Function()
        > {
  $$MetaTableTableManager(_$AppDatabase db, $MetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => MetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => MetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MetaTable, MetaRow>(table),
                  BaseReferences<_$AppDatabase, $MetaTable, MetaRow>(
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

typedef $$MetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetaTable,
      MetaRow,
      $$MetaTableFilterComposer,
      $$MetaTableOrderingComposer,
      $$MetaTableAnnotationComposer,
      $$MetaTableCreateCompanionBuilder,
      $$MetaTableUpdateCompanionBuilder,
      (MetaRow, BaseReferences<_$AppDatabase, $MetaTable, MetaRow>),
      MetaRow,
      PrefetchHooks Function()
    >;
typedef $$ReviewItemsTableCreateCompanionBuilder =
    ReviewItemsCompanion Function({
      Value<int> shiftId,
      required String reasons,
      Value<String> related,
    });
typedef $$ReviewItemsTableUpdateCompanionBuilder =
    ReviewItemsCompanion Function({
      Value<int> shiftId,
      Value<String> reasons,
      Value<String> related,
    });

final class $$ReviewItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewItemsTable, ReviewItemRow> {
  $$ReviewItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) =>
      db.shifts.createAlias('review_items__shift_id__shifts__id');

  $$ShiftsTableProcessedTableManager get shiftId {
    final $_column = $_itemColumn<int>('shift_id')!;

    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewItemsTable> {
  $$ReviewItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get reasons => $composableBuilder(
    column: $table.reasons,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get related => $composableBuilder(
    column: $table.related,
    builder: (column) => ColumnFilters(column),
  );

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewItemsTable> {
  $$ReviewItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get reasons => $composableBuilder(
    column: $table.reasons,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get related => $composableBuilder(
    column: $table.related,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableOrderingComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewItemsTable> {
  $$ReviewItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get reasons =>
      $composableBuilder(column: $table.reasons, builder: (column) => column);

  GeneratedColumn<String> get related =>
      $composableBuilder(column: $table.related, builder: (column) => column);

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewItemsTable,
          ReviewItemRow,
          $$ReviewItemsTableFilterComposer,
          $$ReviewItemsTableOrderingComposer,
          $$ReviewItemsTableAnnotationComposer,
          $$ReviewItemsTableCreateCompanionBuilder,
          $$ReviewItemsTableUpdateCompanionBuilder,
          (ReviewItemRow, $$ReviewItemsTableReferences),
          ReviewItemRow,
          PrefetchHooks Function({bool shiftId})
        > {
  $$ReviewItemsTableTableManager(_$AppDatabase db, $ReviewItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> shiftId = const Value.absent(),
                Value<String> reasons = const Value.absent(),
                Value<String> related = const Value.absent(),
              }) => ReviewItemsCompanion(
                shiftId: shiftId,
                reasons: reasons,
                related: related,
              ),
          createCompanionCallback:
              ({
                Value<int> shiftId = const Value.absent(),
                required String reasons,
                Value<String> related = const Value.absent(),
              }) => ReviewItemsCompanion.insert(
                shiftId: shiftId,
                reasons: reasons,
                related: related,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewItemsTable, ReviewItemRow>(table),
                  $$ReviewItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shiftId = false}) {
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
                    if (shiftId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.shiftId,
                        referencedTable: $$ReviewItemsTableReferences
                            ._shiftIdTable(db),
                        referencedColumn: $$ReviewItemsTableReferences
                            ._shiftIdTable(db)
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

typedef $$ReviewItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewItemsTable,
      ReviewItemRow,
      $$ReviewItemsTableFilterComposer,
      $$ReviewItemsTableOrderingComposer,
      $$ReviewItemsTableAnnotationComposer,
      $$ReviewItemsTableCreateCompanionBuilder,
      $$ReviewItemsTableUpdateCompanionBuilder,
      (ReviewItemRow, $$ReviewItemsTableReferences),
      ReviewItemRow,
      PrefetchHooks Function({bool shiftId})
    >;
typedef $$LegacyErrorsTableCreateCompanionBuilder =
    LegacyErrorsCompanion Function({
      Value<int> id,
      required String origin,
      required String raw,
      required String code,
      Value<String?> message,
      required int createdAt,
    });
typedef $$LegacyErrorsTableUpdateCompanionBuilder =
    LegacyErrorsCompanion Function({
      Value<int> id,
      Value<String> origin,
      Value<String> raw,
      Value<String> code,
      Value<String?> message,
      Value<int> createdAt,
    });

class $$LegacyErrorsTableFilterComposer
    extends Composer<_$AppDatabase, $LegacyErrorsTable> {
  $$LegacyErrorsTableFilterComposer({
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

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LegacyErrorsTableOrderingComposer
    extends Composer<_$AppDatabase, $LegacyErrorsTable> {
  $$LegacyErrorsTableOrderingComposer({
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

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LegacyErrorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LegacyErrorsTable> {
  $$LegacyErrorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get raw =>
      $composableBuilder(column: $table.raw, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LegacyErrorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LegacyErrorsTable,
          LegacyErrorRow,
          $$LegacyErrorsTableFilterComposer,
          $$LegacyErrorsTableOrderingComposer,
          $$LegacyErrorsTableAnnotationComposer,
          $$LegacyErrorsTableCreateCompanionBuilder,
          $$LegacyErrorsTableUpdateCompanionBuilder,
          (
            LegacyErrorRow,
            BaseReferences<_$AppDatabase, $LegacyErrorsTable, LegacyErrorRow>,
          ),
          LegacyErrorRow,
          PrefetchHooks Function()
        > {
  $$LegacyErrorsTableTableManager(_$AppDatabase db, $LegacyErrorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LegacyErrorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LegacyErrorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LegacyErrorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> raw = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => LegacyErrorsCompanion(
                id: id,
                origin: origin,
                raw: raw,
                code: code,
                message: message,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String origin,
                required String raw,
                required String code,
                Value<String?> message = const Value.absent(),
                required int createdAt,
              }) => LegacyErrorsCompanion.insert(
                id: id,
                origin: origin,
                raw: raw,
                code: code,
                message: message,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LegacyErrorsTable, LegacyErrorRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LegacyErrorsTable,
                    LegacyErrorRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LegacyErrorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LegacyErrorsTable,
      LegacyErrorRow,
      $$LegacyErrorsTableFilterComposer,
      $$LegacyErrorsTableOrderingComposer,
      $$LegacyErrorsTableAnnotationComposer,
      $$LegacyErrorsTableCreateCompanionBuilder,
      $$LegacyErrorsTableUpdateCompanionBuilder,
      (
        LegacyErrorRow,
        BaseReferences<_$AppDatabase, $LegacyErrorsTable, LegacyErrorRow>,
      ),
      LegacyErrorRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$JobsTableTableManager get jobs => $$JobsTableTableManager(_db, _db.jobs);
  $$WageRatesTableTableManager get wageRates =>
      $$WageRatesTableTableManager(_db, _db.wageRates);
  $$PayoutsTableTableManager get payouts =>
      $$PayoutsTableTableManager(_db, _db.payouts);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db, _db.shifts);
  $$MetaTableTableManager get meta => $$MetaTableTableManager(_db, _db.meta);
  $$ReviewItemsTableTableManager get reviewItems =>
      $$ReviewItemsTableTableManager(_db, _db.reviewItems);
  $$LegacyErrorsTableTableManager get legacyErrors =>
      $$LegacyErrorsTableTableManager(_db, _db.legacyErrors);
}
