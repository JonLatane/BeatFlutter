import 'dart:ui';

extension RectRendering on Rect {
  // Rect
  static Rect fromLTRB(double left, double top, double right, double bottom) {
    final realRight = (left == right) ? left + 1 : right;
    final realBottom = (top == bottom) ? top + 1 : bottom;
    return Rect.fromLTRB(left, top, realRight, realBottom);
  }
}
