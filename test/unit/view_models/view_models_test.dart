import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/result_repository.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/omr/omr_reading.dart';
import 'package:egrado/services/name_list_reader.dart';
import 'package:egrado/services/photo_service.dart';
import 'package:egrado/ui/answer_key/answer_key_view_model.dart';
import 'package:egrado/ui/core/view_model.dart';
import 'package:egrado/ui/exam/exam_view_model.dart';
import 'package:egrado/ui/exam_form/exam_form_view_model.dart';
import 'package:egrado/ui/scan/result_review_view_model.dart';
import 'package:egrado/ui/scan/scan_session_view_model.dart';
import 'package:egrado/ui/students/add_students_view_model.dart';
import 'package:egrado/ui/students/students_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';
import '../../support/seed.dart';

const _clear = MarkStatus.clear;

/// Lets watched queries deliver their first results.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late AppDatabase db;
  late ClassRepository classes;
  late ExamRepository exams;
  late ResultRepository results;
  final viewModels = <ViewModel>[];

  T track<T extends ViewModel>(T vm) {
    viewModels.add(vm);
    return vm;
  }

  setUp(() async {
    db = memoryDatabase();
    classes = DriftClassRepository(db);
    exams = DriftExamRepository(db);
    results = DriftResultRepository(db);
    await seedSchool(
      db,
      results: [
        testResult(1, [0, 1, 2, 3, 0]),
      ],
    );
  });

  tearDown(() async {
    for (final vm in viewModels) {
      vm.dispose();
    }
    viewModels.clear();
    await db.close();
  });

  group('ExamViewModel', () {
    late FakePrintService printer;
    late FakeExportService exporter;

    ExamViewModel build() => track(
      ExamViewModel(
        examId: 'e1',
        exams: exams,
        classes: classes,
        results: results,
        printer: printer = FakePrintService(),
        exporter: exporter = FakeExportService(),
      ),
    );

    test('lists every student with their score or not checked', () async {
      final vm = build();
      await _settle();
      expect(vm.isLoading, isFalse);
      expect(vm.scoreLines.map((l) => '${l.number}:${l.score}'), [
        '1:5',
        '2:null',
        '3:null',
      ]);
      expect(vm.summary.checked, 1);
      expect(vm.summary.average, 5);
    });

    test('scores update live when a paper is saved', () async {
      final vm = build();
      await _settle();
      await results.saveResult(testResult(3, [0, 0, 0, 0, 0]));
      await _settle();
      expect(vm.scoreLines.last.score, 2);
      expect(vm.summary.average, 3.5);
    });

    test('print and export pass the right data to the services', () async {
      final vm = build();
      await _settle();
      expect(await vm.printSheets(named: true), ActionOutcome.done);
      expect(printer.lastNamed, isTrue);
      expect(await vm.exportScores(), ActionOutcome.done);
      expect(exporter.exported, hasLength(1));
    });

    test('reports when printing is unavailable', () async {
      final vm = build();
      await _settle();
      printer.unavailable = true;
      expect(await vm.printSheets(named: false), ActionOutcome.unavailable);
    });
  });

  group('ResultReviewViewModel', () {
    ResultReviewViewModel scanned(OmrReading r) => track(
      ResultReviewViewModel.scanned(
        examId: 'e1',
        reading: r,
        exams: exams,
        classes: classes,
        results: results,
      ),
    );

    test('flags unclear answers and re-scores as they are fixed', () async {
      final vm = scanned(
        reading(
          digits: const [MarkReading(0, _clear), MarkReading(2, _clear)],
          answers: const [
            MarkReading(0, _clear),
            MarkReading(1, MarkStatus.unsure),
            MarkReading(null, MarkStatus.multiple),
            MarkReading(3, _clear),
            MarkReading(0, _clear),
          ],
        ),
      );
      await _settle();
      expect(vm.student?.name, 'Santos, María');
      expect(vm.needsCheck, {1, 2});
      expect(vm.score, 4);

      vm.setAnswer(2, 2);
      expect(vm.needsCheck, {1});
      expect(vm.score, 5);
    });

    test('warns before replacing an earlier paper', () async {
      final vm = scanned(
        reading(
          digits: const [MarkReading(0, _clear), MarkReading(1, _clear)],
          answers: [for (var i = 0; i < 5; i++) const MarkReading(0, _clear)],
        ),
      );
      await _settle();
      expect(vm.replacedScore, 5);
      expect(await vm.save(), isTrue);
      expect((await results.getResult('e1', 1))!.answers, [0, 0, 0, 0, 0]);
    });

    test('cannot save until the student is known', () async {
      final vm = scanned(
        reading(
          digits: const [MarkReading.blank(), MarkReading.blank()],
          answers: [for (var i = 0; i < 5; i++) const MarkReading(0, _clear)],
        ),
      );
      await _settle();
      expect(vm.canSave, isFalse);
      expect(await vm.save(), isFalse);
      vm.chooseStudent(3);
      expect(vm.canSave, isTrue);
      expect(await vm.save(), isTrue);
      expect(await results.getResult('e1', 3), isNotNull);
    });

    test('reassigning a saved paper moves it to the other student', () async {
      final vm = track(
        ResultReviewViewModel.saved(
          examId: 'e1',
          savedStudent: 1,
          exams: exams,
          classes: classes,
          results: results,
        ),
      );
      await _settle();
      expect(vm.answers, [0, 1, 2, 3, 0]);
      vm.chooseStudent(2);
      expect(await vm.save(), isTrue);
      expect(await results.getResult('e1', 1), isNull);
      expect(await results.getResult('e1', 2), isNotNull);
    });
  });

  group('ScanSessionViewModel', () {
    late FakePhotoService photos;
    late FakeSheetReader reader;

    ScanSessionViewModel build() => track(
      ScanSessionViewModel(
        examId: 'e1',
        exams: exams,
        classes: classes,
        results: results,
        photos: photos = FakePhotoService(),
        reader: reader = FakeSheetReader(
          SheetScanSuccess(
            reading(
              digits: const [MarkReading(0, _clear), MarkReading(2, _clear)],
              answers: const [],
            ),
          ),
        ),
      ),
    );

    test('a readable photo is handed back for review', () async {
      final vm = build();
      await _settle();
      expect(vm.checkedCount, 1);
      expect(vm.classSize, 3);
      final r = await vm.captureAndRead(PhotoSource.camera);
      expect(r?.studentNumber, 2);
      expect(vm.step, isA<ScanWaiting>());
      expect(vm.source, PhotoSource.camera);
    });

    test('an unreadable photo shows the reason', () async {
      final vm = build();
      await _settle();
      reader.result = const SheetScanFailure(ScanProblem.cornersNotFound);
      expect(await vm.captureAndRead(PhotoSource.camera), isNull);
      expect(
        (vm.step as ScanFailed).message,
        ScanProblem.cornersNotFound.title,
      );
    });

    test('a denied camera explains how to allow it', () async {
      final vm = build();
      await _settle();
      photos.error = const PhotoUnavailableException(permissionDenied: true);
      expect(await vm.captureAndRead(PhotoSource.camera), isNull);
      expect((vm.step as ScanFailed).message, contains('Settings'));
      expect(vm.isBusy, isFalse);
    });

    test('a second tap while busy does not open the camera twice', () async {
      final vm = build();
      await _settle();
      final first = vm.captureAndRead(PhotoSource.camera);
      final second = await vm.captureAndRead(PhotoSource.camera);
      await first;
      expect(second, isNull);
      expect(photos.calls, 1);
    });

    test('backing out of the camera returns to waiting', () async {
      final vm = build();
      await _settle();
      photos.nextPhoto = null;
      expect(await vm.captureAndRead(PhotoSource.gallery), isNull);
      expect(vm.step, isA<ScanWaiting>());
    });
  });

  group('AnswerKeyViewModel', () {
    test('a scanned key fills clear answers and marks the rest', () async {
      final vm = track(
        AnswerKeyViewModel(
          examId: 'e1',
          exams: exams,
          photos: FakePhotoService(),
          reader: FakeSheetReader(
            SheetScanSuccess(
              reading(
                digits: const [],
                answers: const [
                  MarkReading(3, _clear),
                  MarkReading(2, _clear),
                  MarkReading(null, MarkStatus.multiple),
                  MarkReading(1, MarkStatus.unsure),
                  MarkReading(0, _clear),
                ],
              ),
            ),
          ),
        ),
      );
      await _settle();
      final outcome = await vm.scanKey(PhotoSource.camera);
      expect((outcome as KeyScanRead).unreadable, 2);
      expect(vm.draft, [3, 2, null, null, 0]);
      expect(vm.needsCheck(2), isTrue);
      expect(vm.isDirty, isTrue);

      vm.setAnswer(2, 1);
      vm.setAnswer(3, 1);
      expect(await vm.save(), isTrue);
      expect((await exams.watchExam('e1').first)!.answerKey, [3, 2, 1, 1, 0]);
    });
  });

  group('ExamFormViewModel', () {
    test('requires a title', () async {
      final vm = track(ExamFormViewModel(classId: 'c1', exams: exams));
      expect(await vm.save(), FormSaveOutcome.invalid);
      expect(vm.showTitleError, isTrue);
      vm.setTitle('Math');
      expect(vm.showTitleError, isFalse);
    });

    test('creates a test with the chosen size', () async {
      final vm = track(ExamFormViewModel(classId: 'c1', exams: exams))
        ..setTitle('  Math  ')
        ..setQuestions(99)
        ..setChoices(5);
      expect(vm.questions, 60, reason: 'clamped to the sheet maximum');
      expect(await vm.save(), FormSaveOutcome.saved);
      final exam = (await exams.watchExam(vm.savedExamId!).first)!;
      expect(exam.title, 'Math');
      expect(exam.questionCount, 60);
      expect(exam.choiceCount, 5);
    });

    test('warns when editing removes questions', () {
      final vm = track(
        ExamFormViewModel(classId: 'c1', exams: exams, existing: testExam()),
      )..setQuestions(3);
      expect(vm.removesQuestions, isTrue);
    });
  });

  group('AddStudentsViewModel', () {
    late FakePhotoService photos;
    late FakeNameListReader nameReader;

    AddStudentsViewModel addStudents() => track(
      AddStudentsViewModel(
        'c1',
        classes,
        photos: photos,
        nameReader: nameReader,
      ),
    );

    setUp(() {
      photos = FakePhotoService();
      nameReader = FakeNameListReader();
    });

    test('names read from a photo go below the typed ones', () async {
      final vm = addStudents();
      await _settle();
      vm.updateNames('Lopez, Ben\n');
      final outcome = await vm.readNamesFromPhoto(PhotoSource.gallery);
      expect(outcome, isA<NamesFound>().having((o) => o.count, 'count', 2));
      expect(vm.text, 'Lopez, Ben\nAbad, Ben\nCruz, Leo');
      expect(vm.preview.map((s) => s.number), [4, 5, 6]);
      expect(vm.isReadingPhoto, isFalse);
    });

    test('backing out of the camera changes nothing', () async {
      final vm = addStudents();
      photos.nextPhoto = null;
      expect(
        await vm.readNamesFromPhoto(PhotoSource.camera),
        isA<NamePhotoCancelled>(),
      );
      expect(vm.text, isEmpty);
    });

    test('a photo with no names says so', () async {
      final vm = addStudents();
      nameReader.names = const [];
      expect(
        await vm.readNamesFromPhoto(PhotoSource.camera),
        isA<NoNamesFound>(),
      );
    });

    test('camera permission and reader failures are explained', () async {
      final vm = addStudents();
      photos.error = const PhotoUnavailableException(permissionDenied: true);
      final denied = await vm.readNamesFromPhoto(PhotoSource.camera);
      expect(
        denied,
        isA<NamePhotoFailed>().having(
          (o) => o.message,
          'message',
          contains('permission'),
        ),
      );

      photos.error = null;
      nameReader.error = const NameReadException('model missing');
      final failed = await vm.readNamesFromPhoto(PhotoSource.camera);
      expect(failed, isA<NamePhotoFailed>());
      expect(vm.isReadingPhoto, isFalse);
    });

    test('previews numbered names and saves them', () async {
      final vm = addStudents();
      await _settle();
      vm.updateNames(' Lopez, Ben \n\nCruz, Lea\n');
      expect(vm.preview.map((s) => '${s.number} ${s.name}'), [
        '4 Lopez, Ben',
        '5 Cruz, Lea',
      ]);
      expect(await vm.save(), isTrue);
      expect((await classes.watchClass('c1').first)!.students, hasLength(5));
    });
  });

  group('ViewModel base', () {
    test('a failed save returns false instead of throwing', () async {
      final vm = track(StudentsViewModel('c1', _FailingClassRepository()));
      expect(await vm.rename(1, 'X'), isFalse);
    });

    test('a failed load shows the error state', () async {
      final vm = track(StudentsViewModel('c1', _FailingClassRepository()));
      await _settle();
      expect(vm.loadFailed, isTrue);
    });
  });
}

/// Behaves like a database whose disk is full or file is damaged.
class _FailingClassRepository implements ClassRepository {
  static final _error = Exception('disk I/O error');

  @override
  Stream<SchoolClass?> watchClass(String classId) => Stream.error(_error);

  @override
  Future<void> renameStudent(String classId, int number, String name) =>
      Future.error(_error);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
