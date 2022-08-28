import 'dart:async';
import 'dart:math';

import 'package:animations_test/physical_point.dart';
import 'package:flutter/material.dart';

import 'fluid_page_clipper.dart';

const pointMass = 20;
const springStiffness = 4;
const dampingStiffness = 3;
const wallAttractionForce = 90.0;

class ClippedFluidPage extends StatefulWidget {
  const ClippedFluidPage({required this.child, required this.size, Key? key}) : super(key: key);

  final Widget child;
  final Size size;

  @override
  State<ClippedFluidPage> createState() => _ClippedFluidPageState();
}

class _ClippedFluidPageState extends State<ClippedFluidPage> {
  late final Timer timer;
  late final List<PhysicalPoint> points;

  static const int fps = 60;
  static const int pointCount = 10;

  bool isFlipped = false;

  @override
  void initState() {
    super.initState();

    points = List.generate(
      pointCount,
      (index) => PhysicalPoint(
        position: Offset(
          widget.size.width,
          widget.size.height / (pointCount - 1) * index,
        ),
        velocity: Offset.zero,
        force: Offset.zero,
      ),
    );

    timer = Timer.periodic(Duration(milliseconds: (1 / fps * 1000).round()), (timer) {
      calculatePositions();
      setState(() {});
    });
  }

  void calculatePositions() {
    const dt = 1 / fps;
    final restLength = widget.size.height / (pointCount - 1);

    for (int i = 0; i < points.length; i++) {
      points[i].force = Offset.zero;
    }

    for (int i = 0; i < points.length - 1; i++) {
      final forceDirection = atan2(
        points[i + 1].position.dy - points[i].position.dy,
        points[i + 1].position.dx - points[i].position.dx,
      );

      final springForce = Offset.fromDirection(
        forceDirection,
        springStiffness * (distanceBetween(points[i].position, points[i].position) - restLength),
      );

      final unitVector =
          (points[i + 1].position - points[i].position) / distanceBetween(points[i + 1].position, points[i].position);

      final velocityVector = points[i + 1].velocity - points[i].velocity;

      final angle = acos((unitVector.dx * velocityVector.dx + unitVector.dy * velocityVector.dy) /
          (sqrt(unitVector.dx * unitVector.dx + unitVector.dy * unitVector.dy) *
              sqrt(velocityVector.dx * velocityVector.dx + velocityVector.dy * velocityVector.dy)));

      final springDampingForce = Offset.fromDirection(
        forceDirection,
        dampingStiffness * velocityVector.distance * cos(angle),
      );

      if (springDampingForce.isFinite) {
        points[i].force += springDampingForce;
        points[i + 1].force -= springDampingForce;
      }

      points[i].force -= springForce;
      points[i + 1].force += springForce;

      /// Constant force towards right of the screen
      points[i].force += const Offset(wallAttractionForce, 0);
    }

    if (touchOffset != null && pullingPointIndex != null) {
      points[pullingPointIndex!].position = touchOffset!;
      points[pullingPointIndex!].force = Offset.zero;
    }

    /// First and last point get more wall attraction force
    points.first.force += const Offset(wallAttractionForce * 4, 0);
    points.last.force += const Offset(wallAttractionForce * 4, 0);

    for (int i = 0; i < points.length; i++) {
      if (isFlipped) {
        points[i].velocity += -const Offset(10, 0);
      }

      /// Points should only move horizontally
      points[i].force = Offset(points[i].force.dx, 0);

      /// Update position
      points[i].position += points[i].velocity * dt;

      /// Points should be stopped on the right screen edge
      if (points[i].position.dx > widget.size.width) {
        points[i].position = Offset(widget.size.width, points[i].position.dy);
      }

      /// Points should be stopped on the left screen edge
      if (points[i].position.dx < 0) {
        points[i].position = Offset(0, points[i].position.dy);
      }

      /// Update velocity
      final acceleration = points[i].force / pointMass.toDouble();
      points[i].velocity += acceleration * dt;

      /// Check if it's at the right (initial) height
      if (points[i].position.dx == widget.size.width &&
          points[i].position.dy != widget.size.height / (pointCount - 1) * i) {
        points[i].position = Offset(widget.size.width, widget.size.height / (pointCount - 1) * i);
      }
    }
  }

  double distanceBetween(Offset p1, Offset p2) {
    return pow(pow(p1.dx - p2.dx, 2) + pow(p1.dy - p2.dy, 2), 0.5).roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: onHorizontalDragStart,
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragEnd: onHorizontalDragEnd,
      child: Stack(
        children: [
          /// Only for debugging
          Positioned.fill(
            child: CustomPaint(
              painter: MyPainter(points, touchOffset),
            ),
          ),
          Positioned.fill(
            child: ClipPath(
              clipper: FluidPageClipper(points.map((e) => e.position).toList()),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Offset? touchOffset;

  /// Point on which force is applied to pull all points
  int? pullingPointIndex;

  void onHorizontalDragStart(DragStartDetails details) {
    if (details.localPosition.dx > widget.size.width - 50) {
      pullingPointIndex = (details.globalPosition.dy * (pointCount - 1) / widget.size.height).round();
      touchOffset = details.globalPosition;
    }
  }

  void onHorizontalDragUpdate(DragUpdateDetails details) {
    touchOffset = details.globalPosition;

    if (touchOffset!.dx < widget.size.width * 0.3) {
      isFlipped = true;
    }
  }

  void onHorizontalDragEnd(DragEndDetails details) {
    touchOffset = null;
    pullingPointIndex = null;
  }
}

class MyPainter extends CustomPainter {
  MyPainter(this.points, this.touchOffset);

  final List<PhysicalPoint> points;
  final Offset? touchOffset;

  @override
  void paint(Canvas canvas, Size size) {
    for (final point in points) {
      canvas.drawCircle(
        point.position,
        point == points.first || point == points.last ? 10 : 4,
        Paint()
          ..color = point == points.first || point == points.last ? Colors.greenAccent : Colors.black
          ..style = PaintingStyle.fill,
      );

      canvas.drawLine(
        point.position,
        point.position + point.force,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    if (touchOffset != null) {
      canvas.drawCircle(
        touchOffset!,
        40,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
