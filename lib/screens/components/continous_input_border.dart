import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

class ContinousInputBorder extends OutlineInputBorder {

  const ContinousInputBorder({
    BorderSide borderSide = const BorderSide(),
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(2.0)),
    double gapPadding = 2.0,
  }) : super(
      borderSide: borderSide,
      borderRadius: borderRadius,
      gapPadding: gapPadding);

  @override
  ContinousInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) {
    return ContinousInputBorder(
      borderRadius: borderRadius ?? this.borderRadius,
      borderSide: borderSide ?? this.borderSide,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }

  @override
  ContinousInputBorder scale(double t) {
    return ContinousInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
      gapPadding: gapPadding * t,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    assert(t != null);
    if (a is ContinousInputBorder) {
      final ContinousInputBorder border = a;
      return ContinousInputBorder(
        borderRadius: BorderRadius.lerp(border.borderRadius, borderRadius, t)!,
        borderSide: BorderSide.lerp(border.borderSide, borderSide, t),
        gapPadding: border.gapPadding,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    assert(t != null);
    if (b is ContinousInputBorder) {
      final ContinousInputBorder border = b;
      return ContinousInputBorder(
        borderRadius: BorderRadius.lerp(borderRadius, border.borderRadius, t)!,
        borderSide: BorderSide.lerp(borderSide, border.borderSide, t),
        gapPadding: border.gapPadding,
      );
    }
    return super.lerpTo(b, t);
  }

  double _clampToShortest(RRect rrect, double value) {
    return value > rrect.shortestSide ? rrect.shortestSide : value;
  }

  Path _getPath(RRect rrect, {double extent = 0, double start = 0}) {
    //
    final RRect scaledRRect = rrect.scaleRadii();
    //
    final double left = rrect.left;
    final double right = rrect.right;
    final double top = rrect.top;
    final double bottom = rrect.bottom;
    //  Radii will be clamped to the value of the shortest side
    // of rrect to avoid strange tie-fighter shapes.
    final double tlRadiusX =
    math.max(0.0, _clampToShortest(rrect, rrect.tlRadiusX));
    final double tlRadiusY =
    math.max(0.0, _clampToShortest(rrect, rrect.tlRadiusY));
    final double trRadiusX =
    math.max(0.0, _clampToShortest(rrect, rrect.trRadiusX));
    final double trRadiusY =
    math.max(0.0, _clampToShortest(rrect, rrect.trRadiusY));
    final double blRadiusX =
    math.max(0.0, _clampToShortest(rrect, rrect.blRadiusX));
    final double blRadiusY =
    math.max(0.0, _clampToShortest(rrect, rrect.blRadiusY));
    final double brRadiusX =
    math.max(0.0, _clampToShortest(rrect, rrect.brRadiusX));
    final double brRadiusY =
    math.max(0.0, _clampToShortest(rrect, rrect.brRadiusY));

    //
    Path path = Path()
      ..moveTo(left, top + tlRadiusX)
      ..cubicTo(left, top, left, top, left + tlRadiusY - (extent*0.25), top);
    if (extent == 0){
      path.lineTo(right - trRadiusX, top);
      path.cubicTo(right, top, right, top, right, top + trRadiusY);
      path.lineTo(right, bottom - brRadiusX);
      path.cubicTo(right, bottom, right, bottom, right - brRadiusY, bottom);
      path.lineTo(left + blRadiusX, bottom);
      path.cubicTo(left, bottom, left, bottom, left, bottom - blRadiusY);
    }else{
      path.moveTo(scaledRRect.left + start + extent + 5, top);
      path.lineTo(right - trRadiusX, top);
      path.cubicTo(right, top, right, top, right, top + trRadiusY);
      path.lineTo(right, bottom - brRadiusX);
      path.cubicTo(right, bottom, right, bottom, right - brRadiusY, bottom);
      path.lineTo(left + blRadiusX, bottom);
      path.cubicTo(left, bottom, left, bottom, left, bottom - blRadiusY);
    }
    //
    return path;
    return Path()
      ..moveTo(left, top + tlRadiusX)
      ..cubicTo(left, top, left, top, left + tlRadiusY - (extent*0.25), top)
      ..lineTo(right - trRadiusX, top)
      /*..cubicTo(right, top, right, top, right, top + trRadiusY)
      ..lineTo(right, bottom - brRadiusX)
      ..cubicTo(right, bottom, right, bottom, right - brRadiusY, bottom)
      ..lineTo(left + blRadiusX, bottom)
      ..cubicTo(left, bottom, left, bottom, left, bottom - blRadiusY)*/
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection? textDirection }) {
    return _getPath(borderRadius.resolve(textDirection).toRRect(rect).deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection? textDirection, double extent=0.0, double start=0.0 }) {
    return _getPath(borderRadius.resolve(textDirection).toRRect(rect), extent: extent, start: start);
  }

  @override
  void paint(Canvas canvas, Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    assert(gapExtent != null);
    assert(gapPercentage >= 0.0 && gapPercentage <= 1.0);
    assert(_cornersAreCircular(borderRadius));

    if (rect.isEmpty)
      return;
    switch (borderSide.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        //final RRect outer = borderRadius.toRRect(rect);
        if (gapStart == null || gapExtent <= 0.0 || gapPercentage == 0.0) {
          final Path path = getOuterPath(rect, textDirection: textDirection);
          final Paint paint = borderSide.toPaint();
          canvas.drawPath(path, paint);
        }else{
          final double extent = lerpDouble(0.0, gapExtent + gapPadding, gapPercentage)!;
          final Path path = getOuterPath(rect, textDirection: textDirection, extent: extent, start: math.max(0.0, gapStart - gapPadding));
          final Paint paint = borderSide.toPaint();
          canvas.drawPath(path, paint);
        }
        break;
    }
  }

  static bool _cornersAreCircular(BorderRadius borderRadius) {
    return borderRadius.topLeft.x == borderRadius.topLeft.y
        && borderRadius.bottomLeft.x == borderRadius.bottomLeft.y
        && borderRadius.topRight.x == borderRadius.topRight.y
        && borderRadius.bottomRight.x == borderRadius.bottomRight.y;
  }
}