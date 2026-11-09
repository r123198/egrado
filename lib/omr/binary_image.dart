import 'dart:math' as math;
import 'dart:typed_data';

/// Black-and-white version of a photo, thresholded against each pixel's
/// neighbourhood so uneven lighting and shadows don't hide pencil marks.
class BinaryImage {
  BinaryImage._(this.width, this.height, this._dark);

  /// Builds from 8-bit luminance values (row-major, `width * height`).
  ///
  /// A pixel counts as dark when it is [sensitivity] darker than the mean of
  /// the square window around it (window side = [windowFraction] of width).
  factory BinaryImage.adaptive(
    Uint8List luminance,
    int width,
    int height, {
    double windowFraction = 1 / 8,
    double sensitivity = 0.15,
  }) {
    final integral = _integral(luminance, width, height);
    final half = math.max(4, (width * windowFraction / 2).round());
    final stride = width + 1;
    final dark = Uint8List(width * height);
    for (var y = 0; y < height; y++) {
      final y0 = math.max(0, y - half), y1 = math.min(height, y + half + 1);
      for (var x = 0; x < width; x++) {
        final x0 = math.max(0, x - half), x1 = math.min(width, x + half + 1);
        final sum =
            integral[y1 * stride + x1] -
            integral[y0 * stride + x1] -
            integral[y1 * stride + x0] +
            integral[y0 * stride + x0];
        final mean = sum / ((x1 - x0) * (y1 - y0));
        if (luminance[y * width + x] < mean * (1 - sensitivity)) {
          dark[y * width + x] = 1;
        }
      }
    }
    return BinaryImage._(width, height, dark);
  }

  final int width;
  final int height;
  final Uint8List _dark;

  /// Out-of-bounds pixels count as light (paper).
  bool isDark(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return false;
    return _dark[y * width + x] == 1;
  }

  /// Finds solid, compact dark blobs (filled squares or discs) — candidates
  /// for the corner registration markers.
  /// Blobs touching the photo border (table edges, shadows) are ignored.
  List<Blob> findSolidBlobs({required int minSide, required int maxSide}) {
    final visited = Uint8List(width * height);
    final blobs = <Blob>[];
    final stack = <int>[];
    for (var start = 0; start < _dark.length; start++) {
      if (_dark[start] == 0 || visited[start] == 1) continue;
      final blob = _flood(start, visited, stack);
      final touchesBorder =
          blob.left == 0 ||
          blob.top == 0 ||
          blob.left + blob.boxWidth == width ||
          blob.top + blob.boxHeight == height;
      if (!touchesBorder &&
          blob.isSolid(minSide: minSide) &&
          math.max(blob.boxWidth, blob.boxHeight) <= maxSide) {
        blobs.add(blob);
      }
    }
    return blobs;
  }

  Blob _flood(int start, Uint8List visited, List<int> stack) {
    var minX = width, minY = height, maxX = 0, maxY = 0;
    var area = 0;
    var sumX = 0.0, sumY = 0.0, sumXX = 0.0, sumYY = 0.0;
    stack
      ..clear()
      ..add(start);
    visited[start] = 1;
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      final x = i % width, y = i ~/ width;
      area++;
      sumX += x;
      sumY += y;
      sumXX += x * x;
      sumYY += y * y;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
      if (x > 0) _push(i - 1, visited, stack);
      if (x < width - 1) _push(i + 1, visited, stack);
      if (y > 0) _push(i - width, visited, stack);
      if (y < height - 1) _push(i + width, visited, stack);
    }
    final cx = sumX / area, cy = sumY / area;
    return Blob(
      centerX: cx,
      centerY: cy,
      left: minX,
      top: minY,
      boxWidth: maxX - minX + 1,
      boxHeight: maxY - minY + 1,
      area: area,
      spread: (sumXX / area - cx * cx) + (sumYY / area - cy * cy),
    );
  }

  void _push(int i, Uint8List visited, List<int> stack) {
    if (_dark[i] == 1 && visited[i] == 0) {
      visited[i] = 1;
      stack.add(i);
    }
  }

  static Float64List _integral(Uint8List lum, int width, int height) {
    final stride = width + 1;
    final out = Float64List(stride * (height + 1));
    for (var y = 0; y < height; y++) {
      var rowSum = 0.0;
      for (var x = 0; x < width; x++) {
        rowSum += lum[y * width + x];
        out[(y + 1) * stride + x + 1] = out[y * stride + x + 1] + rowSum;
      }
    }
    return out;
  }
}

/// A connected group of dark pixels.
class Blob {
  const Blob({
    required this.centerX,
    required this.centerY,
    required this.left,
    required this.top,
    required this.boxWidth,
    required this.boxHeight,
    required this.area,
    required this.spread,
  });

  final double centerX;
  final double centerY;
  final int left;
  final int top;
  final int boxWidth;
  final int boxHeight;
  final int area;

  /// Mean squared distance of the pixels from the centre.
  final double spread;

  /// Rotation-independent solidity: area ÷ spread is 6.0 for a filled
  /// square and 2π (≈6.3) for a filled disc, but far lower for letters,
  /// rings, lines and scribbles.
  double get compactness => spread == 0 ? 0 : area / spread;

  bool isSolid({required int minSide}) {
    if (boxWidth < minSide || boxHeight < minSide) return false;
    final aspect = boxWidth / boxHeight;
    return aspect > 0.5 && aspect < 2 && compactness > 5.2;
  }
}
