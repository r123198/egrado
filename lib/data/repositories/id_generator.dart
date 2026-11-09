import 'dart:math';

/// Short unique ids for new classes and tests.
class IdGenerator {
  IdGenerator([Random? random]) : _random = random ?? Random();

  final Random _random;

  String next() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_random.nextInt(1 << 20).toRadixString(36)}';
}
