/// Turning an Initial Grade (IG) into the grade that goes on the report card.
///
/// Every IG is first rounded to 2 decimals, because the DepEd tables are
/// written to 2 decimals. The calculator rounds PS and WS to 2 decimals the
/// way the DO 8 and Strengthened SHS E-Class Records do; a template that
/// doesn't round (the Grades 2-10 three-term file) can differ by one at a
/// band edge, and the teacher's class record is always the official grade.
library;

/// How an IG becomes a term/quarter grade.
enum Transmutation {
  /// DO 015, s. 2026, Annex D Table 4 — "Adjusted Transmutation Table (only
  /// for SY 2026-2027)". IG 70.00 → 75. Also used for Grade 12 in SY 2026-27.
  adjusted2026,

  /// DO 015, s. 2026 para 50 — from SY 2027-2028: no transmutation; the
  /// grade is the IG rounded to a whole number (report-card floor of 60).
  zeroBased,

  /// DO 8, s. 2015, Appendix B. IG 60.00 → 75. Superseded in SY 2026-27.
  do8s2015,
}

/// Lowest IG (in hundredths) that earns each grade, from 100 down to 60.
/// Copied row by row from DO 015 s. 2026 Annex D Table 4 (p. 40).
const _adjusted2026Floors = <int, int>{
  100: 9950,
  99: 9832,
  98: 9714,
  97: 9596,
  96: 9478,
  95: 9360,
  94: 9242,
  93: 9124,
  92: 9006,
  91: 8888,
  90: 8770,
  89: 8652,
  88: 8534,
  87: 8416,
  86: 8298,
  85: 8180,
  84: 8062,
  83: 7944,
  82: 7826,
  81: 7708,
  80: 7590,
  79: 7472,
  78: 7354,
  77: 7236,
  76: 7118,
  75: 7000,
  74: 6534,
  73: 6067,
  72: 5601,
  71: 5134,
  70: 4667,
  69: 4201,
  68: 3734,
  67: 3268,
  66: 2801,
  65: 2335,
  64: 1868,
  63: 1401,
  62: 935,
  61: 468,
  60: 0,
};

/// The lowest grade DepEd lets a report card show (DO 015 Annex D para 18).
const kMinimumReportableGrade = 60;

/// The lowest passing final grade.
const kPassingGrade = 75;

/// Rounds half up to 2 decimals and returns hundredths (85.336 → 8534).
/// The tiny nudge stops 84.5 being stored as 84.4999… from rounding down.
int toHundredths(double value) => (value * 100 + 1e-7).round();

/// Rounds half up to a whole number, as DepEd does for every reported grade.
int roundGrade(double value) => (value + 1e-9).round();

/// The reported grade for [initialGrade] (0–100) under [scheme].
int transmute(double initialGrade, Transmutation scheme) {
  final ig = toHundredths(initialGrade.clamp(0, 100).toDouble());
  switch (scheme) {
    case Transmutation.adjusted2026:
      for (final entry in _adjusted2026Floors.entries) {
        if (ig >= entry.value) return entry.key;
      }
      return kMinimumReportableGrade;
    case Transmutation.zeroBased:
      final grade = roundGrade(ig / 100);
      return grade < kMinimumReportableGrade ? kMinimumReportableGrade : grade;
    case Transmutation.do8s2015:
      if (ig >= 6000) {
        final grade = 75 + (ig - 6000) ~/ 160;
        return grade > 100 ? 100 : grade;
      }
      return 60 + ig ~/ 400;
  }
}
