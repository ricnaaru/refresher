import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class LoadingAnimation extends StatefulWidget {
  final Color lineColor;
  final Color progressColor;
  final LoadingController controller;
  final AnimationController anim;
  final double size;
  final EdgeInsets margin;

  LoadingAnimation(
      {Color lineColor,
      Color progressColor,
      double percentage,
      double thickness,
      LoadingController controller,
      this.anim,
      double size,
      EdgeInsets margin})
      : assert(controller == null || (percentage == null && thickness == null)),
        this.lineColor = lineColor ?? Colors.white,
        this.progressColor = progressColor ?? Colors.amber,
        this.size = size ?? 100.0,
        this.margin = margin ?? EdgeInsets.all(0.0),
        this.controller = controller ??
            LoadingController(
              percentage: percentage ?? 0.0,
              thickness: thickness ?? 1.0,
            );

  @override
  _LoadingAnimationState createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation> {
  @override
  void initState() {
    super.initState();

    widget.anim.addListener(() {
      if (this.mounted) {
        setState(() {
          widget.controller.percentage = widget.anim.value * widget.size;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: widget.margin,
        padding: EdgeInsets.all(widget.controller.thickness / 2),
        height: widget.size,
        width: widget.size,
        child: CustomPaint(
            foregroundPainter: new LoadingPainter(
                lineColor: widget.lineColor,
                progressColor: widget.progressColor,
                completePercent: widget.controller.percentage,
                thickness: widget.controller.thickness,
                maxHeight: widget.size)));
  }
}

class LoadingPainter extends CustomPainter {
  Color lineColor;
  Color progressColor;
  double completePercent;
  double thickness;
  final double maxHeight;

  LoadingPainter(
      {this.lineColor, this.progressColor, this.completePercent, this.thickness, this.maxHeight});

  @override
  void paint(Canvas canvas, Size size) {
    Paint line = new Paint()
      ..color = lineColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    Paint complete = new Paint()
      ..color = progressColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    Offset center = new Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, line);
    double factor = maxHeight * 0.9;

    double arc = completePercent <= (maxHeight * 0.5)
        ? (completePercent * maxHeight / factor)
        : ((maxHeight * 0.5) * maxHeight / factor) -
            ((completePercent - (maxHeight * 0.5)) * maxHeight / factor);

    double arcAngle = 2 * pi * (arc / maxHeight);

    double startPercentage =
        ((completePercent - (maxHeight - factor)) * maxHeight / factor).clamp(0.0, maxHeight);
    double startAngle = lerpDouble(-0.5, 1.5, startPercentage / maxHeight);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi * startAngle, arcAngle,
        false, complete);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class LoadingController extends ValueNotifier<LoadingValue> {
  double get percentage => value.percentage;

  set percentage(double newPercentage) {
    value = value.copyWith(percentage: newPercentage, thickness: this.thickness);
  }

  double get thickness => value.thickness;

  set thickness(double newThickness) {
    value = value.copyWith(percentage: this.percentage, thickness: newThickness);
  }

  LoadingController({double percentage, double thickness})
      : super(percentage == null && thickness == null
            ? LoadingValue.empty
            : new LoadingValue(
                percentage: percentage ?? 0.0,
                thickness: thickness ?? 1.0,
              ));

  LoadingController.fromValue(LoadingValue value) : super(value ?? LoadingValue.empty);

  void clear() {
    value = LoadingValue.empty;
  }
}

@immutable
class LoadingValue {
  const LoadingValue({this.percentage = 0.0, this.thickness = 1.0});

  final double percentage;
  final double thickness;

  static const LoadingValue empty = const LoadingValue();

  LoadingValue copyWith({double percentage, double thickness}) {
    return new LoadingValue(
        percentage: percentage ?? this.percentage, thickness: thickness ?? this.thickness);
  }

  LoadingValue.fromValue(LoadingValue copy)
      : this.percentage = copy.percentage,
        this.thickness = copy.thickness;

  @override
  String toString() =>
      '$runtimeType(text: \u2524$percentage\u251C, thickness: \u2524$thickness\u251C)';

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! LoadingValue) return false;
    final LoadingValue typedOther = other;
    return typedOther.percentage == percentage && typedOther.thickness == thickness;
  }

  @override
  int get hashCode => hashValues(percentage.hashCode, thickness.hashCode);
}
