/// The kind of school a teacher's workspace is set up for. DepEd and
/// college grade so differently that the app shows one or the other.
enum TeachingLevel {
  depEd(
    'DepEd · Kinder to Grade 12',
    'Terms or quarters, Written Work / Performance Task / Exam, and '
        'your E-Class Record',
    'e.g. Grade 7 – Rizal',
  ),
  college(
    'College',
    'Prelim, Midterm and Finals, your own categories and weights, and '
        'the 1.00–5.00 scale',
    'e.g. NCM 107 – BSN 2G',
  );

  const TeachingLevel(this.label, this.detail, this.classNameHint);

  final String label;
  final String detail;

  /// An example class name a teacher at this level would recognise.
  final String classNameHint;
}
