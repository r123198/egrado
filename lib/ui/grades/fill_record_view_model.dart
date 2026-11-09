import 'dart:typed_data';
import 'dart:ui';

import 'package:egrado/class_record/class_record_fill.dart';
import 'package:egrado/class_record/name_match.dart';
import 'package:egrado/data/repositories/class_record_repository.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/domain/grade_book.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/services/class_record_engine.dart';
import 'package:egrado/services/class_record_file_service.dart';
import 'package:egrado/ui/core/view_model.dart';

/// Where the teacher is in filling their E-Class Record.
enum FillStep {
  /// Explains what will happen; waiting for the file.
  choose,

  /// Reading the chosen file.
  reading,

  /// Learners matched; teacher checks names before filling.
  review,

  /// Writing the scores.
  filling,

  /// Filled copy is ready to save or share.
  done,
}

enum FileOutcome { done, cancelled, failed }

/// Fills the teacher's own E-Class Record (.xlsx) with every counted test's
/// Highest Possible Score and raw scores.
class FillRecordViewModel extends ViewModel {
  FillRecordViewModel({
    required this.classId,
    required ClassRepository classes,
    required ExamRepository exams,
    required this._records,
    required this._files,
    required this._engine,
  }) {
    listen(classes.watchClass(classId), (c) {
      _schoolClass = c;
      notifyListeners();
    });
    listen(exams.watchOverviews(classId), (list) {
      _exams = [for (final o in list) o.exam];
      notifyListeners();
    });
    listen(_records.watchClassResults(classId), (list) {
      _results = list;
      notifyListeners();
    });
  }

  final String classId;
  final ClassRecordRepository _records;
  final ClassRecordFileService _files;
  final ClassRecordEngine _engine;

  SchoolClass? _schoolClass;
  List<Exam>? _exams;
  List<ExamResult>? _results;

  FillStep _step = FillStep.choose;
  RecordProblem? _problem;
  bool _fileError = false;
  String _fileName = '';
  Uint8List? _source;
  RecordSummary? _summary;
  Map<int, String> _pairs = const {};

  /// Pairs the teacher has picked or confirmed, or that came from last time.
  Set<int> _sure = const {};
  FilledRecord? _filled;

  bool get isLoading =>
      _schoolClass == null || _exams == null || _results == null;

  FillStep get step => _step;

  /// Why the last chosen file can't be used; null when fine.
  RecordProblem? get problem => _problem;

  /// The phone couldn't open the file at all.
  bool get fileError => _fileError;

  List<Student> get students => _schoolClass?.students ?? const [];

  /// "Term" or "Quarter", from the class's grading rules.
  String get periodName => _schoolClass?.gradingPolicy.periodName ?? 'Term';

  /// Learner names found in the class record.
  List<String> get recordNames => _summary?.learnerNames ?? const [];

  List<String> get periodSheets => _summary?.periodSheets ?? const [];

  /// Student number → chosen class-record name.
  Map<int, String> get pairs => Map.unmodifiable(_pairs);

  List<Student> get unmatched => [
    for (final s in students)
      if (!_pairs.containsKey(s.number)) s,
  ];

  /// Automatic matches that aren't exact ("Maria Santos" ↔ "SANTOS, MARIA
  /// CLARA"); the teacher confirms each before filling.
  List<Student> get toConfirm => [
    for (final s in students)
      if (_pairs.containsKey(s.number) && !_sure.contains(s.number)) s,
  ];

  bool needsConfirming(int studentNumber) =>
      _pairs.containsKey(studentNumber) && !_sure.contains(studentNumber);

  bool get canFill => _step == FillStep.review && toConfirm.isEmpty;

  /// Tests that will be written (counted, with scanned papers).
  List<RecordActivity> get activities => recordActivities(
    _schoolClass?.gradingPolicy ?? policyById(null),
    _exams ?? const [],
    _results ?? const [],
  );

  FillReport? get report => _filled?.report;

  /// "Grade 7 – Rizal (filled).xlsx" style name for the saved copy.
  String get outputName {
    final base = _fileName.toLowerCase().endsWith('.xlsx')
        ? _fileName.substring(0, _fileName.length - 5)
        : _fileName;
    return '${base.isEmpty ? 'Class record' : base} (eGrado).xlsx';
  }

  Future<void> chooseFile() async {
    _problem = null;
    _fileError = false;
    final PickedWorkbook? picked;
    try {
      picked = await _files.pickWorkbook();
    } on ClassRecordFileException {
      _fileError = true;
      notifyListeners();
      return;
    }
    if (picked == null) return;
    _step = FillStep.reading;
    notifyListeners();
    try {
      final summary = await _engine.inspect(picked.bytes);
      final saved = await _records.getRecordNames(classId);
      _fileName = picked.name;
      _source = picked.bytes;
      _summary = summary;
      _pairs = _initialPairs(saved, summary.learnerNames);
      _sure = {
        for (final MapEntry(key: n, value: name) in _pairs.entries)
          if (saved[n] == name || _isExact(n, name)) n,
      };
      _step = FillStep.review;
    } on RecordProblemException catch (e) {
      _problem = e.problem;
      _step = FillStep.choose;
    } on Exception {
      _fileError = true;
      _step = FillStep.choose;
    }
    notifyListeners();
  }

  /// Names chosen last time (if still in the record), then automatic
  /// matches for everyone else.
  Map<int, String> _initialPairs(
    Map<int, String> saved,
    List<String> recordNames,
  ) {
    final inRecord = recordNames.toSet();
    final pairs = <int, String>{
      for (final MapEntry(key: n, value: name) in saved.entries)
        if (inRecord.contains(name) && students.any((s) => s.number == n))
          n: name,
    };
    final taken = pairs.values.toSet();
    final auto = matchNames(
      {
        for (final s in students)
          if (!pairs.containsKey(s.number)) s.number: s.name,
      },
      [
        for (final r in recordNames)
          if (!taken.contains(r)) r,
      ],
    );
    return {...pairs, ...auto};
  }

  bool _isExact(int studentNumber, String recordName) {
    final student = _schoolClass?.studentByNumber(studentNumber);
    return student != null && isExactNameMatch(student.name, recordName);
  }

  /// Teacher picks (or clears, with null) the record name for a student.
  /// A name can belong to only one student.
  void pair(int studentNumber, String? recordName) {
    final losing = {
      for (final MapEntry(key: n, value: name) in _pairs.entries)
        if (n != studentNumber && name == recordName) n,
    };
    _pairs = {
      for (final MapEntry(key: n, value: name) in _pairs.entries)
        if (n != studentNumber && !losing.contains(n)) n: name,
      studentNumber: ?recordName,
    };
    _sure = {..._sure.difference(losing), studentNumber};
    notifyListeners();
  }

  /// Teacher says an inexact automatic match is the right learner.
  void confirm(int studentNumber) {
    _sure = {..._sure, studentNumber};
    notifyListeners();
  }

  /// Record names nobody has been paired with yet, plus [current].
  List<String> namesAvailableFor(int studentNumber) {
    final used = {
      for (final MapEntry(key: n, value: name) in _pairs.entries)
        if (n != studentNumber) name,
    };
    return [
      for (final r in recordNames)
        if (!used.contains(r)) r,
    ];
  }

  Future<bool> fill() async {
    final source = _source;
    // Also guards against a double tap: the step leaves review at once.
    if (source == null || !canFill) return false;
    _step = FillStep.filling;
    notifyListeners();
    final pairs = _pairs;
    try {
      final previous = await _records.getPlacements(classId);
      final filled = await _engine.fill(
        source,
        activities: activities,
        recordNames: pairs,
        previous: previous,
      );
      await _records.saveFill(
        classId,
        names: pairs,
        placements: filled.report.placements,
      );
      _filled = filled;
      _step = FillStep.done;
      notifyListeners();
      return true;
    } on RecordProblemException catch (e) {
      _problem = e.problem;
    } on Exception {
      _fileError = true;
    }
    _step = FillStep.review;
    notifyListeners();
    return false;
  }

  Future<FileOutcome> save() async {
    final filled = _filled;
    if (filled == null) return FileOutcome.failed;
    try {
      final saved = await _files.saveWorkbook(outputName, filled.bytes);
      return saved ? FileOutcome.done : FileOutcome.cancelled;
    } on ClassRecordFileException {
      return FileOutcome.failed;
    }
  }

  Future<FileOutcome> share({Rect? origin}) async {
    final filled = _filled;
    if (filled == null) return FileOutcome.failed;
    try {
      await _files.shareWorkbook(outputName, filled.bytes, origin: origin);
      return FileOutcome.done;
    } on ClassRecordFileException {
      return FileOutcome.failed;
    }
  }

  /// Start over with another file.
  void reset() {
    _step = FillStep.choose;
    _problem = null;
    _fileError = false;
    _source = null;
    _summary = null;
    _filled = null;
    _pairs = const {};
    _sure = const {};
    notifyListeners();
  }

  String studentName(int number) =>
      _schoolClass?.studentByNumber(number)?.name ?? 'Student $number';
}
