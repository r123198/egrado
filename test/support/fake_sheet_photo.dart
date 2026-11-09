import 'dart:typed_data';

import 'package:egrado/omr/sheet_layout.dart';
import 'package:image/image.dart' as img;

/// How a student filled one bubble in a generated test photo.
/// [partial] is a small, half-erased smudge rather than a full fill.
enum Pencil { solid, partial }

/// Draws an answer sheet the way a phone camera might see it: on a darker
/// table, optionally turned, saved as a JPEG.
Uint8List fakeSheetPhoto({
  required int questionCount,
  required int choiceCount,
  int? studentNumber,
  Map<int, List<int>> answers = const {},
  Map<int, int> partialAnswers = const {},
  double pixelsPerMm = 6,
  num rotateDegrees = 0,
  bool drawMarkers = true,
}) {
  final page = img.Image(
    width: (SheetLayout.pageWidth * pixelsPerMm).round(),
    height: (SheetLayout.pageHeight * pixelsPerMm).round(),
    numChannels: 4,
  );
  img.fill(page, color: img.ColorRgba8(238, 236, 230, 255));

  int px(double mm) => (mm * pixelsPerMm).round();
  final ink = img.ColorRgba8(20, 20, 20, 255);

  void square(PagePoint c, double size) => img.fillRect(
    page,
    x1: px(c.x - size / 2),
    y1: px(c.y - size / 2),
    x2: px(c.x + size / 2),
    y2: px(c.y + size / 2),
    color: ink,
  );

  void bubble(PagePoint c, {Pencil? pencil}) {
    img.drawCircle(
      page,
      x: px(c.x),
      y: px(c.y),
      radius: px(SheetLayout.bubbleRadius),
      color: img.ColorRgba8(60, 60, 60, 255),
    );
    if (pencil == null) return;
    final size = pencil == Pencil.solid ? 0.9 : 0.33;
    img.fillCircle(
      page,
      x: px(c.x),
      y: px(c.y),
      radius: px(SheetLayout.bubbleRadius * size),
      color: img.ColorRgba8(90, 90, 90, 255),
    );
  }

  if (drawMarkers) {
    for (final c in SheetLayout.markerCenters) {
      square(c, SheetLayout.markerSize);
    }
    square(SheetLayout.orientationMark, SheetLayout.orientationMarkSize);
  }

  final idDigits = studentNumber == null
      ? null
      : [studentNumber ~/ 10, studentNumber % 10];
  for (var place = 0; place < kStudentNumberDigits; place++) {
    for (var d = 0; d < 10; d++) {
      final filled = idDigits != null && idDigits[place] == d;
      bubble(
        SheetLayout.idBubble(place, d),
        pencil: filled ? Pencil.solid : null,
      );
    }
  }
  for (var q = 0; q < questionCount; q++) {
    for (var c = 0; c < choiceCount; c++) {
      final pencil = (answers[q]?.contains(c) ?? false)
          ? Pencil.solid
          : partialAnswers[q] == c
          ? Pencil.partial
          : null;
      bubble(SheetLayout.questionBubble(q, c), pencil: pencil);
    }
  }

  final turned = rotateDegrees == 0
      ? page
      : img.copyRotate(
          page,
          angle: rotateDegrees,
          interpolation: img.Interpolation.linear,
        );
  final margin = px(18);
  final table = img.Image(
    width: turned.width + margin * 2,
    height: turned.height + margin * 2,
  );
  img.fill(table, color: img.ColorRgb8(95, 85, 75));
  img.compositeImage(table, turned, dstX: margin, dstY: margin);
  return img.encodeJpg(table, quality: 85);
}
