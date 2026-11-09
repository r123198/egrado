import 'package:egrado/domain/name_list.dart';
import 'package:flutter_test/flutter_test.dart';

/// A line [h] px tall whose top edge is at [y].
TextLineBox line(String text, double x, double y, {double w = 200}) =>
    TextLineBox(text, left: x, top: y, right: x + w, bottom: y + 30);

void main() {
  group('cleanName', () {
    test('drops row numbers, bullets and trailing scores', () {
      expect(cleanName('1. Dela Cruz, Juan'), 'Dela Cruz, Juan');
      expect(cleanName('12) Santos, Maria  95'), 'Santos, Maria');
      expect(cleanName('No. 3 - Reyes, Ana'), 'Reyes, Ana');
      expect(cleanName('• Lopez, Ben 87.5%'), 'Lopez, Ben');
      expect(cleanName('  Sta   Ana  Rosa '), 'Sta Ana Rosa');
    });

    test('keeps accents, ñ, hyphens and apostrophes', () {
      expect(cleanName('Peña-Ibáñez, José'), 'Peña-Ibáñez, José');
      expect(cleanName("O'Neil, Mary Jo"), "O'Neil, Mary Jo");
    });

    test('rejects headings, numbers and stray marks', () {
      expect(cleanName('NAME'), isNull);
      expect(cleanName('Learners\' Names'), isNull);
      expect(cleanName('Last Name, First Name'), isNull);
      expect(cleanName('BOYS'), isNull);
      expect(cleanName('24'), isNull);
      expect(cleanName('|'), isNull);
      expect(cleanName('x'), isNull);
    });
  });

  group('namesFromTextLines', () {
    test('reads a one-column list top to bottom', () {
      final names = namesFromTextLines([
        line('2. Santos, Maria', 40, 140),
        line('NAMES', 40, 60),
        line('1. Dela Cruz, Juan', 40, 100),
      ]);
      expect(names, ['Dela Cruz, Juan', 'Santos, Maria']);
    });

    test('joins surname and first-name columns on the same row', () {
      final names = namesFromTextLines([
        line('Dela Cruz', 40, 100, w: 150),
        line('Juan', 400, 102, w: 80),
        line('Santos', 40, 140, w: 100),
        line('Maria', 400, 139, w: 80),
      ]);
      expect(names, ['Dela Cruz Juan', 'Santos Maria']);
    });

    test('a boys | girls list is read column by column', () {
      final names = namesFromTextLines([
        line('BOYS', 40, 60, w: 80),
        line('GIRLS', 500, 60, w: 80),
        line('1. Abad, Ben', 40, 100),
        line('1. Bautista, Lea', 500, 100),
        line('2. Cruz, Leo', 40, 140),
        line('2. Diaz, Mia', 500, 140),
        line('3. Flores, Ana', 500, 180),
      ]);
      expect(names, [
        'Abad, Ben',
        'Cruz, Leo',
        'Bautista, Lea',
        'Diaz, Mia',
        'Flores, Ana',
      ]);
    });

    test('nothing readable gives an empty list', () {
      expect(namesFromTextLines([line('42', 0, 0), line('', 0, 50)]), isEmpty);
      expect(namesFromTextLines(const []), isEmpty);
    });
  });
}
