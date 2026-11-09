import 'package:egrado/grading/transmutation.dart';
import 'package:meta/meta.dart';

/// The three things every DepEd grade is built from.
enum GradeComponent {
  writtenWork('WW', 'Written Work'),
  performanceTask('PT', 'Performance Task'),
  exam('EX', 'Exam');

  const GradeComponent(this.code, this.label);

  /// Short code used in class records (WW, PT, EX).
  final String code;
  final String label;
}

/// Which exam a test is, inside the Exam component.
///
/// DO 015 s. 2026 counts two Summative Tests and one Term Exam, weighted
/// 30/30/40 (para 45). DO 8 s. 2015 has a single Quarterly Assessment.
enum ExamPart {
  summativeTest1('ST1', 'Summative Test 1'),
  summativeTest2('ST2', 'Summative Test 2'),
  termExam('TE', 'Term Exam'),
  quarterlyAssessment('QA', 'Quarterly Assessment');

  const ExamPart(this.code, this.label);

  final String code;
  final String label;
}

/// Percent weights of WW, PT and EX. They add up to 100.
@immutable
class ComponentWeights {
  const ComponentWeights(this.writtenWork, this.performanceTask, this.exam);

  final int writtenWork;
  final int performanceTask;
  final int exam;

  int of(GradeComponent c) => switch (c) {
    GradeComponent.writtenWork => writtenWork,
    GradeComponent.performanceTask => performanceTask,
    GradeComponent.exam => exam,
  };

  bool get isValid =>
      writtenWork >= 0 &&
      performanceTask >= 0 &&
      exam >= 0 &&
      writtenWork + performanceTask + exam == 100;

  @override
  bool operator ==(Object other) =>
      other is ComponentWeights &&
      other.writtenWork == writtenWork &&
      other.performanceTask == performanceTask &&
      other.exam == exam;

  @override
  int get hashCode => Object.hash(writtenWork, performanceTask, exam);

  @override
  String toString() => '$writtenWork/$performanceTask/$exam';
}

/// A learning area (or group of them) and its official weights.
@immutable
class SubjectGroup {
  const SubjectGroup(this.id, this.label, this.weights);

  /// Stable id saved with a class. Never change an existing one.
  final String id;
  final String label;
  final ComponentWeights weights;
}

/// One DepEd grading rule set: how many grading periods, how exams combine,
/// how an Initial Grade becomes a reported grade, and the subject weights.
@immutable
class GradingPolicy {
  const GradingPolicy({
    required this.id,
    required this.label,
    required this.periodCount,
    required this.periodName,
    required this.transmutation,
    required this.examParts,
    required this.subjects,
  });

  /// Stable id saved with a class. Never change an existing one.
  final String id;
  final String label;

  /// 3 terms (DO 015) or 4 quarters (DO 8).
  final int periodCount;

  /// "Term" or "Quarter".
  final String periodName;
  final Transmutation transmutation;

  /// The exam parts and their percent weights inside the Exam component.
  final Map<ExamPart, int> examParts;
  final List<SubjectGroup> subjects;

  SubjectGroup? subject(String id) {
    for (final s in subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  String periodLabel(int period) => '$periodName $period';
}

const _do015ExamParts = {
  ExamPart.summativeTest1: 30,
  ExamPart.summativeTest2: 30,
  ExamPart.termExam: 40,
};

/// DO 015 s. 2026 Table 9 (Grades 2-10) and Table 10 (Strengthened SHS).
const _do015Subjects = [
  SubjectGroup(
    'core',
    'English, Filipino, Math, Science, AP, GMRC/VE, Makabansa',
    ComponentWeights(20, 50, 30),
  ),
  SubjectGroup('mapeh_tle', 'MAPEH, EPP/TLE', ComponentWeights(20, 60, 20)),
  SubjectGroup(
    'sshs_core',
    'SHS: Core subjects and other Academic electives',
    ComponentWeights(20, 50, 30),
  ),
  SubjectGroup(
    'sshs_exposure',
    'SHS: Field Exposure, Arts Apprenticeship, Creative Production',
    ComponentWeights(15, 70, 15),
  ),
  SubjectGroup(
    'sshs_arts_sports',
    'SHS: Arts, Sports, Health and Wellness electives',
    ComponentWeights(20, 60, 20),
  ),
  SubjectGroup(
    'sshs_research',
    'SHS: Research electives, Design and Innovation',
    ComponentWeights(40, 60, 0),
  ),
  SubjectGroup(
    'sshs_techpro',
    'SHS: TechPro electives',
    ComponentWeights(15, 65, 20),
  ),
  SubjectGroup(
    'sshs_immersion',
    'SHS: Work Immersion',
    ComponentWeights(20, 80, 0),
  ),
];

/// DO 8 s. 2015 Table 4 (Grades 1-10) and Table 5 (SHS).
const _do8Subjects = [
  SubjectGroup('languages', 'Languages, AP, EsP', ComponentWeights(30, 50, 20)),
  SubjectGroup('math_science', 'Science, Math', ComponentWeights(40, 40, 20)),
  SubjectGroup('mapeh_tle', 'MAPEH, EPP/TLE', ComponentWeights(20, 60, 20)),
  SubjectGroup('shs_core', 'SHS: Core subjects', ComponentWeights(25, 50, 25)),
  SubjectGroup(
    'shs_academic',
    'SHS Academic: all other subjects',
    ComponentWeights(25, 45, 30),
  ),
  SubjectGroup(
    'shs_academic_immersion',
    'SHS Academic: Work Immersion, Research, Exhibit, Performance',
    ComponentWeights(35, 40, 25),
  ),
  SubjectGroup(
    'shs_tvl',
    'SHS TVL / Sports / Arts & Design: all other subjects',
    ComponentWeights(20, 60, 20),
  ),
  SubjectGroup(
    'shs_tvl_immersion',
    'SHS TVL / Sports / Arts & Design: Work Immersion, Research, Exhibit',
    ComponentWeights(20, 60, 20),
  ),
];

/// DO 015 s. 2026, SY 2026-2027: three terms, adjusted transmutation table.
const do015Sy2026 = GradingPolicy(
  id: 'do015_2026',
  label: 'DO 015 s. 2026 · SY 2026-2027',
  periodCount: 3,
  periodName: 'Term',
  transmutation: Transmutation.adjusted2026,
  examParts: _do015ExamParts,
  subjects: _do015Subjects,
);

/// DO 015 s. 2026 from SY 2027-2028: zero-based, no transmutation.
const do015ZeroBased = GradingPolicy(
  id: 'do015_zero',
  label: 'DO 015 s. 2026 · SY 2027-2028 onward (zero-based)',
  periodCount: 3,
  periodName: 'Term',
  transmutation: Transmutation.zeroBased,
  examParts: _do015ExamParts,
  subjects: _do015Subjects,
);

/// Grade 12 in SY 2026-2027: DO 8 weights with the adjusted table
/// (DO 015 s. 2026 para 49).
const grade12Sy2026 = GradingPolicy(
  id: 'g12_2026',
  label: 'Grade 12 · SY 2026-2027 (DO 8 weights, adjusted table)',
  periodCount: 3,
  periodName: 'Term',
  transmutation: Transmutation.adjusted2026,
  examParts: {ExamPart.quarterlyAssessment: 100},
  subjects: _do8Subjects,
);

/// DO 8 s. 2015: four quarters, original transmutation table. For private
/// schools that still use it.
const do8s2015 = GradingPolicy(
  id: 'do8_2015',
  label: 'DO 8 s. 2015 · four quarters',
  periodCount: 4,
  periodName: 'Quarter',
  transmutation: Transmutation.do8s2015,
  examParts: {ExamPart.quarterlyAssessment: 100},
  subjects: _do8Subjects,
);

const kGradingPolicies = [do015Sy2026, grade12Sy2026, do015ZeroBased, do8s2015];

/// The policy with [id], or the current DepEd one when unknown.
GradingPolicy policyById(String? id) {
  for (final p in kGradingPolicies) {
    if (p.id == id) return p;
  }
  return do015Sy2026;
}
