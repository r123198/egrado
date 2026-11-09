import 'package:egrado/domain/exam.dart';
import 'package:meta/meta.dart';

/// A class as shown in the list on the home screen.
@immutable
class ClassOverview {
  const ClassOverview({
    required this.id,
    required this.name,
    required this.studentCount,
    required this.testCount,
  });

  final String id;
  final String name;
  final int studentCount;
  final int testCount;
}

/// A test as shown in a class's list of tests.
@immutable
class ExamOverview {
  const ExamOverview({
    required this.exam,
    required this.checkedCount,
    this.className = '',
    this.classSize = 0,
  });

  final Exam exam;

  /// Name of the class the test belongs to.
  final String className;

  /// Students on the class list.
  final int classSize;

  /// How many papers have been scanned and saved.
  final int checkedCount;
}
