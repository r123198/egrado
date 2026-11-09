import 'dart:typed_data';
import 'dart:ui';

import 'package:egrado/class_record/cell_ref.dart';
import 'package:egrado/class_record/class_record_fill.dart';
import 'package:egrado/class_record/xlsx_workbook.dart';
import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/data/repositories/class_record_repository.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/result_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/services/class_record_engine.dart';
import 'package:egrado/services/class_record_file_service.dart';
import 'package:egrado/ui/core/view_model.dart';
import 'package:egrado/ui/exam_form/exam_form_view_model.dart';
import 'package:egrado/ui/grades/fill_record_view_model.dart';
import 'package:egrado/ui/grades/grades_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/seed.dart';
import '../class_record/class_record_test.dart' as ecr;

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

/// Hands the view model a chosen file and keeps what it saves.
class FakeRecordFiles implements ClassRecordFileService {
  PickedWorkbook? toPick;
  bool failPick = false;
  Uint8List? saved;
  String? savedName;

  @override
  Future<PickedWorkbook?> pickWorkbook() async {
    if (failPick) throw const ClassRecordFileException();
    return toPick;
  }

  @override
  Future<bool> saveWorkbook(String fileName, Uint8List bytes) async {
    savedName = fileName;
    saved = bytes;
    return true;
  }

  @override
  Future<void> shareWorkbook(
    String fileName,
    Uint8List bytes, {
    Rect? origin,
  }) async {}
}

/// The real engine, run on the test's own thread.
class SyncEngine implements ClassRecordEngine {
  @override
  Future<RecordSummary> inspect(Uint8List bytes) async => inspectRecord(bytes);

  @override
  Future<FilledRecord> fill(
    Uint8List bytes, {
    required List<RecordActivity> activities,
    required Map<int, String> recordNames,
    required Map<String, ColumnPlacement> previous,
  }) async => fillRecord(
    bytes,
    activities: activities,
    recordNames: recordNames,
    previous: previous,
  );
}

const _ww1 = GradeTag(period: 1, component: GradeComponent.writtenWork);

void main() {
  late AppDatabase db;
  late ClassRepository classes;
  late ExamRepository exams;
  late ResultRepository results;
  late ClassRecordRepository records;
  final viewModels = <ViewModel>[];

  T track<T extends ViewModel>(T vm) {
    viewModels.add(vm);
    return vm;
  }

  /// A 5-question test with key A B C D A, tagged [tag].
  Future<String> addTest(String title, GradeTag? tag) async {
    final id = await exams.createExam(
      classId: 'c1',
      title: title,
      questionCount: 5,
      choiceCount: 4,
      gradeTag: tag,
    );
    final exam = Exam(
      id: id,
      classId: 'c1',
      title: title,
      questionCount: 5,
      choiceCount: 4,
      answerKey: const [0, 1, 2, 3, 0],
      createdAt: DateTime(2026),
      gradeTag: tag,
    );
    await exams.updateExam(exam);
    return id;
  }

  setUp(() async {
    db = memoryDatabase();
    classes = DriftClassRepository(db);
    exams = DriftExamRepository(db);
    results = DriftResultRepository(db);
    records = DriftClassRecordRepository(db);
    await seedSchool(
      db,
      results: [
        testResult(1, [0, 1, 2, 3, 0]), // 5/5
        testResult(2, [0, 1, 2, 3, 3]), // 4/5
        testResult(3, [1, 1, 2, 3, 3]), // 3/5
      ],
    );
    await exams.updateExam(testExam().copyWith(gradeTag: () => _ww1));
  });

  tearDown(() async {
    for (final vm in viewModels) {
      vm.dispose();
    }
    viewModels.clear();
    await db.close();
  });

  group('storage', () {
    test('a test keeps what it counts toward', () async {
      const tag = GradeTag(
        period: 2,
        component: GradeComponent.exam,
        examPart: ExamPart.termExam,
      );
      final id = await addTest('Term exam', tag);
      final saved = await exams.watchExam(id).first;
      expect(saved?.gradeTag, tag);
    });

    test('"not counted" is stored as no tag', () async {
      final id = await addTest('Practice', null);
      expect((await exams.watchExam(id).first)?.gradeTag, isNull);
    });

    test('a class keeps its grading rules and subject', () async {
      await classes.setGrading(
        'c1',
        policyId: do8s2015.id,
        subjectGroupId: 'math_science',
      );
      final c = await classes.watchClass('c1').first;
      expect(c?.gradingPolicy, do8s2015);
      expect(c?.subjectGroup?.weights, const ComponentWeights(40, 40, 20));
    });

    test(
      'remembers record names and placements; cleans up with the test',
      () async {
        await records.saveFill(
          'c1',
          names: {1: 'DELA CRUZ, JUAN A.'},
          placements: {'e1': const ColumnPlacement('TERM 1', 6, 5)},
        );
        expect(await records.getRecordNames('c1'), {1: 'DELA CRUZ, JUAN A.'});
        expect(await records.getPlacements('c1'), {
          'e1': const ColumnPlacement('TERM 1', 6, 5),
        });
        await exams.deleteExam('e1');
        expect(await records.getPlacements('c1'), isEmpty);
      },
    );

    test('class results cover every test of the class', () async {
      await addTest('Quiz 2', _ww1);
      final all = await records.watchClassResults('c1').first;
      expect(all.map((r) => r.studentNumber), unorderedEquals([1, 2, 3]));
    });
  });

  group('GradesViewModel', () {
    GradesViewModel make() => track(
      GradesViewModel(
        classId: 'c1',
        classes: classes,
        exams: exams,
        records: records,
      ),
    );

    test('no grades until the subject is chosen', () async {
      final vm = make();
      await _settle();
      expect(vm.subject, isNull);
      expect(vm.lines, isEmpty);
    });

    test('shows component scores and what is still missing', () async {
      await classes.setGrading(
        'c1',
        policyId: do015Sy2026.id,
        subjectGroupId: 'core',
      );
      final vm = make();
      await _settle();
      final first = vm.lines.first;
      expect(
        first.grade.components[GradeComponent.writtenWork]!.percentage,
        100,
      );
      expect(first.grade.grade, isNull);
      expect(vm.missingComponents, [
        GradeComponent.performanceTask,
        GradeComponent.exam,
      ]);
    });

    test('computes the term grade once every component has a test', () async {
      await classes.setGrading(
        'c1',
        policyId: do015Sy2026.id,
        subjectGroupId: 'core',
      );
      final pt = await addTest(
        'PT',
        const GradeTag(period: 1, component: GradeComponent.performanceTask),
      );
      final te = await addTest(
        'TE',
        const GradeTag(
          period: 1,
          component: GradeComponent.exam,
          examPart: ExamPart.termExam,
        ),
      );
      for (final id in [pt, te]) {
        await results.saveResult(testResult(1, [0, 1, 2, 3, 0], exam: id));
      }
      final vm = make();
      await _settle();
      expect(vm.missingComponents, isEmpty);
      expect(vm.lines.first.grade.grade, 100);
      // Student 2 has no PT or TE paper: counted as 0 and flagged.
      expect(vm.lines[1].grade.missedActivities, 2);
    });

    test('flags tests set to a term the rules no longer have', () async {
      await addTest(
        'Q4 exam',
        const GradeTag(period: 4, component: GradeComponent.writtenWork),
      );
      final vm = make();
      await _settle();
      expect(vm.outOfRangeCount, 1);
    });

    test('counts tests that are not tagged yet', () async {
      await addTest('Practice', null);
      final vm = make();
      await _settle();
      expect(vm.untaggedCount, 1);
    });
  });

  group('FillRecordViewModel', () {
    late FakeRecordFiles files;

    FillRecordViewModel make() => track(
      FillRecordViewModel(
        classId: 'c1',
        classes: classes,
        exams: exams,
        records: records,
        files: files,
        engine: SyncEngine(),
      ),
    );

    setUp(() {
      files = FakeRecordFiles()
        ..toPick = PickedWorkbook(
          'Science 7.xlsx',
          ecr.withLearners(ecr.g2to10).encode(),
        );
    });

    test('matches names it can and asks about the rest', () async {
      final vm = make();
      await _settle();
      await vm.chooseFile();
      expect(vm.step, FillStep.review);
      expect(vm.recordNames, hasLength(3));
      // "Dela Cruz, Juan" ↔ "DELA CRUZ, JUAN A."; the others differ.
      expect(vm.pairs, {1: 'DELA CRUZ, JUAN A.'});
      expect(vm.unmatched.map((s) => s.number), [2, 3]);
      expect(vm.namesAvailableFor(2), isNot(contains('DELA CRUZ, JUAN A.')));
    });

    test('a record name can belong to only one student', () async {
      final vm = make();
      await _settle();
      await vm.chooseFile();
      vm.pair(2, 'DELA CRUZ, JUAN A.');
      expect(vm.pairs, {2: 'DELA CRUZ, JUAN A.'});
    });

    test('fills, saves, and remembers for next time', () async {
      final vm = make();
      await _settle();
      await vm.chooseFile();
      vm.pair(2, 'SANTOS, PEDRO');
      expect(await vm.fill(), isTrue);
      expect(vm.step, FillStep.done);
      final report = vm.report!;
      expect(report.outcomes.single.columnLabel, 'TERM 1 · WW 1');
      expect(report.studentsNotInRecord, {3});

      expect(await vm.save(), FileOutcome.done);
      expect(files.savedName, 'Science 7 (eGrado).xlsx');
      final saved = XlsxWorkbook.decode(files.saved!);
      num? at(String ref) =>
          saved.sheet('TERM 1')!.cell(CellRef.tryParse(ref)!)?.number;
      expect(at('F15'), 5); // HPS
      expect(at('F18'), 5); // Dela Cruz
      expect(at('F19'), 4); // Santos (picked by hand)
      expect(at('F69'), isNull); // Reyes not paired: left blank

      // The next fill restores the hand-picked pair and the same column.
      files.toPick = PickedWorkbook('Science 7 (eGrado).xlsx', files.saved!);
      final again = make();
      await _settle();
      await again.chooseFile();
      expect(again.pairs[2], 'SANTOS, PEDRO');
      await again.fill();
      expect(again.report!.outcomes.single.columnLabel, 'TERM 1 · WW 1');
    });

    test('an inexact automatic match must be confirmed first', () async {
      // "Reyes, Ana" isn't in the record; rename to a partial match.
      await classes.renameStudent('c1', 3, 'Maria Reyes');
      final vm = make();
      await _settle();
      await vm.chooseFile();
      expect(vm.pairs[3], 'REYES, MARIA CLARA B.');
      expect(vm.needsConfirming(3), isTrue);
      expect(vm.canFill, isFalse);
      expect(await vm.fill(), isFalse);
      vm.confirm(3);
      expect(vm.canFill, isTrue);
    });

    test('a new student given a freed-up number gets no old pairing', () async {
      final first = make();
      await _settle();
      await first.chooseFile();
      first.pair(2, 'SANTOS, PEDRO');
      await first.fill();

      await classes.removeStudent('c1', 2);
      await classes.addStudents('c1', const [
        Student(number: 2, name: 'Bautista, Carlo'),
      ]);
      final again = make();
      await _settle();
      await again.chooseFile();
      expect(again.pairs.containsKey(2), isFalse);
      // Juan was matched exactly and keeps his pairing.
      expect(again.pairs[1], 'DELA CRUZ, JUAN A.');
    });

    test('a test with an unfinished key is reported, not written', () async {
      await exams.updateExam(
        testExam(key: [0, 1, null, 3, 0]).copyWith(gradeTag: () => _ww1),
      );
      final vm = make();
      await _settle();
      await vm.chooseFile();
      await vm.fill();
      expect(vm.report!.outcomes.single.skipReason, SkipReason.noHighestScore);
    });

    test('a QA-tagged exam counts as the Term Exam under DO 015', () async {
      await exams.updateExam(
        testExam().copyWith(
          gradeTag: () => const GradeTag(
            period: 1,
            component: GradeComponent.exam,
            examPart: ExamPart.quarterlyAssessment,
          ),
        ),
      );
      final vm = make();
      await _settle();
      expect(vm.activities.single.examPart, ExamPart.termExam);
    });

    test('explains a file that is not a workbook', () async {
      files.toPick = PickedWorkbook('notes.xlsx', Uint8List.fromList([1, 2]));
      final vm = make();
      await _settle();
      await vm.chooseFile();
      expect(vm.step, FillStep.choose);
      expect(vm.problem, RecordProblem.notAWorkbook);
    });

    test('explains a class record without learner names', () async {
      files.toPick = PickedWorkbook('blank.xlsx', ecr.g2to10.bytes());
      final vm = make();
      await _settle();
      await vm.chooseFile();
      expect(vm.problem, RecordProblem.noLearners);
    });

    test('cancelling the file picker changes nothing', () async {
      files.toPick = null;
      final vm = make();
      await _settle();
      await vm.chooseFile();
      expect(vm.step, FillStep.choose);
      expect(vm.problem, isNull);
    });

    test('a picker failure is reported plainly', () async {
      files.failPick = true;
      final vm = make();
      await _settle();
      await vm.chooseFile();
      expect(vm.fileError, isTrue);
    });

    test('only counted tests with scanned papers are filled', () async {
      await addTest('Practice', null);
      await addTest('Not scanned yet', _ww1);
      final vm = make();
      await _settle();
      expect(vm.activities.map((a) => a.id), ['e1']);
    });
  });

  group('ExamFormViewModel grade tag', () {
    test('a new test counts as Written Work in the latest term', () async {
      await exams.updateExam(
        testExam().copyWith(
          gradeTag: () =>
              const GradeTag(period: 2, component: GradeComponent.writtenWork),
        ),
      );
      final vm = track(
        ExamFormViewModel(classId: 'c1', exams: exams, classes: classes),
      );
      await _settle();
      expect(vm.period, 2);
      expect(vm.kind.component, GradeComponent.writtenWork);
    });

    test('offers ST1/ST2/TE under DO 015 and QA under DO 8', () async {
      final vm = track(
        ExamFormViewModel(classId: 'c1', exams: exams, classes: classes),
      );
      await _settle();
      expect(vm.kinds.map((k) => k.examPart).whereType<ExamPart>(), [
        ExamPart.summativeTest1,
        ExamPart.summativeTest2,
        ExamPart.termExam,
      ]);
      await classes.setGrading(
        'c1',
        policyId: do8s2015.id,
        subjectGroupId: null,
      );
      await _settle();
      expect(vm.kinds.map((k) => k.examPart).whereType<ExamPart>(), [
        ExamPart.quarterlyAssessment,
      ]);
      expect(vm.policy.periodCount, 4);
    });

    test('saves the chosen tag, or none for practice', () async {
      final vm = track(
        ExamFormViewModel(classId: 'c1', exams: exams, classes: classes),
      );
      await _settle();
      vm
        ..setTitle('Unit test')
        ..setKind(vm.kinds.firstWhere((k) => k.examPart == ExamPart.termExam))
        ..setPeriod(3);
      await vm.save();
      final saved = await exams.watchExam(vm.savedExamId!).first;
      expect(
        saved?.gradeTag,
        const GradeTag(
          period: 3,
          component: GradeComponent.exam,
          examPart: ExamPart.termExam,
        ),
      );

      final practice = track(
        ExamFormViewModel(classId: 'c1', exams: exams, classes: classes),
      );
      await _settle();
      practice
        ..setTitle('Drill')
        ..setKind(GradeKind.notCounted);
      await practice.save();
      expect(
        (await exams.watchExam(practice.savedExamId!).first)?.gradeTag,
        isNull,
      );
    });
  });
}
