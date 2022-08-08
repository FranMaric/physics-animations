import 'dart:async';
import 'dart:math';

import 'package:animations_test/fluid_page_clipper.dart';
import 'package:animations_test/physical_point.dart';
import 'package:flutter/material.dart';

const pointMass = 20;
const springStiffness = 4;
const dampingStiffness = 3;
const wallAttractionForce = 90.0;

class FluidPageView extends StatelessWidget {
  const FluidPageView({required this.firstPage, required this.secondPage, Key? key}) : super(key: key);

  final Widget firstPage;
  final Widget secondPage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            firstPage,
            ClippedFluidPage(
              secondPage,
              size: constraints.biggest,
            ),
          ],
        );
      },
    );
  }
}

class ClippedFluidPage extends StatefulWidget {
  const ClippedFluidPage(this.page, {required this.size, Key? key}) : super(key: key);

  final Widget page;
  final Size size;

  @override
  State<ClippedFluidPage> createState() => _ClippedFluidPageState();
}

class _ClippedFluidPageState extends State<ClippedFluidPage> {
  late final Timer timer;
  late final List<PhysicalPoint> points;

  static const int fps = 60;
  static const int pointCount = 10;

  @override
  void initState() {
    super.initState();
    final random = Random(123456);

    points = List.generate(
      pointCount,
      (index) => PhysicalPoint(
        position: Offset(
          (1 + random.nextDouble()) * widget.size.width / 2,
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

    for (int i = 0; i < points.length; i++) {
      /// Points should only move horizontally
      points[i].force = Offset(points[i].force.dx, 0);

      /// Update speed
      points[i].position += points[i].velocity * dt;

      /// Points should be stopped on the right screen edge
      if (points[i].position.dx > widget.size.width) {
        points[i].position = Offset(widget.size.width, points[i].position.dy);
      }

      final acceleration = points[i].force / pointMass.toDouble();
      points[i].velocity += acceleration * dt;
    }
  }

  double distanceBetween(Offset p1, Offset p2) {
    return pow(pow(p1.dx - p2.dx, 2) + pow(p1.dy - p2.dy, 2), 0.5).roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: MyPainter(points),
        ),
        ClipPath(
          clipper: FluidPageClipper(points.map((e) => e.position).toList()),
          child: widget.page,
        )
      ],
    );
  }
}

class MyPainter extends CustomPainter {
  MyPainter(this.points);

  final List<PhysicalPoint> points;

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

    final path = Path();

    path.moveTo(points.first.position.dx, points.first.position.dy);

    for (int i = 1; i < points.length - 2; i++) {
      var xc = (points[i].position.dx + points[i + 1].position.dx) / 2;
      var yc = (points[i].position.dy + points[i + 1].position.dy) / 2;
      path.quadraticBezierTo(points[i].position.dx, points[i].position.dy, xc, yc);
    }

    path.quadraticBezierTo(
      points[points.length - 2].position.dx,
      points[points.length - 2].position.dy,
      points[points.length - 1].position.dx,
      points[points.length - 1].position.dy,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
