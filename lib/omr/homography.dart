import 'package:egrado/omr/sheet_layout.dart';

/// Projective transform that maps page millimetres onto photo pixels.
///
/// Built from four point pairs, so it corrects for a tilted or angled photo.
class Homography {
  const Homography._(this._h);

  /// Row-major 3×3 matrix with h[8] fixed to 1.
  final List<double> _h;

  /// Solves for the transform taking each `from[i]` to `to[i]`.
  ///
  /// Returns null when the points are degenerate (e.g. three in a line).
  static Homography? fromPoints(List<PagePoint> from, List<PagePoint> to) {
    assert(from.length == 4 && to.length == 4);
    final a = List.generate(8, (_) => List<double>.filled(9, 0));
    for (var i = 0; i < 4; i++) {
      final x = from[i].x, y = from[i].y;
      final u = to[i].x, v = to[i].y;
      a[i * 2] = [x, y, 1, 0, 0, 0, -u * x, -u * y, u];
      a[i * 2 + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y, v];
    }
    final solution = _solve(a);
    if (solution == null) return null;
    return Homography._([...solution, 1]);
  }

  PagePoint map(PagePoint p) {
    final h = _h;
    final w = h[6] * p.x + h[7] * p.y + h[8];
    return PagePoint(
      (h[0] * p.x + h[1] * p.y + h[2]) / w,
      (h[3] * p.x + h[4] * p.y + h[5]) / w,
    );
  }

  /// Gaussian elimination with partial pivoting on an augmented 8×9 matrix.
  static List<double>? _solve(List<List<double>> m) {
    const n = 8;
    for (var col = 0; col < n; col++) {
      var pivot = col;
      for (var r = col + 1; r < n; r++) {
        if (m[r][col].abs() > m[pivot][col].abs()) pivot = r;
      }
      if (m[pivot][col].abs() < 1e-10) return null;
      final tmp = m[col];
      m[col] = m[pivot];
      m[pivot] = tmp;
      for (var r = 0; r < n; r++) {
        if (r == col) continue;
        final factor = m[r][col] / m[col][col];
        if (factor == 0) continue;
        for (var c = col; c <= n; c++) {
          m[r][c] -= factor * m[col][c];
        }
      }
    }
    return List.generate(n, (i) => m[i][n] / m[i][i]);
  }
}
