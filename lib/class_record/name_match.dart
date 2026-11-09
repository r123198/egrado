/// Matching the app's class list to the names in a class record.
///
/// Class records usually write "DELA CRUZ, JUAN A." while the app may have
/// "Juan Dela Cruz". Names are compared as sets of words, ignoring case,
/// punctuation, accents and order. Initials only confirm a match, they never
/// make one. Ambiguous names are left for the teacher to pick.
library;

/// Splits a name into comparable words: upper case, accents removed,
/// punctuation dropped.
List<String> nameWords(String name) {
  const accents = {
    'Á': 'A',
    'À': 'A',
    'Â': 'A',
    'Ä': 'A',
    'É': 'E',
    'È': 'E',
    'Ê': 'E',
    'Ë': 'E',
    'Í': 'I',
    'Ì': 'I',
    'Î': 'I',
    'Ï': 'I',
    'Ó': 'O',
    'Ò': 'O',
    'Ô': 'O',
    'Ö': 'O',
    'Ú': 'U',
    'Ù': 'U',
    'Û': 'U',
    'Ü': 'U',
    'Ñ': 'N',
  };
  final upper = name.toUpperCase().split('').map((c) => accents[c] ?? c).join();
  return upper
      .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
      .trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();
}

/// How well two names agree: 0 means "not the same person".
int nameMatchScore(String a, String b) {
  final wa = nameWords(a);
  final wb = nameWords(b);
  final fullA = wa.where((w) => w.length > 1).toSet();
  final fullB = wb.where((w) => w.length > 1).toSet();
  if (fullA.isEmpty || fullB.isEmpty) return 0;
  final shared = fullA.intersection(fullB);
  final smaller = fullA.length <= fullB.length ? fullA : fullB;
  // Every full word of the shorter name must appear in the longer one, and
  // a single shared word ("JUAN") is never enough.
  if (shared.length < smaller.length || shared.length < 2) return 0;
  var score = shared.length * 10;
  if (fullA.length == fullB.length) score += 5;
  // Middle initials: reward agreement, reject a clear contradiction.
  final initialsA = wa.where((w) => w.length == 1).toSet();
  final initialsB = wb.where((w) => w.length == 1).toSet();
  final firstLettersB = fullB.difference(shared).map((w) => w[0]).toSet()
    ..addAll(initialsB);
  final firstLettersA = fullA.difference(shared).map((w) => w[0]).toSet()
    ..addAll(initialsA);
  for (final i in initialsA) {
    if (firstLettersB.isEmpty) continue;
    score += firstLettersB.contains(i) ? 2 : -100;
  }
  for (final i in initialsB) {
    if (firstLettersA.isEmpty) continue;
    score += firstLettersA.contains(i) ? 2 : -100;
  }
  return score < 0 ? 0 : score;
}

/// Pairs each app student (number → name) with at most one record name.
///
/// A pair is made only when it is the clear best for both sides; ties and
/// weak matches are left out so the teacher can choose.
Map<int, String> matchNames(
  Map<int, String> students,
  List<String> recordNames,
) {
  final candidates = <(int, String, int)>[];
  for (final MapEntry(key: number, value: name) in students.entries) {
    for (final record in recordNames) {
      final score = nameMatchScore(name, record);
      if (score > 0) candidates.add((number, record, score));
    }
  }

  bool isClearBest((int, String, int) c) {
    final (number, record, score) = c;
    for (final (n, r, s) in candidates) {
      if ((n == number) == (r == record)) continue;
      if ((n == number || r == record) && s >= score) return false;
    }
    return true;
  }

  final out = <int, String>{};
  final usedRecords = <String>{};
  for (final c in candidates.where(isClearBest)) {
    final (number, record, _) = c;
    if (out.containsKey(number) || usedRecords.contains(record)) continue;
    out[number] = record;
    usedRecords.add(record);
  }
  return out;
}

/// True when both names have exactly the same full words (initials and
/// word order aside) — safe to pair without asking the teacher.
bool isExactNameMatch(String a, String b) {
  Set<String> full(String n) => nameWords(n).where((w) => w.length > 1).toSet();
  final wa = full(a);
  return wa.isNotEmpty &&
      wa.length == full(b).length &&
      wa.containsAll(full(b)) &&
      nameMatchScore(a, b) > 0;
}
