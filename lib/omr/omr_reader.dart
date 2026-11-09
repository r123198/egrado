import 'dart:math' as math;
import 'dart:typed_data';

import 'package:egrado/omr/binary_image.dart';
import 'package:egrado/omr/homography.dart';
import 'package:egrado/omr/omr_reading.dart';
import 'package:egrado/omr/sheet_layout.dart';
import 'package:image/image.dart' as img;

/// Photos are shrunk to this long side before reading: plenty for 5 mm
/// bubbles, and fast enough on older phones.
const int _workingLongSide = 1600;

/// Share of a bubble's centre that must be dark to count as filled.
const double _filledThreshold = 0.5;

/// Below this a bubble is treated as empty; in between it is "unsure".
const double _faintThreshold = 0.25;

/// Reads an answer sheet photo. Pure and synchronous so it can run in a
/// background isolate (`Isolate.run`).
SheetScan readAnswerSheet(
  Uint8List photoBytes, {
  required int questionCount,
  required int choiceCount,
}) {
  final decoded = img.decodeImage(photoBytes);
  if (decoded == null) {
    return const SheetScanFailure(ScanProblem.unreadableImage);
  }
  final binary = _binarize(decoded);
  final pageToImage = _locatePage(binary);
  if (pageToImage == null) {
    return const SheetScanFailure(ScanProblem.cornersNotFound);
  }
  final sampler = _BubbleSampler(binary, pageToImage);

  final digits = [
    for (var place = 0; place < kStudentNumberDigits; place++)
      classifyRow([
        for (var d = 0; d < 10; d++)
          sampler.fill(SheetLayout.idBubble(place, d)),
      ]),
  ];
  final answers = [
    for (var q = 0; q < questionCount; q++)
      classifyRow([
        for (var c = 0; c < choiceCount; c++)
          sampler.fill(SheetLayout.questionBubble(q, c)),
      ]),
  ];
  return SheetScanSuccess(OmrReading(studentDigits: digits, answers: answers));
}

/// Decides what a row of bubbles says from each bubble's fill (0–1).
MarkReading classifyRow(List<double> fills) {
  var best = 0;
  for (var i = 1; i < fills.length; i++) {
    if (fills[i] > fills[best]) best = i;
  }
  var second = 0.0;
  for (var i = 0; i < fills.length; i++) {
    if (i != best) second = math.max(second, fills[i]);
  }
  final top = fills[best];

  if (top < _faintThreshold) return const MarkReading.blank();
  if (second >= _filledThreshold) {
    return const MarkReading(null, MarkStatus.multiple);
  }
  if (top < _filledThreshold || second >= _faintThreshold) {
    return MarkReading(best, MarkStatus.unsure);
  }
  return MarkReading(best, MarkStatus.clear);
}

BinaryImage _binarize(img.Image photo) {
  var image = img.bakeOrientation(photo);
  final longSide = math.max(image.width, image.height);
  if (longSide > _workingLongSide) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: _workingLongSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: _workingLongSide,
            interpolation: img.Interpolation.average,
          );
  }
  final lum = Uint8List(image.width * image.height);
  var i = 0;
  for (final pixel in image) {
    lum[i++] = pixel.luminanceNormalized * 255 ~/ 1;
  }
  return BinaryImage.adaptive(lum, image.width, image.height);
}

/// How many of the largest solid blobs are tried as corner markers. Extra
/// candidates cover a stray blot that happens to be larger than a marker.
const int _markerCandidates = 6;

/// Finds the four corner markers and works out which way up the page is.
Homography? _locatePage(BinaryImage binary) {
  // A marker is 10 mm on a 210 mm-wide page, i.e. about 1/21 of the
  // photo's short side when the page fills the frame.
  final shortSide = math.min(binary.width, binary.height);
  final blobs = binary.findSolidBlobs(
    minSide: math.max(6, shortSide ~/ 70),
    maxSide: shortSide ~/ 10,
  )..sort((a, b) => b.area.compareTo(a.area));
  // Markers are 4× the area of a bubble, so even with a steep camera angle
  // (near markers up to ~2× far ones) the four markers are the largest.
  final candidates = blobs.take(_markerCandidates).toList();

  for (final four in _combinationsOf4(candidates)) {
    final fit = _fitPage(binary, four);
    if (fit != null) return fit;
  }
  return null;
}

/// All 4-element subsets, largest blobs first.
Iterable<List<Blob>> _combinationsOf4(List<Blob> items) sync* {
  final n = items.length;
  for (var a = 0; a < n; a++) {
    for (var b = a + 1; b < n; b++) {
      for (var c = b + 1; c < n; c++) {
        for (var d = c + 1; d < n; d++) {
          yield [items[a], items[b], items[c], items[d]];
        }
      }
    }
  }
}

/// Treats [markers] as the page corners; returns the page transform if they
/// form a proper quadrilateral with the orientation mark in place.
Homography? _fitPage(BinaryImage binary, List<Blob> markers) {
  // Image corners clockwise from top-left.
  Blob extreme(double Function(Blob) score) =>
      markers.reduce((a, b) => score(a) <= score(b) ? a : b);
  final corners = [
    extreme((b) => b.centerX + b.centerY),
    extreme((b) => b.centerY - b.centerX),
    extreme((b) => -(b.centerX + b.centerY)),
    extreme((b) => b.centerX - b.centerY),
  ];
  if (corners.toSet().length < 4) return null;
  final imagePoints = [
    for (final c in corners) PagePoint(c.centerX, c.centerY),
  ];

  // Try all four rotations; keep the one where the orientation mark is.
  Homography? bestFit;
  var bestScore = 0.0;
  for (var turn = 0; turn < 4; turn++) {
    final rotated = [for (var i = 0; i < 4; i++) imagePoints[(i + turn) % 4]];
    final h = Homography.fromPoints(SheetLayout.markerCenters, rotated);
    if (h == null) continue;
    final score = _BubbleSampler(binary, h).fill(
      SheetLayout.orientationMark,
      radius: SheetLayout.orientationMarkSize / 2,
    );
    if (score > bestScore) {
      bestScore = score;
      bestFit = h;
    }
  }
  return bestScore >= 0.6 ? bestFit : null;
}

class _BubbleSampler {
  _BubbleSampler(this._binary, this._pageToImage);

  final BinaryImage _binary;
  final Homography _pageToImage;

  /// Share of dark pixels inside the middle of a circle on the page. Only
  /// the inner 55% is sampled so the printed outline never counts.
  double fill(PagePoint center, {double radius = SheetLayout.bubbleRadius}) {
    final r = radius * 0.55;
    final step = r / 4;
    var total = 0, dark = 0;
    for (var dy = -r; dy <= r + 1e-9; dy += step) {
      for (var dx = -r; dx <= r + 1e-9; dx += step) {
        if (dx * dx + dy * dy > r * r) continue;
        final p = _pageToImage.map(PagePoint(center.x + dx, center.y + dy));
        total++;
        // A degenerate corner fit can map points to infinity: count those
        // as paper so the fit simply fails its checks.
        if (!p.x.isFinite || !p.y.isFinite) continue;
        if (_binary.isDark(p.x.round(), p.y.round())) dark++;
      }
    }
    return total == 0 ? 0 : dark / total;
  }
}
