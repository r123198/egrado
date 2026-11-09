// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SchoolClassesTable extends SchoolClasses
    with TableInfo<$SchoolClassesTable, ClassRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchoolClassesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _gradingPolicyMeta = const VerificationMeta(
    'gradingPolicy',
  );
  @override
  late final GeneratedColumn<String> gradingPolicy = GeneratedColumn<String>(
    'grading_policy',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectGroupMeta = const VerificationMeta(
    'subjectGroup',
  );
  @override
  late final GeneratedColumn<String> subjectGroup = GeneratedColumn<String>(
    'subject_group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAt,
    gradingPolicy,
    subjectGroup,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'school_classes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassRow> instance, {
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('grading_policy')) {
      context.handle(
        _gradingPolicyMeta,
        gradingPolicy.isAcceptableOrUnknown(
          data['grading_policy']!,
          _gradingPolicyMeta,
        ),
      );
    }
    if (data.containsKey('subject_group')) {
      context.handle(
        _subjectGroupMeta,
        subjectGroup.isAcceptableOrUnknown(
          data['subject_group']!,
          _subjectGroupMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      gradingPolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grading_policy'],
      ),
      subjectGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_group'],
      ),
    );
  }

  @override
  $SchoolClassesTable createAlias(String alias) {
    return $SchoolClassesTable(attachedDatabase, alias);
  }
}

class ClassRow extends DataClass implements Insertable<ClassRow> {
  final String id;
  final String name;
  final DateTime createdAt;

  /// DepEd grading policy id (see `kGradingPolicies`); null = current one.
  final String? gradingPolicy;

  /// Subject group id inside the policy; null = not chosen yet.
  final String? subjectGroup;
  const ClassRow({
    required this.id,
    required this.name,
    required this.createdAt,
    this.gradingPolicy,
    this.subjectGroup,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || gradingPolicy != null) {
      map['grading_policy'] = Variable<String>(gradingPolicy);
    }
    if (!nullToAbsent || subjectGroup != null) {
      map['subject_group'] = Variable<String>(subjectGroup);
    }
    return map;
  }

  SchoolClassesCompanion toCompanion(bool nullToAbsent) {
    return SchoolClassesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      gradingPolicy: gradingPolicy == null && nullToAbsent
          ? const Value.absent()
          : Value(gradingPolicy),
      subjectGroup: subjectGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectGroup),
    );
  }

  factory ClassRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      gradingPolicy: serializer.fromJson<String?>(json['gradingPolicy']),
      subjectGroup: serializer.fromJson<String?>(json['subjectGroup']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'gradingPolicy': serializer.toJson<String?>(gradingPolicy),
      'subjectGroup': serializer.toJson<String?>(subjectGroup),
    };
  }

  ClassRow copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    Value<String?> gradingPolicy = const Value.absent(),
    Value<String?> subjectGroup = const Value.absent(),
  }) => ClassRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    gradingPolicy: gradingPolicy.present
        ? gradingPolicy.value
        : this.gradingPolicy,
    subjectGroup: subjectGroup.present ? subjectGroup.value : this.subjectGroup,
  );
  ClassRow copyWithCompanion(SchoolClassesCompanion data) {
    return ClassRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      gradingPolicy: data.gradingPolicy.present
          ? data.gradingPolicy.value
          : this.gradingPolicy,
      subjectGroup: data.subjectGroup.present
          ? data.subjectGroup.value
          : this.subjectGroup,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('gradingPolicy: $gradingPolicy, ')
          ..write('subjectGroup: $subjectGroup')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, createdAt, gradingPolicy, subjectGroup);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.gradingPolicy == this.gradingPolicy &&
          other.subjectGroup == this.subjectGroup);
}

class SchoolClassesCompanion extends UpdateCompanion<ClassRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<String?> gradingPolicy;
  final Value<String?> subjectGroup;
  final Value<int> rowid;
  const SchoolClassesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.gradingPolicy = const Value.absent(),
    this.subjectGroup = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchoolClassesCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    this.gradingPolicy = const Value.absent(),
    this.subjectGroup = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<ClassRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<String>? gradingPolicy,
    Expression<String>? subjectGroup,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (gradingPolicy != null) 'grading_policy': gradingPolicy,
      if (subjectGroup != null) 'subject_group': subjectGroup,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchoolClassesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<String?>? gradingPolicy,
    Value<String?>? subjectGroup,
    Value<int>? rowid,
  }) {
    return SchoolClassesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      gradingPolicy: gradingPolicy ?? this.gradingPolicy,
      subjectGroup: subjectGroup ?? this.subjectGroup,
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (gradingPolicy.present) {
      map['grading_policy'] = Variable<String>(gradingPolicy.value);
    }
    if (subjectGroup.present) {
      map['subject_group'] = Variable<String>(subjectGroup.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchoolClassesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('gradingPolicy: $gradingPolicy, ')
          ..write('subjectGroup: $subjectGroup, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudentsTable extends Students
    with TableInfo<$StudentsTable, StudentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _classIdMeta = const VerificationMeta(
    'classId',
  );
  @override
  late final GeneratedColumn<String> classId = GeneratedColumn<String>(
    'class_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES school_classes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [classId, number, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'students';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('class_id')) {
      context.handle(
        _classIdMeta,
        classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta),
      );
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {classId, number};
  @override
  StudentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentRow(
      classId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $StudentsTable createAlias(String alias) {
    return $StudentsTable(attachedDatabase, alias);
  }
}

class StudentRow extends DataClass implements Insertable<StudentRow> {
  final String classId;

  /// The number shaded on the answer sheet (1–99), unique within a class.
  final int number;
  final String name;
  const StudentRow({
    required this.classId,
    required this.number,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['class_id'] = Variable<String>(classId);
    map['number'] = Variable<int>(number);
    map['name'] = Variable<String>(name);
    return map;
  }

  StudentsCompanion toCompanion(bool nullToAbsent) {
    return StudentsCompanion(
      classId: Value(classId),
      number: Value(number),
      name: Value(name),
    );
  }

  factory StudentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentRow(
      classId: serializer.fromJson<String>(json['classId']),
      number: serializer.fromJson<int>(json['number']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'classId': serializer.toJson<String>(classId),
      'number': serializer.toJson<int>(number),
      'name': serializer.toJson<String>(name),
    };
  }

  StudentRow copyWith({String? classId, int? number, String? name}) =>
      StudentRow(
        classId: classId ?? this.classId,
        number: number ?? this.number,
        name: name ?? this.name,
      );
  StudentRow copyWithCompanion(StudentsCompanion data) {
    return StudentRow(
      classId: data.classId.present ? data.classId.value : this.classId,
      number: data.number.present ? data.number.value : this.number,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentRow(')
          ..write('classId: $classId, ')
          ..write('number: $number, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(classId, number, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentRow &&
          other.classId == this.classId &&
          other.number == this.number &&
          other.name == this.name);
}

class StudentsCompanion extends UpdateCompanion<StudentRow> {
  final Value<String> classId;
  final Value<int> number;
  final Value<String> name;
  final Value<int> rowid;
  const StudentsCompanion({
    this.classId = const Value.absent(),
    this.number = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentsCompanion.insert({
    required String classId,
    required int number,
    required String name,
    this.rowid = const Value.absent(),
  }) : classId = Value(classId),
       number = Value(number),
       name = Value(name);
  static Insertable<StudentRow> custom({
    Expression<String>? classId,
    Expression<int>? number,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (classId != null) 'class_id': classId,
      if (number != null) 'number': number,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentsCompanion copyWith({
    Value<String>? classId,
    Value<int>? number,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return StudentsCompanion(
      classId: classId ?? this.classId,
      number: number ?? this.number,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (classId.present) {
      map['class_id'] = Variable<String>(classId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsCompanion(')
          ..write('classId: $classId, ')
          ..write('number: $number, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExamsTable extends Exams with TableInfo<$ExamsTable, ExamRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classIdMeta = const VerificationMeta(
    'classId',
  );
  @override
  late final GeneratedColumn<String> classId = GeneratedColumn<String>(
    'class_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES school_classes (id) ON DELETE CASCADE',
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
  static const VerificationMeta _questionCountMeta = const VerificationMeta(
    'questionCount',
  );
  @override
  late final GeneratedColumn<int> questionCount = GeneratedColumn<int>(
    'question_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _choiceCountMeta = const VerificationMeta(
    'choiceCount',
  );
  @override
  late final GeneratedColumn<int> choiceCount = GeneratedColumn<int>(
    'choice_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<int?>, String> answerKey =
      GeneratedColumn<String>(
        'answer_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<int?>>($ExamsTable.$converteranswerKey);
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
  static const VerificationMeta _gradingPeriodMeta = const VerificationMeta(
    'gradingPeriod',
  );
  @override
  late final GeneratedColumn<int> gradingPeriod = GeneratedColumn<int>(
    'grading_period',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gradeComponentMeta = const VerificationMeta(
    'gradeComponent',
  );
  @override
  late final GeneratedColumn<String> gradeComponent = GeneratedColumn<String>(
    'grade_component',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _examPartMeta = const VerificationMeta(
    'examPart',
  );
  @override
  late final GeneratedColumn<String> examPart = GeneratedColumn<String>(
    'exam_part',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    classId,
    title,
    questionCount,
    choiceCount,
    answerKey,
    createdAt,
    gradingPeriod,
    gradeComponent,
    examPart,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exams';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExamRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('class_id')) {
      context.handle(
        _classIdMeta,
        classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta),
      );
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('question_count')) {
      context.handle(
        _questionCountMeta,
        questionCount.isAcceptableOrUnknown(
          data['question_count']!,
          _questionCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionCountMeta);
    }
    if (data.containsKey('choice_count')) {
      context.handle(
        _choiceCountMeta,
        choiceCount.isAcceptableOrUnknown(
          data['choice_count']!,
          _choiceCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_choiceCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('grading_period')) {
      context.handle(
        _gradingPeriodMeta,
        gradingPeriod.isAcceptableOrUnknown(
          data['grading_period']!,
          _gradingPeriodMeta,
        ),
      );
    }
    if (data.containsKey('grade_component')) {
      context.handle(
        _gradeComponentMeta,
        gradeComponent.isAcceptableOrUnknown(
          data['grade_component']!,
          _gradeComponentMeta,
        ),
      );
    }
    if (data.containsKey('exam_part')) {
      context.handle(
        _examPartMeta,
        examPart.isAcceptableOrUnknown(data['exam_part']!, _examPartMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExamRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExamRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      classId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      questionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_count'],
      )!,
      choiceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}choice_count'],
      )!,
      answerKey: $ExamsTable.$converteranswerKey.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}answer_key'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      gradingPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grading_period'],
      ),
      gradeComponent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade_component'],
      ),
      examPart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_part'],
      ),
    );
  }

  @override
  $ExamsTable createAlias(String alias) {
    return $ExamsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<int?>, String> $converteranswerKey =
      const ChoiceListConverter();
}

class ExamRow extends DataClass implements Insertable<ExamRow> {
  final String id;
  final String classId;
  final String title;
  final int questionCount;
  final int choiceCount;
  final List<int?> answerKey;
  final DateTime createdAt;

  /// Term or quarter this test counts toward; null = not counted.
  final int? gradingPeriod;

  /// `GradeComponent.name`; null = not counted.
  final String? gradeComponent;

  /// `ExamPart.name` for exams (ST1, ST2, TE, QA).
  final String? examPart;
  const ExamRow({
    required this.id,
    required this.classId,
    required this.title,
    required this.questionCount,
    required this.choiceCount,
    required this.answerKey,
    required this.createdAt,
    this.gradingPeriod,
    this.gradeComponent,
    this.examPart,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['class_id'] = Variable<String>(classId);
    map['title'] = Variable<String>(title);
    map['question_count'] = Variable<int>(questionCount);
    map['choice_count'] = Variable<int>(choiceCount);
    {
      map['answer_key'] = Variable<String>(
        $ExamsTable.$converteranswerKey.toSql(answerKey),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || gradingPeriod != null) {
      map['grading_period'] = Variable<int>(gradingPeriod);
    }
    if (!nullToAbsent || gradeComponent != null) {
      map['grade_component'] = Variable<String>(gradeComponent);
    }
    if (!nullToAbsent || examPart != null) {
      map['exam_part'] = Variable<String>(examPart);
    }
    return map;
  }

  ExamsCompanion toCompanion(bool nullToAbsent) {
    return ExamsCompanion(
      id: Value(id),
      classId: Value(classId),
      title: Value(title),
      questionCount: Value(questionCount),
      choiceCount: Value(choiceCount),
      answerKey: Value(answerKey),
      createdAt: Value(createdAt),
      gradingPeriod: gradingPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(gradingPeriod),
      gradeComponent: gradeComponent == null && nullToAbsent
          ? const Value.absent()
          : Value(gradeComponent),
      examPart: examPart == null && nullToAbsent
          ? const Value.absent()
          : Value(examPart),
    );
  }

  factory ExamRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExamRow(
      id: serializer.fromJson<String>(json['id']),
      classId: serializer.fromJson<String>(json['classId']),
      title: serializer.fromJson<String>(json['title']),
      questionCount: serializer.fromJson<int>(json['questionCount']),
      choiceCount: serializer.fromJson<int>(json['choiceCount']),
      answerKey: serializer.fromJson<List<int?>>(json['answerKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      gradingPeriod: serializer.fromJson<int?>(json['gradingPeriod']),
      gradeComponent: serializer.fromJson<String?>(json['gradeComponent']),
      examPart: serializer.fromJson<String?>(json['examPart']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'classId': serializer.toJson<String>(classId),
      'title': serializer.toJson<String>(title),
      'questionCount': serializer.toJson<int>(questionCount),
      'choiceCount': serializer.toJson<int>(choiceCount),
      'answerKey': serializer.toJson<List<int?>>(answerKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'gradingPeriod': serializer.toJson<int?>(gradingPeriod),
      'gradeComponent': serializer.toJson<String?>(gradeComponent),
      'examPart': serializer.toJson<String?>(examPart),
    };
  }

  ExamRow copyWith({
    String? id,
    String? classId,
    String? title,
    int? questionCount,
    int? choiceCount,
    List<int?>? answerKey,
    DateTime? createdAt,
    Value<int?> gradingPeriod = const Value.absent(),
    Value<String?> gradeComponent = const Value.absent(),
    Value<String?> examPart = const Value.absent(),
  }) => ExamRow(
    id: id ?? this.id,
    classId: classId ?? this.classId,
    title: title ?? this.title,
    questionCount: questionCount ?? this.questionCount,
    choiceCount: choiceCount ?? this.choiceCount,
    answerKey: answerKey ?? this.answerKey,
    createdAt: createdAt ?? this.createdAt,
    gradingPeriod: gradingPeriod.present
        ? gradingPeriod.value
        : this.gradingPeriod,
    gradeComponent: gradeComponent.present
        ? gradeComponent.value
        : this.gradeComponent,
    examPart: examPart.present ? examPart.value : this.examPart,
  );
  ExamRow copyWithCompanion(ExamsCompanion data) {
    return ExamRow(
      id: data.id.present ? data.id.value : this.id,
      classId: data.classId.present ? data.classId.value : this.classId,
      title: data.title.present ? data.title.value : this.title,
      questionCount: data.questionCount.present
          ? data.questionCount.value
          : this.questionCount,
      choiceCount: data.choiceCount.present
          ? data.choiceCount.value
          : this.choiceCount,
      answerKey: data.answerKey.present ? data.answerKey.value : this.answerKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      gradingPeriod: data.gradingPeriod.present
          ? data.gradingPeriod.value
          : this.gradingPeriod,
      gradeComponent: data.gradeComponent.present
          ? data.gradeComponent.value
          : this.gradeComponent,
      examPart: data.examPart.present ? data.examPart.value : this.examPart,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExamRow(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('title: $title, ')
          ..write('questionCount: $questionCount, ')
          ..write('choiceCount: $choiceCount, ')
          ..write('answerKey: $answerKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('gradingPeriod: $gradingPeriod, ')
          ..write('gradeComponent: $gradeComponent, ')
          ..write('examPart: $examPart')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    classId,
    title,
    questionCount,
    choiceCount,
    answerKey,
    createdAt,
    gradingPeriod,
    gradeComponent,
    examPart,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExamRow &&
          other.id == this.id &&
          other.classId == this.classId &&
          other.title == this.title &&
          other.questionCount == this.questionCount &&
          other.choiceCount == this.choiceCount &&
          other.answerKey == this.answerKey &&
          other.createdAt == this.createdAt &&
          other.gradingPeriod == this.gradingPeriod &&
          other.gradeComponent == this.gradeComponent &&
          other.examPart == this.examPart);
}

class ExamsCompanion extends UpdateCompanion<ExamRow> {
  final Value<String> id;
  final Value<String> classId;
  final Value<String> title;
  final Value<int> questionCount;
  final Value<int> choiceCount;
  final Value<List<int?>> answerKey;
  final Value<DateTime> createdAt;
  final Value<int?> gradingPeriod;
  final Value<String?> gradeComponent;
  final Value<String?> examPart;
  final Value<int> rowid;
  const ExamsCompanion({
    this.id = const Value.absent(),
    this.classId = const Value.absent(),
    this.title = const Value.absent(),
    this.questionCount = const Value.absent(),
    this.choiceCount = const Value.absent(),
    this.answerKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.gradingPeriod = const Value.absent(),
    this.gradeComponent = const Value.absent(),
    this.examPart = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExamsCompanion.insert({
    required String id,
    required String classId,
    required String title,
    required int questionCount,
    required int choiceCount,
    required List<int?> answerKey,
    required DateTime createdAt,
    this.gradingPeriod = const Value.absent(),
    this.gradeComponent = const Value.absent(),
    this.examPart = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       classId = Value(classId),
       title = Value(title),
       questionCount = Value(questionCount),
       choiceCount = Value(choiceCount),
       answerKey = Value(answerKey),
       createdAt = Value(createdAt);
  static Insertable<ExamRow> custom({
    Expression<String>? id,
    Expression<String>? classId,
    Expression<String>? title,
    Expression<int>? questionCount,
    Expression<int>? choiceCount,
    Expression<String>? answerKey,
    Expression<DateTime>? createdAt,
    Expression<int>? gradingPeriod,
    Expression<String>? gradeComponent,
    Expression<String>? examPart,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classId != null) 'class_id': classId,
      if (title != null) 'title': title,
      if (questionCount != null) 'question_count': questionCount,
      if (choiceCount != null) 'choice_count': choiceCount,
      if (answerKey != null) 'answer_key': answerKey,
      if (createdAt != null) 'created_at': createdAt,
      if (gradingPeriod != null) 'grading_period': gradingPeriod,
      if (gradeComponent != null) 'grade_component': gradeComponent,
      if (examPart != null) 'exam_part': examPart,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExamsCompanion copyWith({
    Value<String>? id,
    Value<String>? classId,
    Value<String>? title,
    Value<int>? questionCount,
    Value<int>? choiceCount,
    Value<List<int?>>? answerKey,
    Value<DateTime>? createdAt,
    Value<int?>? gradingPeriod,
    Value<String?>? gradeComponent,
    Value<String?>? examPart,
    Value<int>? rowid,
  }) {
    return ExamsCompanion(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      questionCount: questionCount ?? this.questionCount,
      choiceCount: choiceCount ?? this.choiceCount,
      answerKey: answerKey ?? this.answerKey,
      createdAt: createdAt ?? this.createdAt,
      gradingPeriod: gradingPeriod ?? this.gradingPeriod,
      gradeComponent: gradeComponent ?? this.gradeComponent,
      examPart: examPart ?? this.examPart,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<String>(classId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (questionCount.present) {
      map['question_count'] = Variable<int>(questionCount.value);
    }
    if (choiceCount.present) {
      map['choice_count'] = Variable<int>(choiceCount.value);
    }
    if (answerKey.present) {
      map['answer_key'] = Variable<String>(
        $ExamsTable.$converteranswerKey.toSql(answerKey.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (gradingPeriod.present) {
      map['grading_period'] = Variable<int>(gradingPeriod.value);
    }
    if (gradeComponent.present) {
      map['grade_component'] = Variable<String>(gradeComponent.value);
    }
    if (examPart.present) {
      map['exam_part'] = Variable<String>(examPart.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExamsCompanion(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('title: $title, ')
          ..write('questionCount: $questionCount, ')
          ..write('choiceCount: $choiceCount, ')
          ..write('answerKey: $answerKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('gradingPeriod: $gradingPeriod, ')
          ..write('gradeComponent: $gradeComponent, ')
          ..write('examPart: $examPart, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExamResultsTable extends ExamResults
    with TableInfo<$ExamResultsTable, ResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
    'exam_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exams (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _studentNumberMeta = const VerificationMeta(
    'studentNumber',
  );
  @override
  late final GeneratedColumn<int> studentNumber = GeneratedColumn<int>(
    'student_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<int?>, String> answers =
      GeneratedColumn<String>(
        'answers',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<int?>>($ExamResultsTable.$converteranswers);
  static const VerificationMeta _scannedAtMeta = const VerificationMeta(
    'scannedAt',
  );
  @override
  late final GeneratedColumn<DateTime> scannedAt = GeneratedColumn<DateTime>(
    'scanned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    examId,
    studentNumber,
    answers,
    scannedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exam_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('student_number')) {
      context.handle(
        _studentNumberMeta,
        studentNumber.isAcceptableOrUnknown(
          data['student_number']!,
          _studentNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studentNumberMeta);
    }
    if (data.containsKey('scanned_at')) {
      context.handle(
        _scannedAtMeta,
        scannedAt.isAcceptableOrUnknown(data['scanned_at']!, _scannedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_scannedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {examId, studentNumber};
  @override
  ResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResultRow(
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_id'],
      )!,
      studentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_number'],
      )!,
      answers: $ExamResultsTable.$converteranswers.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}answers'],
        )!,
      ),
      scannedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scanned_at'],
      )!,
    );
  }

  @override
  $ExamResultsTable createAlias(String alias) {
    return $ExamResultsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<int?>, String> $converteranswers =
      const ChoiceListConverter();
}

class ResultRow extends DataClass implements Insertable<ResultRow> {
  final String examId;
  final int studentNumber;
  final List<int?> answers;
  final DateTime scannedAt;
  const ResultRow({
    required this.examId,
    required this.studentNumber,
    required this.answers,
    required this.scannedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exam_id'] = Variable<String>(examId);
    map['student_number'] = Variable<int>(studentNumber);
    {
      map['answers'] = Variable<String>(
        $ExamResultsTable.$converteranswers.toSql(answers),
      );
    }
    map['scanned_at'] = Variable<DateTime>(scannedAt);
    return map;
  }

  ExamResultsCompanion toCompanion(bool nullToAbsent) {
    return ExamResultsCompanion(
      examId: Value(examId),
      studentNumber: Value(studentNumber),
      answers: Value(answers),
      scannedAt: Value(scannedAt),
    );
  }

  factory ResultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResultRow(
      examId: serializer.fromJson<String>(json['examId']),
      studentNumber: serializer.fromJson<int>(json['studentNumber']),
      answers: serializer.fromJson<List<int?>>(json['answers']),
      scannedAt: serializer.fromJson<DateTime>(json['scannedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'examId': serializer.toJson<String>(examId),
      'studentNumber': serializer.toJson<int>(studentNumber),
      'answers': serializer.toJson<List<int?>>(answers),
      'scannedAt': serializer.toJson<DateTime>(scannedAt),
    };
  }

  ResultRow copyWith({
    String? examId,
    int? studentNumber,
    List<int?>? answers,
    DateTime? scannedAt,
  }) => ResultRow(
    examId: examId ?? this.examId,
    studentNumber: studentNumber ?? this.studentNumber,
    answers: answers ?? this.answers,
    scannedAt: scannedAt ?? this.scannedAt,
  );
  ResultRow copyWithCompanion(ExamResultsCompanion data) {
    return ResultRow(
      examId: data.examId.present ? data.examId.value : this.examId,
      studentNumber: data.studentNumber.present
          ? data.studentNumber.value
          : this.studentNumber,
      answers: data.answers.present ? data.answers.value : this.answers,
      scannedAt: data.scannedAt.present ? data.scannedAt.value : this.scannedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResultRow(')
          ..write('examId: $examId, ')
          ..write('studentNumber: $studentNumber, ')
          ..write('answers: $answers, ')
          ..write('scannedAt: $scannedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(examId, studentNumber, answers, scannedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResultRow &&
          other.examId == this.examId &&
          other.studentNumber == this.studentNumber &&
          other.answers == this.answers &&
          other.scannedAt == this.scannedAt);
}

class ExamResultsCompanion extends UpdateCompanion<ResultRow> {
  final Value<String> examId;
  final Value<int> studentNumber;
  final Value<List<int?>> answers;
  final Value<DateTime> scannedAt;
  final Value<int> rowid;
  const ExamResultsCompanion({
    this.examId = const Value.absent(),
    this.studentNumber = const Value.absent(),
    this.answers = const Value.absent(),
    this.scannedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExamResultsCompanion.insert({
    required String examId,
    required int studentNumber,
    required List<int?> answers,
    required DateTime scannedAt,
    this.rowid = const Value.absent(),
  }) : examId = Value(examId),
       studentNumber = Value(studentNumber),
       answers = Value(answers),
       scannedAt = Value(scannedAt);
  static Insertable<ResultRow> custom({
    Expression<String>? examId,
    Expression<int>? studentNumber,
    Expression<String>? answers,
    Expression<DateTime>? scannedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (examId != null) 'exam_id': examId,
      if (studentNumber != null) 'student_number': studentNumber,
      if (answers != null) 'answers': answers,
      if (scannedAt != null) 'scanned_at': scannedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExamResultsCompanion copyWith({
    Value<String>? examId,
    Value<int>? studentNumber,
    Value<List<int?>>? answers,
    Value<DateTime>? scannedAt,
    Value<int>? rowid,
  }) {
    return ExamResultsCompanion(
      examId: examId ?? this.examId,
      studentNumber: studentNumber ?? this.studentNumber,
      answers: answers ?? this.answers,
      scannedAt: scannedAt ?? this.scannedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (studentNumber.present) {
      map['student_number'] = Variable<int>(studentNumber.value);
    }
    if (answers.present) {
      map['answers'] = Variable<String>(
        $ExamResultsTable.$converteranswers.toSql(answers.value),
      );
    }
    if (scannedAt.present) {
      map['scanned_at'] = Variable<DateTime>(scannedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExamResultsCompanion(')
          ..write('examId: $examId, ')
          ..write('studentNumber: $studentNumber, ')
          ..write('answers: $answers, ')
          ..write('scannedAt: $scannedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordNamesTable extends RecordNames
    with TableInfo<$RecordNamesTable, RecordNameRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordNamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _classIdMeta = const VerificationMeta(
    'classId',
  );
  @override
  late final GeneratedColumn<String> classId = GeneratedColumn<String>(
    'class_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES school_classes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _studentNumberMeta = const VerificationMeta(
    'studentNumber',
  );
  @override
  late final GeneratedColumn<int> studentNumber = GeneratedColumn<int>(
    'student_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentNameMeta = const VerificationMeta(
    'studentName',
  );
  @override
  late final GeneratedColumn<String> studentName = GeneratedColumn<String>(
    'student_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordNameMeta = const VerificationMeta(
    'recordName',
  );
  @override
  late final GeneratedColumn<String> recordName = GeneratedColumn<String>(
    'record_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    classId,
    studentNumber,
    studentName,
    recordName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'record_names';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordNameRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('class_id')) {
      context.handle(
        _classIdMeta,
        classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta),
      );
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('student_number')) {
      context.handle(
        _studentNumberMeta,
        studentNumber.isAcceptableOrUnknown(
          data['student_number']!,
          _studentNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studentNumberMeta);
    }
    if (data.containsKey('student_name')) {
      context.handle(
        _studentNameMeta,
        studentName.isAcceptableOrUnknown(
          data['student_name']!,
          _studentNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studentNameMeta);
    }
    if (data.containsKey('record_name')) {
      context.handle(
        _recordNameMeta,
        recordName.isAcceptableOrUnknown(data['record_name']!, _recordNameMeta),
      );
    } else if (isInserting) {
      context.missing(_recordNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {classId, studentNumber};
  @override
  RecordNameRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordNameRow(
      classId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_id'],
      )!,
      studentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_number'],
      )!,
      studentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_name'],
      )!,
      recordName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_name'],
      )!,
    );
  }

  @override
  $RecordNamesTable createAlias(String alias) {
    return $RecordNamesTable(attachedDatabase, alias);
  }
}

class RecordNameRow extends DataClass implements Insertable<RecordNameRow> {
  final String classId;
  final int studentNumber;

  /// The student's name when paired. A pairing is only reused while the
  /// student still has this name, so a new student given a freed-up number
  /// never inherits someone else's class-record row.
  final String studentName;
  final String recordName;
  const RecordNameRow({
    required this.classId,
    required this.studentNumber,
    required this.studentName,
    required this.recordName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['class_id'] = Variable<String>(classId);
    map['student_number'] = Variable<int>(studentNumber);
    map['student_name'] = Variable<String>(studentName);
    map['record_name'] = Variable<String>(recordName);
    return map;
  }

  RecordNamesCompanion toCompanion(bool nullToAbsent) {
    return RecordNamesCompanion(
      classId: Value(classId),
      studentNumber: Value(studentNumber),
      studentName: Value(studentName),
      recordName: Value(recordName),
    );
  }

  factory RecordNameRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordNameRow(
      classId: serializer.fromJson<String>(json['classId']),
      studentNumber: serializer.fromJson<int>(json['studentNumber']),
      studentName: serializer.fromJson<String>(json['studentName']),
      recordName: serializer.fromJson<String>(json['recordName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'classId': serializer.toJson<String>(classId),
      'studentNumber': serializer.toJson<int>(studentNumber),
      'studentName': serializer.toJson<String>(studentName),
      'recordName': serializer.toJson<String>(recordName),
    };
  }

  RecordNameRow copyWith({
    String? classId,
    int? studentNumber,
    String? studentName,
    String? recordName,
  }) => RecordNameRow(
    classId: classId ?? this.classId,
    studentNumber: studentNumber ?? this.studentNumber,
    studentName: studentName ?? this.studentName,
    recordName: recordName ?? this.recordName,
  );
  RecordNameRow copyWithCompanion(RecordNamesCompanion data) {
    return RecordNameRow(
      classId: data.classId.present ? data.classId.value : this.classId,
      studentNumber: data.studentNumber.present
          ? data.studentNumber.value
          : this.studentNumber,
      studentName: data.studentName.present
          ? data.studentName.value
          : this.studentName,
      recordName: data.recordName.present
          ? data.recordName.value
          : this.recordName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordNameRow(')
          ..write('classId: $classId, ')
          ..write('studentNumber: $studentNumber, ')
          ..write('studentName: $studentName, ')
          ..write('recordName: $recordName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(classId, studentNumber, studentName, recordName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordNameRow &&
          other.classId == this.classId &&
          other.studentNumber == this.studentNumber &&
          other.studentName == this.studentName &&
          other.recordName == this.recordName);
}

class RecordNamesCompanion extends UpdateCompanion<RecordNameRow> {
  final Value<String> classId;
  final Value<int> studentNumber;
  final Value<String> studentName;
  final Value<String> recordName;
  final Value<int> rowid;
  const RecordNamesCompanion({
    this.classId = const Value.absent(),
    this.studentNumber = const Value.absent(),
    this.studentName = const Value.absent(),
    this.recordName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordNamesCompanion.insert({
    required String classId,
    required int studentNumber,
    required String studentName,
    required String recordName,
    this.rowid = const Value.absent(),
  }) : classId = Value(classId),
       studentNumber = Value(studentNumber),
       studentName = Value(studentName),
       recordName = Value(recordName);
  static Insertable<RecordNameRow> custom({
    Expression<String>? classId,
    Expression<int>? studentNumber,
    Expression<String>? studentName,
    Expression<String>? recordName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (classId != null) 'class_id': classId,
      if (studentNumber != null) 'student_number': studentNumber,
      if (studentName != null) 'student_name': studentName,
      if (recordName != null) 'record_name': recordName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordNamesCompanion copyWith({
    Value<String>? classId,
    Value<int>? studentNumber,
    Value<String>? studentName,
    Value<String>? recordName,
    Value<int>? rowid,
  }) {
    return RecordNamesCompanion(
      classId: classId ?? this.classId,
      studentNumber: studentNumber ?? this.studentNumber,
      studentName: studentName ?? this.studentName,
      recordName: recordName ?? this.recordName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (classId.present) {
      map['class_id'] = Variable<String>(classId.value);
    }
    if (studentNumber.present) {
      map['student_number'] = Variable<int>(studentNumber.value);
    }
    if (studentName.present) {
      map['student_name'] = Variable<String>(studentName.value);
    }
    if (recordName.present) {
      map['record_name'] = Variable<String>(recordName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordNamesCompanion(')
          ..write('classId: $classId, ')
          ..write('studentNumber: $studentNumber, ')
          ..write('studentName: $studentName, ')
          ..write('recordName: $recordName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordPlacementsTable extends RecordPlacements
    with TableInfo<$RecordPlacementsTable, RecordPlacementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordPlacementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
    'exam_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exams (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sheetNameMeta = const VerificationMeta(
    'sheetName',
  );
  @override
  late final GeneratedColumn<String> sheetName = GeneratedColumn<String>(
    'sheet_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _columnIndexMeta = const VerificationMeta(
    'columnIndex',
  );
  @override
  late final GeneratedColumn<int> columnIndex = GeneratedColumn<int>(
    'column_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _highestScoreMeta = const VerificationMeta(
    'highestScore',
  );
  @override
  late final GeneratedColumn<int> highestScore = GeneratedColumn<int>(
    'highest_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    examId,
    sheetName,
    columnIndex,
    highestScore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'record_placements';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordPlacementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('sheet_name')) {
      context.handle(
        _sheetNameMeta,
        sheetName.isAcceptableOrUnknown(data['sheet_name']!, _sheetNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sheetNameMeta);
    }
    if (data.containsKey('column_index')) {
      context.handle(
        _columnIndexMeta,
        columnIndex.isAcceptableOrUnknown(
          data['column_index']!,
          _columnIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_columnIndexMeta);
    }
    if (data.containsKey('highest_score')) {
      context.handle(
        _highestScoreMeta,
        highestScore.isAcceptableOrUnknown(
          data['highest_score']!,
          _highestScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_highestScoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {examId};
  @override
  RecordPlacementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordPlacementRow(
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_id'],
      )!,
      sheetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sheet_name'],
      )!,
      columnIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}column_index'],
      )!,
      highestScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}highest_score'],
      )!,
    );
  }

  @override
  $RecordPlacementsTable createAlias(String alias) {
    return $RecordPlacementsTable(attachedDatabase, alias);
  }
}

class RecordPlacementRow extends DataClass
    implements Insertable<RecordPlacementRow> {
  final String examId;
  final String sheetName;
  final int columnIndex;

  /// The Highest Possible Score written there, to recognise the column.
  final int highestScore;
  const RecordPlacementRow({
    required this.examId,
    required this.sheetName,
    required this.columnIndex,
    required this.highestScore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exam_id'] = Variable<String>(examId);
    map['sheet_name'] = Variable<String>(sheetName);
    map['column_index'] = Variable<int>(columnIndex);
    map['highest_score'] = Variable<int>(highestScore);
    return map;
  }

  RecordPlacementsCompanion toCompanion(bool nullToAbsent) {
    return RecordPlacementsCompanion(
      examId: Value(examId),
      sheetName: Value(sheetName),
      columnIndex: Value(columnIndex),
      highestScore: Value(highestScore),
    );
  }

  factory RecordPlacementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordPlacementRow(
      examId: serializer.fromJson<String>(json['examId']),
      sheetName: serializer.fromJson<String>(json['sheetName']),
      columnIndex: serializer.fromJson<int>(json['columnIndex']),
      highestScore: serializer.fromJson<int>(json['highestScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'examId': serializer.toJson<String>(examId),
      'sheetName': serializer.toJson<String>(sheetName),
      'columnIndex': serializer.toJson<int>(columnIndex),
      'highestScore': serializer.toJson<int>(highestScore),
    };
  }

  RecordPlacementRow copyWith({
    String? examId,
    String? sheetName,
    int? columnIndex,
    int? highestScore,
  }) => RecordPlacementRow(
    examId: examId ?? this.examId,
    sheetName: sheetName ?? this.sheetName,
    columnIndex: columnIndex ?? this.columnIndex,
    highestScore: highestScore ?? this.highestScore,
  );
  RecordPlacementRow copyWithCompanion(RecordPlacementsCompanion data) {
    return RecordPlacementRow(
      examId: data.examId.present ? data.examId.value : this.examId,
      sheetName: data.sheetName.present ? data.sheetName.value : this.sheetName,
      columnIndex: data.columnIndex.present
          ? data.columnIndex.value
          : this.columnIndex,
      highestScore: data.highestScore.present
          ? data.highestScore.value
          : this.highestScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordPlacementRow(')
          ..write('examId: $examId, ')
          ..write('sheetName: $sheetName, ')
          ..write('columnIndex: $columnIndex, ')
          ..write('highestScore: $highestScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(examId, sheetName, columnIndex, highestScore);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordPlacementRow &&
          other.examId == this.examId &&
          other.sheetName == this.sheetName &&
          other.columnIndex == this.columnIndex &&
          other.highestScore == this.highestScore);
}

class RecordPlacementsCompanion extends UpdateCompanion<RecordPlacementRow> {
  final Value<String> examId;
  final Value<String> sheetName;
  final Value<int> columnIndex;
  final Value<int> highestScore;
  final Value<int> rowid;
  const RecordPlacementsCompanion({
    this.examId = const Value.absent(),
    this.sheetName = const Value.absent(),
    this.columnIndex = const Value.absent(),
    this.highestScore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordPlacementsCompanion.insert({
    required String examId,
    required String sheetName,
    required int columnIndex,
    required int highestScore,
    this.rowid = const Value.absent(),
  }) : examId = Value(examId),
       sheetName = Value(sheetName),
       columnIndex = Value(columnIndex),
       highestScore = Value(highestScore);
  static Insertable<RecordPlacementRow> custom({
    Expression<String>? examId,
    Expression<String>? sheetName,
    Expression<int>? columnIndex,
    Expression<int>? highestScore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (examId != null) 'exam_id': examId,
      if (sheetName != null) 'sheet_name': sheetName,
      if (columnIndex != null) 'column_index': columnIndex,
      if (highestScore != null) 'highest_score': highestScore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordPlacementsCompanion copyWith({
    Value<String>? examId,
    Value<String>? sheetName,
    Value<int>? columnIndex,
    Value<int>? highestScore,
    Value<int>? rowid,
  }) {
    return RecordPlacementsCompanion(
      examId: examId ?? this.examId,
      sheetName: sheetName ?? this.sheetName,
      columnIndex: columnIndex ?? this.columnIndex,
      highestScore: highestScore ?? this.highestScore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (sheetName.present) {
      map['sheet_name'] = Variable<String>(sheetName.value);
    }
    if (columnIndex.present) {
      map['column_index'] = Variable<int>(columnIndex.value);
    }
    if (highestScore.present) {
      map['highest_score'] = Variable<int>(highestScore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordPlacementsCompanion(')
          ..write('examId: $examId, ')
          ..write('sheetName: $sheetName, ')
          ..write('columnIndex: $columnIndex, ')
          ..write('highestScore: $highestScore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SchoolClassesTable schoolClasses = $SchoolClassesTable(this);
  late final $StudentsTable students = $StudentsTable(this);
  late final $ExamsTable exams = $ExamsTable(this);
  late final $ExamResultsTable examResults = $ExamResultsTable(this);
  late final $RecordNamesTable recordNames = $RecordNamesTable(this);
  late final $RecordPlacementsTable recordPlacements = $RecordPlacementsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    schoolClasses,
    students,
    exams,
    examResults,
    recordNames,
    recordPlacements,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'school_classes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('students', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'school_classes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exams', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exams',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exam_results', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'school_classes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('record_names', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exams',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('record_placements', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SchoolClassesTableCreateCompanionBuilder =
    SchoolClassesCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      Value<String?> gradingPolicy,
      Value<String?> subjectGroup,
      Value<int> rowid,
    });
typedef $$SchoolClassesTableUpdateCompanionBuilder =
    SchoolClassesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<String?> gradingPolicy,
      Value<String?> subjectGroup,
      Value<int> rowid,
    });

final class $$SchoolClassesTableReferences
    extends BaseReferences<_$AppDatabase, $SchoolClassesTable, ClassRow> {
  $$SchoolClassesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$StudentsTable, List<StudentRow>>
  _studentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.students,
    aliasName: 'school_classes__id__students__class_id',
  );

  $$StudentsTableProcessedTableManager get studentsRefs {
    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.classId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_studentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExamsTable, List<ExamRow>> _examsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.exams,
    aliasName: 'school_classes__id__exams__class_id',
  );

  $$ExamsTableProcessedTableManager get examsRefs {
    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.classId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_examsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecordNamesTable, List<RecordNameRow>>
  _recordNamesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recordNames,
    aliasName: 'school_classes__id__record_names__class_id',
  );

  $$RecordNamesTableProcessedTableManager get recordNamesRefs {
    final manager = $$RecordNamesTableTableManager(
      $_db,
      $_db.recordNames,
    ).filter((f) => f.classId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recordNamesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SchoolClassesTableFilterComposer
    extends Composer<_$AppDatabase, $SchoolClassesTable> {
  $$SchoolClassesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gradingPolicy => $composableBuilder(
    column: $table.gradingPolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectGroup => $composableBuilder(
    column: $table.subjectGroup,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> studentsRefs(
    Expression<bool> Function($$StudentsTableFilterComposer f) f,
  ) {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> examsRefs(
    Expression<bool> Function($$ExamsTableFilterComposer f) f,
  ) {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recordNamesRefs(
    Expression<bool> Function($$RecordNamesTableFilterComposer f) f,
  ) {
    final $$RecordNamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recordNames,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordNamesTableFilterComposer(
            $db: $db,
            $table: $db.recordNames,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SchoolClassesTableOrderingComposer
    extends Composer<_$AppDatabase, $SchoolClassesTable> {
  $$SchoolClassesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gradingPolicy => $composableBuilder(
    column: $table.gradingPolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectGroup => $composableBuilder(
    column: $table.subjectGroup,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchoolClassesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchoolClassesTable> {
  $$SchoolClassesTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get gradingPolicy => $composableBuilder(
    column: $table.gradingPolicy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectGroup => $composableBuilder(
    column: $table.subjectGroup,
    builder: (column) => column,
  );

  Expression<T> studentsRefs<T extends Object>(
    Expression<T> Function($$StudentsTableAnnotationComposer a) f,
  ) {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> examsRefs<T extends Object>(
    Expression<T> Function($$ExamsTableAnnotationComposer a) f,
  ) {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recordNamesRefs<T extends Object>(
    Expression<T> Function($$RecordNamesTableAnnotationComposer a) f,
  ) {
    final $$RecordNamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recordNames,
      getReferencedColumn: (t) => t.classId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordNamesTableAnnotationComposer(
            $db: $db,
            $table: $db.recordNames,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SchoolClassesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchoolClassesTable,
          ClassRow,
          $$SchoolClassesTableFilterComposer,
          $$SchoolClassesTableOrderingComposer,
          $$SchoolClassesTableAnnotationComposer,
          $$SchoolClassesTableCreateCompanionBuilder,
          $$SchoolClassesTableUpdateCompanionBuilder,
          (ClassRow, $$SchoolClassesTableReferences),
          ClassRow,
          PrefetchHooks Function({
            bool studentsRefs,
            bool examsRefs,
            bool recordNamesRefs,
          })
        > {
  $$SchoolClassesTableTableManager(_$AppDatabase db, $SchoolClassesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchoolClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchoolClassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchoolClassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> gradingPolicy = const Value.absent(),
                Value<String?> subjectGroup = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchoolClassesCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                gradingPolicy: gradingPolicy,
                subjectGroup: subjectGroup,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                Value<String?> gradingPolicy = const Value.absent(),
                Value<String?> subjectGroup = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchoolClassesCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                gradingPolicy: gradingPolicy,
                subjectGroup: subjectGroup,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SchoolClassesTable, ClassRow>(table),
                  $$SchoolClassesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                studentsRefs = false,
                examsRefs = false,
                recordNamesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (studentsRefs) db.students,
                    if (examsRefs) db.exams,
                    if (recordNamesRefs) db.recordNames,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (studentsRefs)
                        await $_getPrefetchedDataByColumns<
                          ClassRow,
                          $SchoolClassesTable,
                          StudentRow,
                          $StudentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SchoolClassesTableReferences
                              ._studentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SchoolClassesTableReferences(
                                db,
                                table,
                                p0,
                              ).studentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'class_id',
                          typedResults: items,
                        ),
                      if (examsRefs)
                        await $_getPrefetchedDataByColumns<
                          ClassRow,
                          $SchoolClassesTable,
                          ExamRow,
                          $ExamsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SchoolClassesTableReferences
                              ._examsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SchoolClassesTableReferences(
                                db,
                                table,
                                p0,
                              ).examsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'class_id',
                          typedResults: items,
                        ),
                      if (recordNamesRefs)
                        await $_getPrefetchedDataByColumns<
                          ClassRow,
                          $SchoolClassesTable,
                          RecordNameRow,
                          $RecordNamesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SchoolClassesTableReferences
                              ._recordNamesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SchoolClassesTableReferences(
                                db,
                                table,
                                p0,
                              ).recordNamesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'class_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SchoolClassesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchoolClassesTable,
      ClassRow,
      $$SchoolClassesTableFilterComposer,
      $$SchoolClassesTableOrderingComposer,
      $$SchoolClassesTableAnnotationComposer,
      $$SchoolClassesTableCreateCompanionBuilder,
      $$SchoolClassesTableUpdateCompanionBuilder,
      (ClassRow, $$SchoolClassesTableReferences),
      ClassRow,
      PrefetchHooks Function({
        bool studentsRefs,
        bool examsRefs,
        bool recordNamesRefs,
      })
    >;
typedef $$StudentsTableCreateCompanionBuilder = StudentsCompanion Function({
  required String classId,
  required int number,
  required String name,
  Value<int> rowid,
});
typedef $$StudentsTableUpdateCompanionBuilder = StudentsCompanion Function({
  Value<String> classId,
  Value<int> number,
  Value<String> name,
  Value<int> rowid,
});

final class $$StudentsTableReferences
    extends BaseReferences<_$AppDatabase, $StudentsTable, StudentRow> {
  $$StudentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SchoolClassesTable _classIdTable(_$AppDatabase db) =>
      db.schoolClasses.createAlias('students__class_id__school_classes__id');

  $$SchoolClassesTableProcessedTableManager get classId {
    final $_column = $_itemColumn<String>('class_id')!;

    final manager = $$SchoolClassesTableTableManager(
      $_db,
      $_db.schoolClasses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StudentsTableFilterComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$SchoolClassesTableFilterComposer get classId {
    final $$SchoolClassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.schoolClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolClassesTableFilterComposer(
            $db: $db,
            $table: $db.schoolClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudentsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$SchoolClassesTableOrderingComposer get classId {
    final $$SchoolClassesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.schoolClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolClassesTableOrderingComposer(
            $db: $db,
            $table: $db.schoolClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$SchoolClassesTableAnnotationComposer get classId {
    final $$SchoolClassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.schoolClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolClassesTableAnnotationComposer(
            $db: $db,
            $table: $db.schoolClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudentsTable,
          StudentRow,
          $$StudentsTableFilterComposer,
          $$StudentsTableOrderingComposer,
          $$StudentsTableAnnotationComposer,
          $$StudentsTableCreateCompanionBuilder,
          $$StudentsTableUpdateCompanionBuilder,
          (StudentRow, $$StudentsTableReferences),
          StudentRow,
          PrefetchHooks Function({bool classId})
        > {
  $$StudentsTableTableManager(_$AppDatabase db, $StudentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> classId = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentsCompanion(
                classId: classId,
                number: number,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String classId,
                required int number,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => StudentsCompanion.insert(
                classId: classId,
                number: number,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StudentsTable, StudentRow>(table),
                  $$StudentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({classId = false}) {
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
                    if (classId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.classId,
                        referencedTable: $$StudentsTableReferences
                            ._classIdTable(db),
                        referencedColumn: $$StudentsTableReferences
                            ._classIdTable(db)
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

typedef $$StudentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudentsTable,
      StudentRow,
      $$StudentsTableFilterComposer,
      $$StudentsTableOrderingComposer,
      $$StudentsTableAnnotationComposer,
      $$StudentsTableCreateCompanionBuilder,
      $$StudentsTableUpdateCompanionBuilder,
      (StudentRow, $$StudentsTableReferences),
      StudentRow,
      PrefetchHooks Function({bool classId})
    >;
typedef $$ExamsTableCreateCompanionBuilder = ExamsCompanion Function({
  required String id,
  required String classId,
  required String title,
  required int questionCount,
  required int choiceCount,
  required List<int?> answerKey,
  required DateTime createdAt,
  Value<int?> gradingPeriod,
  Value<String?> gradeComponent,
  Value<String?> examPart,
  Value<int> rowid,
});
typedef $$ExamsTableUpdateCompanionBuilder = ExamsCompanion Function({
  Value<String> id,
  Value<String> classId,
  Value<String> title,
  Value<int> questionCount,
  Value<int> choiceCount,
  Value<List<int?>> answerKey,
  Value<DateTime> createdAt,
  Value<int?> gradingPeriod,
  Value<String?> gradeComponent,
  Value<String?> examPart,
  Value<int> rowid,
});

final class $$ExamsTableReferences
    extends BaseReferences<_$AppDatabase, $ExamsTable, ExamRow> {
  $$ExamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SchoolClassesTable _classIdTable(_$AppDatabase db) =>
      db.schoolClasses.createAlias('exams__class_id__school_classes__id');

  $$SchoolClassesTableProcessedTableManager get classId {
    final $_column = $_itemColumn<String>('class_id')!;

    final manager = $$SchoolClassesTableTableManager(
      $_db,
      $_db.schoolClasses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExamResultsTable, List<ResultRow>>
  _examResultsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.examResults,
    aliasName: 'exams__id__exam_results__exam_id',
  );

  $$ExamResultsTableProcessedTableManager get examResultsRefs {
    final manager = $$ExamResultsTableTableManager(
      $_db,
      $_db.examResults,
    ).filter((f) => f.examId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_examResultsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecordPlacementsTable, List<RecordPlacementRow>>
  _recordPlacementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recordPlacements,
    aliasName: 'exams__id__record_placements__exam_id',
  );

  $$RecordPlacementsTableProcessedTableManager get recordPlacementsRefs {
    final manager = $$RecordPlacementsTableTableManager(
      $_db,
      $_db.recordPlacements,
    ).filter((f) => f.examId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recordPlacementsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExamsTableFilterComposer extends Composer<_$AppDatabase, $ExamsTable> {
  $$ExamsTableFilterComposer({
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

  ColumnFilters<int> get questionCount => $composableBuilder(
    column: $table.questionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get choiceCount => $composableBuilder(
    column: $table.choiceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<int?>, List<int>, String> get answerKey =>
      $composableBuilder(
        column: $table.answerKey,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gradingPeriod => $composableBuilder(
    column: $table.gradingPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gradeComponent => $composableBuilder(
    column: $table.gradeComponent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get examPart => $composableBuilder(
    column: $table.examPart,
    builder: (column) => ColumnFilters(column),
  );

  $$SchoolClassesTableFilterComposer get classId {
    final $$SchoolClassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.schoolClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolClassesTableFilterComposer(
            $db: $db,
            $table: $db.schoolClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> examResultsRefs(
    Expression<bool> Function($$ExamResultsTableFilterComposer f) f,
  ) {
    final $$ExamResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.examResults,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamResultsTableFilterComposer(
            $db: $db,
            $table: $db.examResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recordPlacementsRefs(
    Expression<bool> Function($$RecordPlacementsTableFilterComposer f) f,
  ) {
    final $$RecordPlacementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recordPlacements,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordPlacementsTableFilterComposer(
            $db: $db,
            $table: $db.recordPlacements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExamsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExamsTable> {
  $$ExamsTableOrderingComposer({
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

  ColumnOrderings<int> get questionCount => $composableBuilder(
    column: $table.questionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get choiceCount => $composableBuilder(
    column: $table.choiceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerKey => $composableBuilder(
    column: $table.answerKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gradingPeriod => $composableBuilder(
    column: $table.gradingPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gradeComponent => $composableBuilder(
    column: $table.gradeComponent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examPart => $composableBuilder(
    column: $table.examPart,
    builder: (column) => ColumnOrderings(column),
  );

  $$SchoolClassesTableOrderingComposer get classId {
    final $$SchoolClassesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.schoolClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolClassesTableOrderingComposer(
            $db: $db,
            $table: $db.schoolClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExamsTable> {
  $$ExamsTableAnnotationComposer({
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

  GeneratedColumn<int> get questionCount => $composableBuilder(
    column: $table.questionCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get choiceCount => $composableBuilder(
    column: $table.choiceCount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<int?>, String> get answerKey =>
      $composableBuilder(column: $table.answerKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get gradingPeriod => $composableBuilder(
    column: $table.gradingPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gradeComponent => $composableBuilder(
    column: $table.gradeComponent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get examPart =>
      $composableBuilder(column: $table.examPart, builder: (column) => column);

  $$SchoolClassesTableAnnotationComposer get classId {
    final $$SchoolClassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.schoolClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolClassesTableAnnotationComposer(
            $db: $db,
            $table: $db.schoolClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> examResultsRefs<T extends Object>(
    Expression<T> Function($$ExamResultsTableAnnotationComposer a) f,
  ) {
    final $$ExamResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.examResults,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.examResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recordPlacementsRefs<T extends Object>(
    Expression<T> Function($$RecordPlacementsTableAnnotationComposer a) f,
  ) {
    final $$RecordPlacementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recordPlacements,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordPlacementsTableAnnotationComposer(
            $db: $db,
            $table: $db.recordPlacements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExamsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExamsTable,
          ExamRow,
          $$ExamsTableFilterComposer,
          $$ExamsTableOrderingComposer,
          $$ExamsTableAnnotationComposer,
          $$ExamsTableCreateCompanionBuilder,
          $$ExamsTableUpdateCompanionBuilder,
          (ExamRow, $$ExamsTableReferences),
          ExamRow,
          PrefetchHooks Function({
            bool classId,
            bool examResultsRefs,
            bool recordPlacementsRefs,
          })
        > {
  $$ExamsTableTableManager(_$AppDatabase db, $ExamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> classId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> questionCount = const Value.absent(),
                Value<int> choiceCount = const Value.absent(),
                Value<List<int?>> answerKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> gradingPeriod = const Value.absent(),
                Value<String?> gradeComponent = const Value.absent(),
                Value<String?> examPart = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamsCompanion(
                id: id,
                classId: classId,
                title: title,
                questionCount: questionCount,
                choiceCount: choiceCount,
                answerKey: answerKey,
                createdAt: createdAt,
                gradingPeriod: gradingPeriod,
                gradeComponent: gradeComponent,
                examPart: examPart,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String classId,
                required String title,
                required int questionCount,
                required int choiceCount,
                required List<int?> answerKey,
                required DateTime createdAt,
                Value<int?> gradingPeriod = const Value.absent(),
                Value<String?> gradeComponent = const Value.absent(),
                Value<String?> examPart = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamsCompanion.insert(
                id: id,
                classId: classId,
                title: title,
                questionCount: questionCount,
                choiceCount: choiceCount,
                answerKey: answerKey,
                createdAt: createdAt,
                gradingPeriod: gradingPeriod,
                gradeComponent: gradeComponent,
                examPart: examPart,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExamsTable, ExamRow>(table),
                  $$ExamsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                classId = false,
                examResultsRefs = false,
                recordPlacementsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (examResultsRefs) db.examResults,
                    if (recordPlacementsRefs) db.recordPlacements,
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
                        if (classId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.classId,
                            referencedTable: $$ExamsTableReferences
                                ._classIdTable(db),
                            referencedColumn: $$ExamsTableReferences
                                ._classIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (examResultsRefs)
                        await $_getPrefetchedDataByColumns<
                          ExamRow,
                          $ExamsTable,
                          ResultRow,
                          $ExamResultsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ExamsTableReferences
                              ._examResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExamsTableReferences(
                                db,
                                table,
                                p0,
                              ).examResultsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'exam_id',
                          typedResults: items,
                        ),
                      if (recordPlacementsRefs)
                        await $_getPrefetchedDataByColumns<
                          ExamRow,
                          $ExamsTable,
                          RecordPlacementRow,
                          $RecordPlacementsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ExamsTableReferences
                              ._recordPlacementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExamsTableReferences(
                                db,
                                table,
                                p0,
                              ).recordPlacementsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'exam_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExamsTable,
      ExamRow,
      $$ExamsTableFilterComposer,
      $$ExamsTableOrderingComposer,
      $$ExamsTableAnnotationComposer,
      $$ExamsTableCreateCompanionBuilder,
      $$ExamsTableUpdateCompanionBuilder,
      (ExamRow, $$ExamsTableReferences),
      ExamRow,
      PrefetchHooks Function({
        bool classId,
        bool examResultsRefs,
        bool recordPlacementsRefs,
      })
    >;
typedef $$ExamResultsTableCreateCompanionBuilder =
    ExamResultsCompanion Function({
      required String examId,
      required int studentNumber,
      required List<int?> answers,
      required DateTime scannedAt,
      Value<int> rowid,
    });
typedef $$ExamResultsTableUpdateCompanionBuilder =
    ExamResultsCompanion Function({
      Value<String> examId,
      Value<int> studentNumber,
      Value<List<int?>> answers,
      Value<DateTime> scannedAt,
      Value<int> rowid,
    });

final class $$ExamResultsTableReferences
    extends BaseReferences<_$AppDatabase, $ExamResultsTable, ResultRow> {
  $$ExamResultsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExamsTable _examIdTable(_$AppDatabase db) =>
      db.exams.createAlias('exam_results__exam_id__exams__id');

  $$ExamsTableProcessedTableManager get examId {
    final $_column = $_itemColumn<String>('exam_id')!;

    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_examIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExamResultsTableFilterComposer
    extends Composer<_$AppDatabase, $ExamResultsTable> {
  $$ExamResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get studentNumber => $composableBuilder(
    column: $table.studentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<int?>, List<int>, String> get answers =>
      $composableBuilder(
        column: $table.answers,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get scannedAt => $composableBuilder(
    column: $table.scannedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ExamsTableFilterComposer get examId {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExamResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExamResultsTable> {
  $$ExamResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get studentNumber => $composableBuilder(
    column: $table.studentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answers => $composableBuilder(
    column: $table.answers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scannedAt => $composableBuilder(
    column: $table.scannedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExamsTableOrderingComposer get examId {
    final $$ExamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableOrderingComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExamResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExamResultsTable> {
  $$ExamResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get studentNumber => $composableBuilder(
    column: $table.studentNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<int?>, String> get answers =>
      $composableBuilder(column: $table.answers, builder: (column) => column);

  GeneratedColumn<DateTime> get scannedAt =>
      $composableBuilder(column: $table.scannedAt, builder: (column) => column);

  $$ExamsTableAnnotationComposer get examId {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExamResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExamResultsTable,
          ResultRow,
          $$ExamResultsTableFilterComposer,
          $$ExamResultsTableOrderingComposer,
          $$ExamResultsTableAnnotationComposer,
          $$ExamResultsTableCreateCompanionBuilder,
          $$ExamResultsTableUpdateCompanionBuilder,
          (ResultRow, $$ExamResultsTableReferences),
          ResultRow,
          PrefetchHooks Function({bool examId})
        > {
  $$ExamResultsTableTableManager(_$AppDatabase db, $ExamResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExamResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExamResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExamResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> examId = const Value.absent(),
                Value<int> studentNumber = const Value.absent(),
                Value<List<int?>> answers = const Value.absent(),
                Value<DateTime> scannedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamResultsCompanion(
                examId: examId,
                studentNumber: studentNumber,
                answers: answers,
                scannedAt: scannedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String examId,
                required int studentNumber,
                required List<int?> answers,
                required DateTime scannedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExamResultsCompanion.insert(
                examId: examId,
                studentNumber: studentNumber,
                answers: answers,
                scannedAt: scannedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExamResultsTable, ResultRow>(table),
                  $$ExamResultsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({examId = false}) {
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
                    if (examId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.examId,
                        referencedTable: $$ExamResultsTableReferences
                            ._examIdTable(db),
                        referencedColumn: $$ExamResultsTableReferences
                            ._examIdTable(db)
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

typedef $$ExamResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExamResultsTable,
      ResultRow,
      $$ExamResultsTableFilterComposer,
      $$ExamResultsTableOrderingComposer,
      $$ExamResultsTableAnnotationComposer,
      $$ExamResultsTableCreateCompanionBuilder,
      $$ExamResultsTableUpdateCompanionBuilder,
      (ResultRow, $$ExamResultsTableReferences),
      ResultRow,
      PrefetchHooks Function({bool examId})
    >;
typedef $$RecordNamesTableCreateCompanionBuilder =
    RecordNamesCompanion Function({
      required String classId,
      required int studentNumber,
      required String studentName,
      required String recordName,
      Value<int> rowid,
    });
typedef $$RecordNamesTableUpdateCompanionBuilder =
    RecordNamesCompanion Function({
      Value<String> classId,
      Value<int> studentNumber,
      Value<String> studentName,
      Value<String> recordName,
      Value<int> rowid,
    });

final class $$RecordNamesTableReferences
    extends BaseReferences<_$AppDatabase, $RecordNamesTable, RecordNameRow> {
  $$RecordNamesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SchoolClassesTable _classIdTable(_$AppDatabase db) => db.schoolClasses
      .createAlias('record_names__class_id__school_classes__id');

  $$SchoolClassesTableProcessedTableManager get classId {
    final $_column = $_itemColumn<String>('class_id')!;

    final manager = $$SchoolClassesTableTableManager(
      $_db,
      $_db.schoolClasses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecordNamesTableFilterComposer
    extends Composer<_$AppDatabase, $RecordNamesTable> {
  $$RecordNamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get studentNumber => $composableBuilder(
    column: $table.studentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentName => $composableBuilder(
    column: $table.studentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordName => $composableBuilder(
    column: $table.recordName,
    builder: (column) => ColumnFilters(column),
  );

  $$SchoolClassesTableFilterComposer get classId {
    final $$SchoolClassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.schoolClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolClassesTableFilterComposer(
            $db: $db,
            $table: $db.schoolClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordNamesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordNamesTable> {
  $$RecordNamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get studentNumber => $composableBuilder(
    column: $table.studentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentName => $composableBuilder(
    column: $table.studentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordName => $composableBuilder(
    column: $table.recordName,
    builder: (column) => ColumnOrderings(column),
  );

  $$SchoolClassesTableOrderingComposer get classId {
    final $$SchoolClassesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.schoolClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolClassesTableOrderingComposer(
            $db: $db,
            $table: $db.schoolClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordNamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordNamesTable> {
  $$RecordNamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get studentNumber => $composableBuilder(
    column: $table.studentNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get studentName => $composableBuilder(
    column: $table.studentName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordName => $composableBuilder(
    column: $table.recordName,
    builder: (column) => column,
  );

  $$SchoolClassesTableAnnotationComposer get classId {
    final $$SchoolClassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classId,
      referencedTable: $db.schoolClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolClassesTableAnnotationComposer(
            $db: $db,
            $table: $db.schoolClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordNamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordNamesTable,
          RecordNameRow,
          $$RecordNamesTableFilterComposer,
          $$RecordNamesTableOrderingComposer,
          $$RecordNamesTableAnnotationComposer,
          $$RecordNamesTableCreateCompanionBuilder,
          $$RecordNamesTableUpdateCompanionBuilder,
          (RecordNameRow, $$RecordNamesTableReferences),
          RecordNameRow,
          PrefetchHooks Function({bool classId})
        > {
  $$RecordNamesTableTableManager(_$AppDatabase db, $RecordNamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordNamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordNamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordNamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> classId = const Value.absent(),
                Value<int> studentNumber = const Value.absent(),
                Value<String> studentName = const Value.absent(),
                Value<String> recordName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordNamesCompanion(
                classId: classId,
                studentNumber: studentNumber,
                studentName: studentName,
                recordName: recordName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String classId,
                required int studentNumber,
                required String studentName,
                required String recordName,
                Value<int> rowid = const Value.absent(),
              }) => RecordNamesCompanion.insert(
                classId: classId,
                studentNumber: studentNumber,
                studentName: studentName,
                recordName: recordName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecordNamesTable, RecordNameRow>(table),
                  $$RecordNamesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({classId = false}) {
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
                    if (classId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.classId,
                        referencedTable: $$RecordNamesTableReferences
                            ._classIdTable(db),
                        referencedColumn: $$RecordNamesTableReferences
                            ._classIdTable(db)
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

typedef $$RecordNamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordNamesTable,
      RecordNameRow,
      $$RecordNamesTableFilterComposer,
      $$RecordNamesTableOrderingComposer,
      $$RecordNamesTableAnnotationComposer,
      $$RecordNamesTableCreateCompanionBuilder,
      $$RecordNamesTableUpdateCompanionBuilder,
      (RecordNameRow, $$RecordNamesTableReferences),
      RecordNameRow,
      PrefetchHooks Function({bool classId})
    >;
typedef $$RecordPlacementsTableCreateCompanionBuilder =
    RecordPlacementsCompanion Function({
      required String examId,
      required String sheetName,
      required int columnIndex,
      required int highestScore,
      Value<int> rowid,
    });
typedef $$RecordPlacementsTableUpdateCompanionBuilder =
    RecordPlacementsCompanion Function({
      Value<String> examId,
      Value<String> sheetName,
      Value<int> columnIndex,
      Value<int> highestScore,
      Value<int> rowid,
    });

final class $$RecordPlacementsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecordPlacementsTable,
          RecordPlacementRow
        > {
  $$RecordPlacementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExamsTable _examIdTable(_$AppDatabase db) =>
      db.exams.createAlias('record_placements__exam_id__exams__id');

  $$ExamsTableProcessedTableManager get examId {
    final $_column = $_itemColumn<String>('exam_id')!;

    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_examIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecordPlacementsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordPlacementsTable> {
  $$RecordPlacementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sheetName => $composableBuilder(
    column: $table.sheetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get columnIndex => $composableBuilder(
    column: $table.columnIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get highestScore => $composableBuilder(
    column: $table.highestScore,
    builder: (column) => ColumnFilters(column),
  );

  $$ExamsTableFilterComposer get examId {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordPlacementsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordPlacementsTable> {
  $$RecordPlacementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sheetName => $composableBuilder(
    column: $table.sheetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get columnIndex => $composableBuilder(
    column: $table.columnIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get highestScore => $composableBuilder(
    column: $table.highestScore,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExamsTableOrderingComposer get examId {
    final $$ExamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableOrderingComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordPlacementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordPlacementsTable> {
  $$RecordPlacementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sheetName =>
      $composableBuilder(column: $table.sheetName, builder: (column) => column);

  GeneratedColumn<int> get columnIndex => $composableBuilder(
    column: $table.columnIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get highestScore => $composableBuilder(
    column: $table.highestScore,
    builder: (column) => column,
  );

  $$ExamsTableAnnotationComposer get examId {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordPlacementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordPlacementsTable,
          RecordPlacementRow,
          $$RecordPlacementsTableFilterComposer,
          $$RecordPlacementsTableOrderingComposer,
          $$RecordPlacementsTableAnnotationComposer,
          $$RecordPlacementsTableCreateCompanionBuilder,
          $$RecordPlacementsTableUpdateCompanionBuilder,
          (RecordPlacementRow, $$RecordPlacementsTableReferences),
          RecordPlacementRow,
          PrefetchHooks Function({bool examId})
        > {
  $$RecordPlacementsTableTableManager(
    _$AppDatabase db,
    $RecordPlacementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordPlacementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordPlacementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordPlacementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> examId = const Value.absent(),
                Value<String> sheetName = const Value.absent(),
                Value<int> columnIndex = const Value.absent(),
                Value<int> highestScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordPlacementsCompanion(
                examId: examId,
                sheetName: sheetName,
                columnIndex: columnIndex,
                highestScore: highestScore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String examId,
                required String sheetName,
                required int columnIndex,
                required int highestScore,
                Value<int> rowid = const Value.absent(),
              }) => RecordPlacementsCompanion.insert(
                examId: examId,
                sheetName: sheetName,
                columnIndex: columnIndex,
                highestScore: highestScore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecordPlacementsTable, RecordPlacementRow>(
                    table,
                  ),
                  $$RecordPlacementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({examId = false}) {
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
                    if (examId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.examId,
                        referencedTable: $$RecordPlacementsTableReferences
                            ._examIdTable(db),
                        referencedColumn: $$RecordPlacementsTableReferences
                            ._examIdTable(db)
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

typedef $$RecordPlacementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordPlacementsTable,
      RecordPlacementRow,
      $$RecordPlacementsTableFilterComposer,
      $$RecordPlacementsTableOrderingComposer,
      $$RecordPlacementsTableAnnotationComposer,
      $$RecordPlacementsTableCreateCompanionBuilder,
      $$RecordPlacementsTableUpdateCompanionBuilder,
      (RecordPlacementRow, $$RecordPlacementsTableReferences),
      RecordPlacementRow,
      PrefetchHooks Function({bool examId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SchoolClassesTableTableManager get schoolClasses =>
      $$SchoolClassesTableTableManager(_db, _db.schoolClasses);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db, _db.students);
  $$ExamsTableTableManager get exams =>
      $$ExamsTableTableManager(_db, _db.exams);
  $$ExamResultsTableTableManager get examResults =>
      $$ExamResultsTableTableManager(_db, _db.examResults);
  $$RecordNamesTableTableManager get recordNames =>
      $$RecordNamesTableTableManager(_db, _db.recordNames);
  $$RecordPlacementsTableTableManager get recordPlacements =>
      $$RecordPlacementsTableTableManager(_db, _db.recordPlacements);
}
