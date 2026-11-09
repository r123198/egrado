import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/omr/sheet_layout.dart';
import 'package:meta/meta.dart';

@immutable
class Student {
  const Student({required this.number, required this.name});

  /// The number the student shades on the answer sheet (1–99).
  final int number;
  final String name;
}

@immutable
class SchoolClass {
  SchoolClass({
    required this.id,
    required this.name,
    List<Student> students = const [],
    this.gradingPolicyId,
    this.subjectGroupId,
  }) : students = List.unmodifiable(
         [...students]..sort((a, b) => a.number.compareTo(b.number)),
       );

  final String id;
  final String name;

  /// Saved DepEd policy id; null means the current DepEd policy.
  final String? gradingPolicyId;

  /// Saved subject group id; null until the teacher picks the subject.
  final String? subjectGroupId;

  GradingPolicy get gradingPolicy => policyById(gradingPolicyId);

  /// The subject's weights, or null until a subject is chosen.
  SubjectGroup? get subjectGroup => switch (subjectGroupId) {
    final id? => gradingPolicy.subject(id),
    null => null,
  };

  /// Always sorted by student number.
  final List<Student> students;

  Student? studentByNumber(int number) {
    for (final s in students) {
      if (s.number == number) return s;
    }
    return null;
  }

  /// Smallest unused student number, or null when the class is full.
  int? get nextFreeNumber {
    final taken = {for (final s in students) s.number};
    for (var n = 1; n <= kMaxStudentNumber; n++) {
      if (!taken.contains(n)) return n;
    }
    return null;
  }

  /// Pairs each new name with the next unused number, filling gaps first.
  /// Names beyond the last free number are left out.
  List<Student> numberNewStudents(List<String> names) {
    final taken = {for (final s in students) s.number};
    final out = <Student>[];
    var n = 1;
    for (final name in names) {
      while (taken.contains(n)) {
        n++;
      }
      if (n > kMaxStudentNumber) break;
      out.add(Student(number: n, name: name));
      taken.add(n);
    }
    return out;
  }
}
